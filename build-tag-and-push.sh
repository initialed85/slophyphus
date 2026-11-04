#!/bin/bash

set -e

docker build -t initialed85/slopyphus:latest -f ./Dockerfile .
docker build -t initialed85/slopyphus-nginx:latest -f ./Dockerfile.nginx .

# docker image push initialed85/slopyphus:latest
# docker image push initialed85/slopyphus-nginx:latest
