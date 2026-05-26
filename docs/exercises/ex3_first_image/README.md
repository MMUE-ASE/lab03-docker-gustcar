# Exercise 3 — Build your own image

Full instructions are in the [exercises README](../README.md#exercise-3--build-your-own-image-ex3_first_image).
Complete TODOs T1–T4 in [`Dockerfile`](Dockerfile), then use this checklist.

## Checklist

- [ ] `docker build -t my-first-image .` completes without errors
- [ ] `docker run --rm my-first-image` prints `Hello from an image I built myself!`
- [ ] A second `docker build` shows every step as `CACHED` and finishes instantly
- [ ] After editing `greet.sh`, the `COPY` step and everything below it rebuild, but the
      `FROM`/`RUN` steps stay `CACHED`

## Check your understanding

- What does each of `FROM`, `COPY`, `RUN`, `CMD` do? Which run at **build** time and which
  at **container start** time?
- Why did editing `greet.sh` invalidate the `COPY` layer but not the layers above it?
- In the lab `Dockerfile`, should the slow `apt-get install` go near the **top** or the
  **bottom**? Why?
