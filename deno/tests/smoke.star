# deno/tests/smoke.star — stable across upstream deno releases.
# Asserts the contract (exit codes, version shape, a value deno itself
# computed, a diagnostic CODE), never help/version prose.
# See create-mirror references/testing-practices.md.
#
# Bazel .bzl dialect: no top-level `if`/`for` STATEMENTS. Branch at module
# scope only via an if-EXPRESSION (below) or a def + top-level call.

DENO = "deno.exe" if ocx.target_platform.os == ocx.os.Windows else "deno"

# The Rust target triple deno reports about ITSELF, reassembled from the typed
# platform constants. Asserting it proves the asset regex shipped the RIGHT
# artifact into the RIGHT bundle — the one bug class the spec's platform gate
# cannot see from inside, since a mis-mapped pattern resolves and publishes
# perfectly happily. Verified present as a standalone string in all six v2.9.4
# binaries (`strings -a deno | grep -x <triple>`).
ARCH = "aarch64" if ocx.target_platform.arch == ocx.arch.Arm64 else "x86_64"
OS_PART = "apple-darwin" if ocx.target_platform.os == ocx.os.Darwin else (
    "pc-windows-msvc" if ocx.target_platform.os == ocx.os.Windows else "unknown-linux-gnu"
)
TRIPLE = ARCH + "-" + OS_PART

# HOME/USERPROFILE → the test sandbox, so DENO_DIR (deno's module + check
# cache) can never land outside it or depend on the runner's home. MEASURED:
# `deno eval`, `deno run` and `deno check` all still exit 0 with HOME unset and
# with HOME=/nonexistent inside a bare ubuntu:24.04 container, so this is
# insurance rather than a fix for a live failure. NO_COLOR removes SGR escapes
# from the diagnostics asserted below — colorized output splits per token and
# is the standard reason a plain-substring assertion reds.
ENV = {
    "HOME": ocx.scratch_root,
    "USERPROFILE": ocx.scratch_root,
    "NO_COLOR": "1",
}

# Tier 1 + 2: liveness on the composed PATH, version SHAPE, and platform
# identity. The digits are the contract — never the banner, never the exact
# version.
r_version = ocx.run(DENO, "--version", env = ENV)
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")
expect.eq(r_version.stdout.count(TRIPLE), 1)

# Tier 3a: run TypeScript. `deno run` on a .ts source forces the transpile path
# (which `deno eval` of plain JS never reaches) and then executes it. The
# asserted number is computed by deno from the script's own data — 1+2+3+4+5=15,
# x6 = 90 — so a stub that echoed its input could not produce it. Asserting the
# COUNT rather than mere containment survives an unsolicited stdout banner.
# `--no-remote` makes the offline guarantee explicit: any future release that
# tries to fetch something reds here instead of flaking on a runner's network.
ocx.write_file("smoke.ts", """function total(xs: number[]): number {
  return xs.reduce((a, b) => a + b, 0);
}
const label: string = "OCXSMOKE";
console.log(`${label}=${total([1, 2, 3, 4, 5]) * 6}`);
""")

r_run = ocx.run(DENO, "run", "--no-remote", "smoke.ts", env = ENV)
expect.ok(r_run)
expect.eq(r_run.stdout.count("OCXSMOKE=90"), 1)

# Tier 3b: type-check the same file. `deno check` boots the bundled TypeScript
# compiler, which is a large slice of the artifact that neither `--version` nor
# `run` touches (run transpiles and discards types). A truncated bundle can
# still pass Tier 1 and 3a and fail here.
expect.ok(ocx.run(DENO, "check", "--no-remote", "smoke.ts", env = ENV))

# Negative control. Tier 3a is execute-and-print shaped, so it needs a paired
# input that MUST fail: a genuine type error. Non-zero alone would also be
# produced by a broken bundle, so the discriminator is the diagnostic CODE —
# TS2322 is emitted by the type checker itself and is a stable contract in the
# way its message text is not.
ocx.write_file("bad.ts", """const n: number = "not a number";
console.log(n);
""")

r_bad = ocx.run(DENO, "check", "--no-remote", "bad.ts", env = ENV)
expect.ne(r_bad.exit_code, 0)
expect.eq(r_bad.stderr.count("TS2322"), 1)

# No Tier 4: metadata.json declares PATH only, and Tier 1 already proves it
# composed (the binary would not resolve otherwise).
