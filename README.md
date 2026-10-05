# lean4-docker-verbose

A Docker image with [Verbose Lean](https://github.com/PatrickMassot/verbose-lean4) ready to use. Verbose and Mathlib are already built in the image (Mathlib's prebuilt cache is downloaded at image build time), so nothing compiles when you start a container.

A GitHub Actions workflow runs daily and rebuilds the image whenever Verbose's `master` branch has a new commit.

**The Lean version is not "latest Lean".** Verbose pins a specific Mathlib release, and Mathlib dictates the Lean version. The workflow reads Verbose's `lean-toolchain` at its current `master` commit and builds with exactly that. For a plain image that tracks the newest Lean release, see the companion repo `lean4-docker`.

## Tags

Published as `ghcr.io/<you>/lean4-verbose`:

| Tag               | Meaning                                       |
|-------------------|-----------------------------------------------|
| `verbose-abc1234` | Exact Verbose commit (never moves)            |
| `lean-v4.31.0`    | Newest build that uses that Lean version      |
| `latest`          | Newest build of Verbose `master`              |

## Usage

The prebuilt project lives in `/home/ubuntu/project`. Mount only your `Teaching/` folder over it, so the prebuilt `.lake/` directory isn't hidden:

```bash
docker run --rm -it \
  -v "$PWD/Teaching":/home/ubuntu/project/Teaching \
  ghcr.io/<you>/lean4-verbose:latest bash

# inside the container
lake env lean Teaching/MyFile.lean   # check one file
lake build                           # build everything imported by Teaching.lean
```

Add your own modules to `Teaching.lean`, and write `import Verbose` at the top of your files. For the tactic syntax, see the Verbose repo's `getting-started.md` and `Verbose/English/Examples.lean`.

## Manual runs

**Actions → Build Lean 4 + Verbose image → Run workflow**

- `verbose_rev`: build a specific Verbose branch, tag or commit. Only the `verbose-<sha>` tag is pushed; `latest` and `lean-*` are not moved.
- `force`: rebuild even if the tag already exists.

Changing `Dockerfile`, `project/` or the workflow on `main` forces a rebuild.

## Local build

```bash
docker build \
  --build-arg LEAN_TOOLCHAIN="$(curl -fsSL https://raw.githubusercontent.com/PatrickMassot/verbose-lean4/master/lean-toolchain)" \
  --build-arg VERBOSE_REV=master \
  -t lean4-verbose .
```

## Caveats

- amd64 only. Building a Mathlib-sized image under QEMU emulation is slow and fragile; Apple Silicon machines run it via emulation.
- Expect a large image (Mathlib's compiled files are several GB). The workflow frees runner disk space before building, but if a build fails with "no space left", that is the likely cause.
- GitHub disables scheduled workflows in public repos after 60 days without repository activity. If that happens, re-enable the workflow in the Actions tab.
