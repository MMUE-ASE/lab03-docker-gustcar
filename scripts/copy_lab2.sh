#!/usr/bin/env bash
# copy_lab2.sh — Carry your completed Lab 2 build into this Lab 3 workspace.
#
# Lab 3 does not ship firmware sources: it adds a Docker layer on top of the
# Makefile project you finished in Lab 2. This script copies that project in so
# the container has something to compile.
#
# Usage: bash scripts/copy_lab2.sh <path-to-your-lab2-repo>
set -euo pipefail

LAB2_PATH="${1:-}"

if [[ -z "$LAB2_PATH" ]]; then
    echo "Usage: bash scripts/copy_lab2.sh <path-to-lab2-repo>"
    echo ""
    echo "  Example: bash scripts/copy_lab2.sh ../lab2-makefile-myuser"
    exit 1
fi

if [[ ! -d "$LAB2_PATH" ]]; then
    echo "ERROR: '$LAB2_PATH' is not a directory."
    exit 1
fi

if [[ ! -f "$LAB2_PATH/Makefile" || ! -d "$LAB2_PATH/src" ]]; then
    echo "ERROR: '$LAB2_PATH' does not look like a Lab 2 repo (missing Makefile or src/)."
    exit 1
fi

echo "Copying from $LAB2_PATH ..."
cp    "$LAB2_PATH/Makefile" Makefile
mkdir -p src inc startup linker
cp -r "$LAB2_PATH/src/."     src/
cp -r "$LAB2_PATH/inc/."     inc/
cp -r "$LAB2_PATH/startup/." startup/
cp -r "$LAB2_PATH/linker/."  linker/

echo "Done. Project copied:"
echo "  Makefile"
echo "  src/  inc/  startup/  linker/"
echo ""
echo "Next: build the Docker image and compile inside it —"
echo "  docker build -t lab3-arm-builder ."
echo "  bash scripts/docker-build.sh"
