#!/usr/bin/env bash
# docker-build.sh — Compile the firmware INSIDE the container, output on the HOST.
#
# The trick is a bind mount: -v <host-dir>:/work makes the current project folder
# appear at /work inside the container. The container runs 'make all' there, and the
# resulting output/ directory is written straight back to your host — ready to flash
# from outside the container (the ST-LINK USB driver lives on the host, not here).
set -euo pipefail

IMAGE="lab3-arm-builder"

# Make sure the image exists before trying to run it.
if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "ERROR: image '$IMAGE' not found. Build it first:"
    echo "       docker build -t $IMAGE ."
    exit 1
fi

echo "Building firmware inside container '$IMAGE' ..."

# TODO (P3.1) — Run the build in the container.
#   Replace the line below with a 'docker run' command that:
#     --rm                  removes the container when it exits (no clutter)
#     -v "$(pwd)":/work     mounts this project onto /work inside the container
#     "$IMAGE"              the image to run
#     [command]             omit it to use the Dockerfile CMD, or pass 'make all'
#
#   Form:  docker run --rm -v "$(pwd)":/work "$IMAGE"
#
echo "ERROR: docker-build.sh is not implemented yet — add the docker run command." && exit 1

echo ""
echo "Done. Artifacts are on the host in ./output/ — flash with: bash scripts/flash.sh"
