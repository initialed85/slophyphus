#!/bin/bash

set -e

MODEL="${MODEL:-rooter/auto}"
export MODEL

NAME="${NAME:-agent}"
export NAME

mkdir -p "$(pwd)/workspace/${NAME}" || true

docker build -t initialed85/slopyphus:latest -f ./Dockerfile .

docker run --rm -it \
	--privileged \
	--name "${NAME}" \
	--hostname "${NAME}" \
	-e NAME \
	-e MODEL \
	-e PI_TEAM_ROOM_NETWORK \
	-e PI_TEAM_ROOM_SHARED_SECRET \
	-e PI_TEAM_ROOM_PEERS \
	-v "${HOME}/.pi/agent/models.json:/root/.pi/agent/models.json" \
	-v "$(pwd)/workspace:/workspace" \
	-p 7681:7681 \
	initialed85/slopyphus:latest
