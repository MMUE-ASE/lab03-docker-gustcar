# Warm-up Exercises — Docker Basics

Three short exercises that build the Docker vocabulary you need before writing the lab's
real `Dockerfile`. Each runs inside WSL (see
[../wsl_docker_setup.md](../wsl_docker_setup.md)) — no extra software required.

**Estimated time:** 30–35 minutes total.

> Run every command in a terminal where `docker --version` works (i.e. the VS Code
> **WSL** terminal). If it says `command not found`, re-read the setup guide first.

---

## Exercise 1 — Run your first container (`ex1_hello/`)

**You will learn:** the image → container model, `docker run`, `docker images`,
`docker ps`, and what `--rm` does.

1. Run the canonical test image:

   ```bash
   docker run hello-world
   ```

   Read the message it prints — it describes the exact steps Docker just took
   (client → daemon → pull image → create container → stream output).

2. Run it **again**. The second time there is no "Unable to find image… pulling" line —
   the image is now cached locally. List your local images:

   ```bash
   docker images
   ```

3. See that the container has already exited (it ran once and stopped):

   ```bash
   docker ps          # running containers — hello-world is NOT here
   docker ps -a       # ALL containers — here it is, status "Exited"
   ```

4. **Key observation:** every `docker run` created a *new* container that lingers after
   exit. Clean them up, then learn the flag that avoids the mess:

   ```bash
   docker container prune -f      # remove all stopped containers
   docker run --rm hello-world    # --rm auto-deletes the container on exit
   docker ps -a                   # the --rm run left nothing behind
   ```

A `Dockerfile` is **not** needed for this exercise — you are consuming an existing image.
Read [`ex1_hello/README.md`](ex1_hello/README.md) for the checklist.

---

## Exercise 2 — Containers are isolated and disposable (`ex2_interactive/`)

**You will learn:** interactive containers (`-it`), that changes inside a container
vanish when it is removed, and the difference between an image and a container's
writable layer.

1. Start an Ubuntu container and get a shell inside it:

   ```bash
   docker run --rm -it ubuntu:24.04 bash
   ```

   Your prompt changes (e.g. `root@a1b2c3:/#`) — you are now *inside* the container.

2. Prove the toolchain is **not** there yet, then install something, then use it:

   ```bash
   arm-none-eabi-gcc --version    # bash: command not found — clean base image
   apt-get update && apt-get install -y cowsay
   /usr/games/cowsay "Hello from inside a container"
   exit
   ```

3. Start a **fresh** container from the *same* image and check for cowsay:

   ```bash
   docker run --rm -it ubuntu:24.04 bash
   /usr/games/cowsay "still here?"   # command not found — it is gone!
   exit
   ```

4. **Key observation:** your `apt-get install` modified that *one* container's writable
   layer, which `--rm` threw away on exit. The image never changed. This is exactly why
   we need a **Dockerfile**: to make installed tools *permanent* and part of the image,
   instead of installing them by hand every time.

Read [`ex2_interactive/README.md`](ex2_interactive/README.md) for the checklist.

---

## Exercise 3 — Build your own image (`ex3_first_image/`)

**You will learn:** the four core Dockerfile instructions (`FROM`, `COPY`, `RUN`, `CMD`),
`docker build -t`, and how the **layer cache** makes rebuilds fast.

**What to do:** open [`ex3_first_image/Dockerfile`](ex3_first_image/Dockerfile) and
complete TODOs T1–T4. The image just runs a tiny shell script, so you can focus on the
mechanics, not on a toolchain.

1. After completing the TODOs, build and run:

   ```bash
   cd ex3_first_image
   docker build -t my-first-image .
   docker run --rm my-first-image
   ```

   Expected output:

   ```text
   Hello from an image I built myself!
   ```

2. **Watch the cache.** Run the exact same `docker build` again — every step says
   `CACHED` and it finishes instantly.

3. Now edit `greet.sh` (change the message), rebuild, and watch which steps rebuild:
   the `COPY` step and everything **below** it re-run, but the `FROM`/`RUN` layers above
   stay `CACHED`.

4. **Key observation:** Docker rebuilds a layer only when that instruction — or any
   instruction above it — changes. Ordering instructions from "least likely to change"
   (top) to "most likely to change" (bottom) is what keeps builds fast. You will apply
   this directly when ordering the toolchain install in the lab `Dockerfile`.

Read [`ex3_first_image/README.md`](ex3_first_image/README.md) for the checklist.

---

## You are ready for the lab Dockerfile

After these three exercises you have seen:

| Concept                                   | Exercise |
| ----------------------------------------- | -------- |
| Image vs. container                       | Ex 1     |
| `docker run`, `docker images`, `docker ps`| Ex 1     |
| `--rm` and container cleanup              | Ex 1, 2  |
| Interactive containers (`-it`)            | Ex 2     |
| Containers are disposable / isolated      | Ex 2     |
| `FROM`, `COPY`, `RUN`, `CMD`              | Ex 3     |
| `docker build -t`                         | Ex 3     |
| Layer cache and instruction ordering      | Ex 3     |

Return to the [lab README](../../README.md) and start **Phase 2 — Author the
build-environment image**.
