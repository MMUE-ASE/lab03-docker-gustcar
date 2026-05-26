# Lab 3 — Reproducible ARM build environment
#
# This Dockerfile describes an image that contains the exact toolchain needed to
# cross-compile the firmware: arm-none-eabi-gcc, binutils, and GNU Make. Anyone who
# builds this image gets the *same* compiler version, on any host — that is the whole
# point of Docker for embedded builds.
#
# Work through the TODOs in order. After each one, rebuild and read the output:
#
#   docker build -t lab3-arm-builder .
#
# The first build downloads packages and is slow (~2-3 min). Every rebuild after that
# reuses cached layers and is almost instant — unless you change a line, in which case
# that line and every line BELOW it are rebuilt. Keep the slow apt layer near the top.
#
# Reference: docs/docker_guide.md

# =============================================================================
# PHASE 2 — Author the build-environment image
# Goal: 'docker build -t lab3-arm-builder .' completes with no errors
# =============================================================================

# D1 — Choose the base image.
#       Use an Ubuntu LTS release so apt has the arm-none-eabi packages.
#       Form:  FROM <image>:<tag>
#       Hint:  ubuntu:24.04
#
# YOUR INSTRUCTION HERE


# D2 — Document who maintains the image (optional but good practice).
#       Form:  LABEL key="value"
#       Example: LABEL org.opencontainers.image.title="Lab 3 ARM builder"
#
# YOUR LABEL HERE


# D3 — Install the toolchain in a SINGLE RUN instruction.
#       You need three things from apt:
#         gcc-arm-none-eabi        the cross-compiler
#         binutils-arm-none-eabi   objcopy, size, ld for the ARM target
#         make                     the build system from Lab 2
#
#       Combine update + install + cleanup in one RUN so they share one layer:
#         RUN apt-get update \
#          && apt-get install -y --no-install-recommends <packages> \
#          && rm -rf /var/lib/apt/lists/*
#
#       Why one RUN? Each RUN is a layer. Splitting update and install into two
#       layers can serve a stale package index from cache. --no-install-recommends
#       and deleting /var/lib/apt/lists/* keep the image small.
#
# YOUR RUN INSTRUCTION HERE


# D4 — Set the working directory inside the container.
#       Every later command (and 'docker run') starts here. The host project will be
#       mounted onto this path at run time.
#       Form:  WORKDIR /work
#
# YOUR WORKDIR HERE


# D5 — Set the default command.
#       When the container is run with no command, build the firmware.
#       Form:  CMD ["make", "all"]
#       (A run command given on the CLI, e.g. 'docker run ... make clean',
#        overrides this default.)
#
# YOUR CMD HERE
