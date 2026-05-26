# Docker Concept Reference

A compact reference for the ideas this lab uses. Read **Section 1** before Phase 1, and
come back to the rest whenever a phase mentions a concept you want to revisit.

---

## Table of Contents

- [1. Why Docker exists](#1-why-docker-exists)
- [2. Images vs. containers](#2-images-vs-containers)
- [3. The Dockerfile](#3-the-dockerfile)
- [4. Layers and the build cache](#4-layers-and-the-build-cache)
- [5. Volumes and bind mounts](#5-volumes-and-bind-mounts)
- [6. Command cheat sheet](#6-command-cheat-sheet)
- [7. Docker vs. a virtual machine](#7-docker-vs-a-virtual-machine)

---

## 1. Why Docker exists

> "It works on my machine."

Every embedded team eventually hits this. One developer has `arm-none-eabi-gcc` 12.2,
another has 10.3, the CI server has yet another. The same source compiles to different
binaries — or fails to compile at all — depending on whose machine ran the build.
Debugging *the toolchain* instead of *the firmware* wastes hours.

**Docker packages the toolchain itself.** Instead of writing a wiki page that says
"install these 7 tools at these exact versions," you write a `Dockerfile` that *is* the
install. Anyone who builds it gets a byte-for-byte identical environment: same compiler,
same libraries, same everything — on Windows, macOS, Linux, or the CI runner.

Why professionals rely on this:

| Problem without Docker                               | What Docker gives you                          |
| ---------------------------------------------------- | ---------------------------------------------- |
| "Works on my machine" toolchain drift                | One image → identical builds everywhere        |
| New hire spends a day installing tools                | `docker build` once, start working             |
| CI environment differs from local                    | CI runs the *same image* you do                |
| Two projects need different compiler versions        | One image per project, no conflicts            |
| Upgrading a tool breaks an unrelated project         | Images are isolated and disposable             |

For this lab the payoff is concrete: your firmware build no longer depends on what is
installed on the lab PC. The PC only needs Docker.

---

## 2. Images vs. containers

These two words are easy to confuse and the whole model depends on the difference.

- An **image** is a read-only template — a frozen snapshot of a filesystem plus some
  metadata (which command to run, which directory to start in). Think of it as a *class*.
- A **container** is a running (or stopped) instance of an image — an isolated process
  with its own filesystem view, created from the image. Think of it as an *object*.

```text
  Dockerfile  --build-->  Image  --run-->  Container (1)
                            |     --run-->  Container (2)
                            |     --run-->  Container (3)
```

You build an image **once** and run **many** disposable containers from it. A container
started with `--rm` deletes itself on exit — anything you changed inside it is gone. That
is a feature: builds start from a known-clean state every time.

---

## 3. The Dockerfile

A `Dockerfile` is a plain-text recipe for an image. Each line is an *instruction*. The
ones used in this lab:

| Instruction | Purpose                                                            |
| ----------- | ----------------------------------------------------------------- |
| `FROM`      | The base image to start from (e.g. `ubuntu:24.04`)                 |
| `LABEL`     | Metadata key/value pairs (author, title, version)                 |
| `RUN`       | Execute a command while *building* the image (e.g. `apt-get …`)    |
| `WORKDIR`   | Set the directory later instructions and `docker run` start in     |
| `COPY`      | Copy files from the build context into the image                   |
| `CMD`       | The default command run when a container *starts* (not at build)   |

`RUN` vs `CMD` is the classic mix-up: `RUN` happens **once, at build time**, and its
result is baked into the image. `CMD` happens **every time you start a container** and can
be overridden on the command line.

---

## 4. Layers and the build cache

Every instruction in a Dockerfile creates a **layer** — a saved diff of the filesystem.
Docker caches layers and reuses them on the next build **as long as that instruction and
everything above it are unchanged**.

```text
FROM ubuntu:24.04                ← layer 1  (cached after first pull)
RUN apt-get update && install…   ← layer 2  (slow: downloads packages)
WORKDIR /work                    ← layer 3
CMD ["make", "all"]              ← layer 4
```

If you edit the `CMD` line, only layer 4 rebuilds — layers 1–3 come from cache, so the
rebuild is instant. But if you edit the `FROM` line, *everything* below it rebuilds,
including the slow `apt-get`.

**Design rule:** put the things that rarely change (installing the toolchain) near the
**top**, and the things that change often near the **bottom**. That keeps the expensive
layer cached. This is why the lab installs the compiler before setting `CMD`.

---

## 5. Volumes and bind mounts

A container's filesystem is isolated and disposable — so how does a build inside it
produce a `.elf` you can flash on the host? With a **bind mount**: you map a host folder
onto a path inside the container.

```bash
docker run --rm -v "$(pwd)":/work lab3-arm-builder make all
#                  └─────┬──────┘  └─┬─┘
#                   host folder   path inside container
```

Now `/work` inside the container *is* your project folder on the host. The container
compiles into `/work/output/`, and because that path is really your host folder, the
artifacts appear on the host the instant the build finishes — ready to flash from outside
the container.

`--rm` deletes the container afterward; the mounted files survive because they live on the
host, not in the container.

---

## 6. Command cheat sheet

```bash
# Images
docker pull ubuntu:24.04          # download an image from Docker Hub
docker images                     # list local images
docker build -t myimage .         # build an image from ./Dockerfile, name it "myimage"
docker rmi myimage                # remove an image

# Containers
docker run hello-world            # run a container from an image
docker run -it ubuntu bash        # run interactively (-i keep stdin, -t terminal)
docker run --rm ubuntu echo hi    # auto-remove the container when it exits
docker run -v "$(pwd)":/work img  # bind-mount the current dir to /work
docker ps                         # list running containers
docker ps -a                      # list all containers, including stopped
docker rm <id>                    # remove a stopped container

# Housekeeping
docker system df                  # how much disk Docker is using
docker system prune               # remove stopped containers + unused data
```

---

## 7. Docker vs. a virtual machine

Students often ask "isn't this just a VM?" No — and the difference is why Docker is fast.

| Aspect          | Virtual machine                          | Docker container                       |
| --------------- | ---------------------------------------- | -------------------------------------- |
| Boots           | A full guest OS (its own kernel)         | Shares the host kernel — no boot       |
| Start time      | Tens of seconds                          | Milliseconds                           |
| Size            | Gigabytes (whole OS)                     | Megabytes (just the app + deps)        |
| Overhead        | Heavy (CPU/RAM reserved per VM)          | Near-native                            |
| Isolation       | Strong (separate kernel)                 | Process-level (shared kernel)          |

On Windows, Docker runs its Linux containers inside a lightweight WSL2 VM — so you do get
one small VM hosting the Linux kernel, but every container on top of it is cheap. That is
exactly why this lab runs Docker through WSL2 (see
[wsl_docker_setup.md](wsl_docker_setup.md)).
