# mirror-denoland

OCX mirror for [Deno](https://github.com/denoland/deno). One repository, one
spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [deno](https://github.com/denoland/deno) | [`deno/mirror.yml`](deno/mirror.yml) | `ghcr.io/ocx-contrib/denoland/deno` | [`ocx.sh/denoland/deno`](https://index.ocx.sh/denoland/deno) | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
deno/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. `platforms:` is deliberately
kept **out** of `mirror-base.yml` here so there is no base block to half-restate:
the container matrix is downstream of a per-package libc measurement and belongs
beside it.

## Platforms

`deno` publishes six platform entries: both Linux arches, both macOS arches and
both Windows arches — the complete set upstream builds. Upstream ships **no
musl build of deno at any version**, and that absence was not taken as the
answer: both Linux binaries were measured and are **dynamically linked against
glibc** (`interpreter /lib64/ld-linux-x86-64.so.2` and
`/lib/ld-linux-aarch64.so.1`, `DT_NEEDED libc.so.6`, max symbol version
`GLIBC_2.27` on both arches). `os.features` states what an artifact requires
*of the host*, so both Linux keys carry **`+libc.glibc`**.

The `alpine:3.20` container leg is therefore **absent by design**: a
`+libc.glibc` key has nothing to prove under musl, and the artifact
demonstrably does not load there — running it in `alpine:3.20` yields
`sh: deno: not found`, which is the musl loader's message for a glibc-dynamic
ELF, not a missing file. `ubuntu:24.04` and `fedora:40` are the legs, and both
run the binary from their stock images (no `containers[].setup` needed —
`libgcc_s.so.1` and `librt.so.1` are already present). The full measurement is
recorded above the `assets:` block in [`deno/mirror.yml`](deno/mirror.yml).

Upstream publishes two sibling asset families for the same six triples —
`denort-<triple>.zip` (the standalone runtime `deno compile` embeds) and
`libdenort-<triple>.zip` (its FFI form). Neither is mirrored. Because `deno` is
a literal substring of `denort`, every asset pattern is fully anchored
`^deno-…\.zip$`.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `deno/mirror.yml` | hand | yes — see below |
| `deno/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `deno/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec deno/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

Upstream's zip holds **exactly one member** — the `deno` executable
(`deno.exe` on Windows) — at the archive root, with no wrapper directory. With
`strip_components: 0` the executable *is* the content root and the bundle's
only PATH entry is a bare `${installPath}`. `bin_scan` only looks *below* an
`${installPath}/<dir>` entry, so `auto`/`verify` is rejected at spec load with
exit 65. `mirror-base.yml` therefore sets `bin_scan: off` and
`deno/metadata.json` hand-lists `binaries: ["deno"]`.

That hand list is load-bearing beyond documentation: `prepare` chmods only
**declared** binaries to 0755.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; the
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
