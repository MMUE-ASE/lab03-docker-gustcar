[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/1fRYDKhM)
# Lab 3 — Docker Build Environment

[![Hardware](https://img.shields.io/badge/Hardware-STM32_NUCLEO--F412ZG-03234B.svg?logo=stmicroelectronics&logoColor=white)](https://www.st.com/en/evaluation-tools/nucleo-f412zg.html)
[![Toolchain](https://img.shields.io/badge/Toolchain-arm--none--eabi--gcc-A8B9CC.svg?logo=arm&logoColor=white)](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
[![Docker](https://img.shields.io/badge/Docker-WSL2-2496ED.svg?logo=docker&logoColor=white)](https://docs.docker.com/desktop/wsl/)
[![GitHub Classroom](https://img.shields.io/badge/GitHub-Classroom-181717.svg?logo=github)](https://classroom.github.com/classrooms/274591709-mmue-arquitectura-sistemas-embebidos-2026)

---

## Table of Contents

- [Context](#context)
- [Objectives](#objectives)
- [Getting Started](#getting-started)
- [Phase Overview](#phase-overview)
- [Phase 0 — What is Docker, and why](#phase-0--what-is-docker-and-why)
- [Phase 1 — Docker basics](#phase-1--docker-basics)
- [Phase 2 — Author the build-environment image](#phase-2--author-the-build-environment-image)
- [Phase 3 — Build in the container, flash outside](#phase-3--build-in-the-container-flash-outside)
- [Phase 4 — Dev Container (optional)](#phase-4--dev-container-optional)
- [Milestones](#milestones)
- [CI and submission](#ci-and-submission)
- [Common errors](#common-errors)
- [Rubric](#rubric)

---

## Context

In Lab 2 you replaced a build script with a Makefile. But the build still depends on what
is installed on *your* machine: the exact `arm-none-eabi-gcc` version, `make`, binutils. On
a different PC — a classmate's, the lab's, the CI runner's — the build can behave
differently or fail outright. This is the **"works on my machine"** problem, and in
professional embedded teams it costs real hours.

This lab fixes that by packaging the toolchain itself into a **Docker image**. You write a
`Dockerfile` that *is* the install recipe; anyone who builds it gets a byte-for-byte
identical build environment. You then compile your Lab 2 firmware **inside** a container
and flash the board **outside** it.

> **Why build inside but flash outside?** A container cannot reach the ST-LINK USB device,
> and the ST-LINK drivers live on the host. So the toolchain is containerised; the hardware
> connection stays on the host — same flash/debug flow as Lab 2.

The firmware behaviour is identical to Lab 2. The objective is the **build environment**.

---

## Objectives

- Explain what Docker is and why reproducible build environments matter professionally.
- Use the core Docker workflow: `pull`, `run`, `build`, images vs. containers, `--rm`.
- Write a `Dockerfile` that installs the ARM cross-toolchain on an Ubuntu LTS base.
- Compile the firmware inside a container, with artifacts landing on the host via a bind
  mount, then flash from outside the container.
- (Optional) Reopen the project *inside* the container as a VS Code Dev Container.

---

## Getting Started

This project must be opened through VS Code's **WSL connection** — Docker lives inside
WSL2 on the lab PCs. Full setup and verification steps:
[`docs/wsl_docker_setup.md`](docs/wsl_docker_setup.md).

```bash
# 1 — open the WSL shell, clone your repository INSIDE the WSL filesystem (~), and cd in
git clone https://github.com/<org>/<assigned-repo>.git
cd <assigned-repo>

# 2 — start the Docker daemon (native Docker Engine in WSL does not auto-start)
#     one-time: add yourself to the docker group first (see docs/wsl_docker_setup.md §1)
sudo service docker start

# 3 — launch VS Code from WSL (bottom-left must read "WSL: <distro>")
code .

# 4 — verify Docker answers (in the VS Code WSL terminal)
docker run --rm hello-world

# 5 — carry your completed Lab 2 project into this workspace
#     (Lab 3 ships no firmware sources — it adds Docker on top of your Lab 2 build)
bash scripts/copy_lab2.sh <path-to-your-lab2-repo>
```

Read [`docs/docker_guide.md`](docs/docker_guide.md) whenever you need a concept refresher.

---

## Phase Overview

| Phase                                                              | Goal                                       | Estimated time | Done when                                   |
| ----------------------------------------------------------------- | ------------------------------------------ | -------------- | ------------------------------------------- |
| [0 — What is Docker](#phase-0--what-is-docker-and-why)            | Understand images, containers, why it matters | 15 min      | You can explain image vs. container         |
| [1 — Docker basics](#phase-1--docker-basics)                      | Hands-on with `run`, `build`, the cache    | 35 min         | Ex 3 builds and runs your own image         |
| [2 — Author the image](#phase-2--author-the-build-environment-image) | Write the toolchain `Dockerfile`        | 40 min         | `docker build -t lab3-arm-builder .` passes |
| [3 — Build & flash](#phase-3--build-in-the-container-flash-outside) | Compile in container, flash on host      | 35 min         | `output/lab2.elf` built; board blinks       |
| [4 — Dev Container](#phase-4--dev-container-optional) *(optional)* | Reopen VS Code inside the container        | 15 min         | "Reopen in Container" works                 |

---

## Phase 0 — What is Docker, and why

**Read [`docs/docker_guide.md`](docs/docker_guide.md#1-why-docker-exists).** Before
typing any commands, make sure you can answer:

- What is the "works on my machine" problem, and how does an image solve it?
- What is the difference between an **image** (template) and a **container** (instance)?
- Why is `docker run --rm` useful for one-shot build containers?

This phase is reading only — it gives the vocabulary the rest of the lab assumes.

---

## Phase 1 — Docker basics

**Before writing any Dockerfile**, run the three warm-up exercises in
[`docs/exercises/`](docs/exercises/README.md). They take ~35 minutes and cover every Docker
concept this lab needs: running containers, the disposable filesystem, and building your
own image with the layer cache.

```bash
docker run --rm hello-world         # Exercise 1
```

| Exercise | You learn                                              |
| -------- | ------------------------------------------------------ |
| Ex 1     | image vs. container, `run`, `images`, `ps`, `--rm`     |
| Ex 2     | interactive containers, disposable/isolated filesystem |
| Ex 3     | `FROM`/`COPY`/`RUN`/`CMD`, `docker build`, layer cache |

**Check:** Exercise 3 builds `my-first-image` and prints its greeting. ✓

---

## Phase 2 — Author the build-environment image

Open [`Dockerfile`](Dockerfile) and complete TODOs **D1 through D5** in order. This image
contains the ARM toolchain and Make — the reproducible environment your firmware compiles
in.

| TODO | What to write                                                              |
| ---- | ------------------------------------------------------------------------- |
| D1   | `FROM` an Ubuntu LTS base image                                           |
| D2   | `LABEL` with image metadata (optional but good practice)                  |
| D3   | A single `RUN` that `apt-get` installs `gcc-arm-none-eabi`, `binutils-arm-none-eabi`, `make`, then cleans the apt lists |
| D4   | `WORKDIR /work` — where the project mounts and builds                     |
| D5   | `CMD ["make", "all"]` — the default build command                        |

Build it:

```bash
docker build -t lab3-arm-builder .
```

The first build downloads packages (~2–3 min). Rebuild and notice the cached layers.
Verify the toolchain is really inside:

```bash
docker run --rm lab3-arm-builder make --version
docker run --rm lab3-arm-builder arm-none-eabi-gcc --version
```

**Check (M2):** `docker build` exits 0; both version commands print versions. ✓

> **Image hygiene matters for the grade.** Combine update + install + cleanup in *one*
> `RUN`, use `--no-install-recommends`, and delete `/var/lib/apt/lists/*`. Put the slow
> install near the top so the cache stays warm — see
> [`docs/docker_guide.md` §4](docs/docker_guide.md#4-layers-and-the-build-cache).

---

## Phase 3 — Build in the container, flash outside

Now compile your Lab 2 firmware inside the image and get the artifacts onto the host.

Open [`scripts/docker-build.sh`](scripts/docker-build.sh) and complete TODO **P3.1**: the
`docker run` command with a **bind mount** (`-v "$(pwd)":/work`) so `output/` is written
back to the host. See [`docs/docker_guide.md` §5](docs/docker_guide.md#5-volumes-and-bind-mounts).

```bash
bash scripts/docker-build.sh        # compiles in the container; output/ appears on host
ls output/                          # lab2.elf  lab2.bin  lab2.hex
```

Then flash from **outside** the container (host OpenOCD + ST-LINK). With WSL you must first
make the ST-LINK reachable — see
[`docs/wsl_docker_setup.md` §5](docs/wsl_docker_setup.md#5-flashing-the-board-from-wsl-usb-passthrough)
and [`debug/README.md`](debug/README.md).

```bash
bash scripts/flash.sh               # runs on the HOST, not in the container
```

**Check (M3, M4):** `output/lab2.elf` exists on the host; pressing B1 lights LD2. ✓

---

## Phase 4 — Dev Container (optional)

Instead of one-off `docker run` commands, VS Code can open *inside* your image so the
editor, terminal, and IntelliSense all run in the toolchain environment.

Open [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json) and complete
**DC1** (point it at your `Dockerfile`) and **DC2** (set `workspaceFolder` to match your
`WORKDIR`). Then: Command Palette → **Dev Containers: Reopen in Container**.

Inside the dev container, `make all` works directly. Flashing still happens on the host.

**Check (M6):** "Reopen in Container" succeeds and `make all` builds from the integrated
terminal. ✓

---

## Milestones

| Milestone                       | How to verify                                                            |
| ------------------------------- | ----------------------------------------------------------------------- |
| M1 — Docker works               | `docker run --rm hello-world` prints the welcome message                |
| M2 — Image builds               | `docker build -t lab3-arm-builder .` exits 0; toolchain versions print  |
| M3 — Firmware built in container| `bash scripts/docker-build.sh` → `output/lab2.elf/.bin/.hex` on host    |
| M4 — Board works                | `bash scripts/flash.sh`; press B1 → LD2 on; release → LD2 off           |
| M5 — Layer cache observed       | Re-run `docker build` → all `CACHED`; edit `CMD` → only last layer rebuilds |
| M6 — Dev Container *(optional)* | "Reopen in Container" works; `make all` builds inside                    |

---

## CI and submission

Every `push` triggers the **Lab 3 — Docker Build Verification** workflow, which:

```text
docker build -t lab3-arm-builder .            →  builds your image (Phase 2)
docker run -v $PWD:/work ... make all         →  compiles firmware in the container (Phase 3)
verifies output/lab2.elf, .bin, .hex exist
docker run ... make size                      →  prints firmware size
```

The image-build step goes green once your `Dockerfile` is correct; the compile step goes
green once you have carried your Lab 2 project in with `copy_lab2.sh`. Results appear in the
**Actions** tab. Submission is the last commit pushed before the deadline.

### Commit conventions

```text
feat(lab3): install arm-none-eabi toolchain in Dockerfile
feat(lab3): add bind-mount run to docker-build.sh
docs(lab3): carry Lab 2 project into the workspace
```

---

## Common errors

| Symptom                                          | Likely cause                                                                 |
| ------------------------------------------------ | --------------------------------------------------------------------------- |
| `docker: command not found`                      | Terminal is on Windows, not WSL — reopen with `WSL:` shown bottom-left       |
| `Cannot connect to the Docker daemon`            | Docker not started in WSL: `sudo service docker start`                       |
| `failed to solve: ... no such file`              | `COPY`/path typo in the Dockerfile, or building from the wrong directory     |
| `Unable to locate package gcc-arm-none-eabi`     | `apt-get update` missing or split into a separate `RUN` (stale index)        |
| `make: *** No rule to make target` inside build  | Lab 2 not carried in — run `bash scripts/copy_lab2.sh <path>`               |
| `output/` empty after build                      | Missing `-v "$(pwd)":/work` bind mount in `docker-build.sh`                  |
| `rm: cannot remove 'output/...': Permission denied` | Files were written by root in the container. Clean via the container: `docker run --rm -v "$(pwd)":/work lab3-arm-builder make clean` |
| Build extremely slow / re-downloads every time   | Repo on `/mnt/c`, or install layer placed below frequently-changing lines    |
| `No ST-LINK device found` when flashing          | USB not passed through to WSL — `usbipd attach --wsl --busid <id>`           |

---

## Rubric

| Criterion                                                          | Weight |
| ----------------------------------------------------------------- | -----: |
| Image builds: `Dockerfile` D1–D5 correct (M2)                     |    30% |
| Firmware compiles inside the container → ELF/BIN/HEX (M3)         |    25% |
| Bind-mount run implemented in `docker-build.sh` (P3.1)           |    15% |
| Image hygiene: single `RUN` layer, cleanup, sensible ordering     |    15% |
| Board flashed from outside the container (M4)                     |     5% |
| Commit quality — Conventional Commits                             |    10% |

> *Phase 4 (Dev Container) is optional and not required for full marks.*
