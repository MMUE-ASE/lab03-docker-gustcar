# Exercise 1 — Run your first container

Full instructions are in the [exercises README](../README.md#exercise-1--run-your-first-container-ex1_hello).
This file is just the checklist.

## Checklist

- [ ] `docker run hello-world` prints the "Hello from Docker!" message
- [ ] Running it a second time does **not** re-download the image
- [ ] `docker images` lists `hello-world`
- [ ] `docker ps` shows nothing; `docker ps -a` shows the exited container
- [ ] `docker container prune -f` removes stopped containers
- [ ] `docker run --rm hello-world` leaves nothing in `docker ps -a`

## Check your understanding

- What is the difference between an **image** and a **container**?
- Why did the second `docker run` skip the download step?
- What does `--rm` do, and why is it useful for build containers?
