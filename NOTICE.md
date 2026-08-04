# NOTICE

This repository packages and redistributes upstream software published by the
[Deno Land Inc.](https://github.com/denoland) organisation. The Apache-2.0
license in [`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It
does **not** cover any upstream-derived asset — each package's redistributed
bytes carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `deno` | `ghcr.io/ocx-contrib/denoland/deno` | `MIT` |

---

## `deno`

Upstream: <https://github.com/denoland/deno>
Published to `ghcr.io/ocx-contrib/denoland/deno`.

| Component | SPDX | Holder |
|---|---|---|
| Deno (`deno`) | **MIT** | Copyright 2018-2026 the Deno authors |

Permissive; redistribution of the compiled binary is granted provided the
copyright notice and permission notice are retained. The terms are those of
<https://github.com/denoland/deno/blob/main/LICENSE.md>, verified via
`gh api repos/denoland/deno/license` → `MIT`.

Upstream's release asset for each platform is a zip holding the single `deno`
executable and nothing else — no `LICENSE` file travels with it. This
`NOTICE.md` is therefore where the required notice is retained, and it is
published in the repository that builds every bundle.

The `deno` binary statically links a large set of third-party Rust crates and
V8, under permissive licenses (MIT / Apache-2.0 / BSD-3-Clause); the full set is
enumerated in upstream's `Cargo.lock` and the V8 sources it vendors. Deno's own
`LICENSE.md` covers the combined work as distributed by upstream.

The Deno name and dinosaur logo are used for catalog identification under
nominative fair use. `deno/logo.svg` is upstream's own mark, taken byte-for-byte
from `cli/tools/jupyter/resources/deno-logo-svg.svg` in the Deno repository;
`deno/logo.png` is a 512px raster of it. Deno Land Inc. does not endorse this
mirror.

This mirror carries only the `deno-<triple>.zip` CLI asset family. The sibling
`denort-*` (standalone `deno compile` runtime) and `libdenort-*` (FFI form)
assets are not redistributed here.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
