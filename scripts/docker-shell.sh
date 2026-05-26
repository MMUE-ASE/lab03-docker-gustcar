#!/usr/bin/env bash
# docker-shell.sh — Open an interactive shell inside the build container.
#
# Useful for exploring: run 'arm-none-eabi-gcc --version', 'make size', or poke around
# the toolchain. The project is mounted at /work, exactly as in docker-build.sh.
# Type 'exit' to leave; the container is removed automatically (--rm).
set -euo pipefail

IMAGE="lab3-arm-builder"

if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "ERROR: image '$IMAGE' not found. Build it first:"
    echo "       docker build -t $IMAGE ."
    exit 1
fi

echo "Entering '$IMAGE' (project mounted at /work). Type 'exit' to leave."
docker run --rm -it -v "$(pwd)":/work "$IMAGE" /bin/bash
