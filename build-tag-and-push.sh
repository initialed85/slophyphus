#!/bin/bash

set -e

docker build -t initialed85/slopyphus:latest -f ./Dockerfile .

# docker image push initialed85/slopyphus:latest
