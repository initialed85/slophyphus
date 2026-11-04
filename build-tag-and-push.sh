#!/bin/bash
#
# Build, tag and push both images this repo ships.
#
#   ./build-tag-and-push.sh                 # -> initialed85/slopyphus:latest (+ :<git sha>) and the same
#                                           #    for initialed85/slopyphus-nginx
#   NO_PUSH=1 ./build-tag-and-push.sh       # local build only, for testing an image
#
# The contract is the same as .woodpecker/build.yaml: every published image gets a mutable `:latest` and
# an immutable full-sha tag, and the sha is what home-ops/clusters/dev/applications/slopyphus/
# kustomization.yaml pins. `latest` is a convenience for `docker run`; nothing in the cluster should rely
# on it (both Deployments pull an immutable sha with imagePullPolicy: IfNotPresent).
#
# A sha tag is only created - and only pushed - from a clean worktree, otherwise the tag would claim the
# image is bytes it was not built from.
#
# Set DOCKER_HOST to build against another daemon, e.g. against a CI node:
#   DOCKER_HOST=tcp://192.168.1.213:2375 ./build-tag-and-push.sh

set -e

# run from anywhere; the script always works on its own repo
pushd "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1
trap 'popd >/dev/null 2>&1 || true' exit

if ! command -v docker >/dev/null 2>&1; then
    echo "error: docker not found" >&2
    exit 1
fi

# `docker.io/` spelled out to match home-ops' kustomization.yaml, whose images: transformer matches the
# name string rather than a normalised reference.
AGENT_IMAGE="${AGENT_IMAGE:-docker.io/initialed85/slopyphus}"
FRONT_IMAGE="${FRONT_IMAGE:-docker.io/initialed85/slopyphus-nginx}"
TAG="${1:-latest}"
PLATFORM="${PLATFORM:-linux/amd64}"

echo "==> building ${AGENT_IMAGE}:${TAG} (${PLATFORM})"
docker build --pull --progress=plain --platform="${PLATFORM}" -t "${AGENT_IMAGE}:${TAG}" -f ./Dockerfile .

echo "==> building ${FRONT_IMAGE}:${TAG} (${PLATFORM})"
docker build --pull --progress=plain --platform="${PLATFORM}" -t "${FRONT_IMAGE}:${TAG}" -f ./Dockerfile.nginx .

sha=""
if git rev-parse --git-dir >/dev/null 2>&1 && git diff-index --quiet HEAD -- 2>/dev/null; then
    sha="$(git rev-parse HEAD)"
    for image in "$AGENT_IMAGE" "$FRONT_IMAGE"; do
        docker tag "${image}:${TAG}" "${image}:${sha}"
    done
else
    echo "==> worktree dirty, skipping the immutable sha tag"
fi

if [[ -n "${NO_PUSH}" ]]; then
    echo "==> NO_PUSH set, skipping push"
    docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E 'slopyphus|REPOSITORY'
    exit 0
fi

for image in "$AGENT_IMAGE" "$FRONT_IMAGE"; do
    echo "==> pushing ${image}:${TAG}"
    docker image push "${image}:${TAG}"
    if [[ -n "${sha}" ]]; then
        echo "==> pushing ${image}:${sha}"
        docker image push "${image}:${sha}"
    fi
done

echo "==> done: ${AGENT_IMAGE}:${TAG}${sha:+ (and :${sha})}, ${FRONT_IMAGE}:${TAG}${sha:+ (and :${sha})}"
