# Exercise 2 — Containers are isolated and disposable

Full instructions are in the [exercises README](../README.md#exercise-2--containers-are-isolated-and-disposable-ex2_interactive).
This file is just the checklist.

## Checklist

- [ ] `docker run --rm -it ubuntu:24.04 bash` drops you into a shell inside the container
- [ ] `arm-none-eabi-gcc --version` fails — the base image has no toolchain
- [ ] `apt-get install -y cowsay` succeeds inside the container
- [ ] After `exit`, a **fresh** container does **not** have cowsay anymore
- [ ] You can explain why the install did not persist

## Check your understanding

- Where did the `cowsay` install actually go, and why was it lost on exit?
- The image was never modified — what *was* modified?
- What is the right way to make a tool a permanent part of an image?
