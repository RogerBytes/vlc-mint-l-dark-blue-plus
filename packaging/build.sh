#!/usr/bin/env bash
# Builds the .deb package and the two .vlt skins in a Docker container.
# Usage: ./packaging/build.sh            -> output in ./dist/
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="vlc-mint-l-build:ubuntu-24.04"

mkdir -p "$REPO/dist"

sudo docker build -t "$IMAGE" -f "$REPO/packaging/docker/Dockerfile.ubuntu-24.04" "$REPO/packaging/docker"

sudo docker run --rm \
    -v "$REPO:/repo:ro" \
    -v "$REPO/dist:/dist" \
    -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    "$IMAGE" bash /repo/packaging/debian/build-deb.sh
