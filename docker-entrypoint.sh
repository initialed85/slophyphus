#!/bin/bash

set -e

# shellcheck disable=SC1091
source /root/.bashrc

mkdir -p "/workspace/$(hostname)"
pushd "/workspace/$(hostname)"

# shellcheck disable=SC2016
tmux new-session -d -s "$(hostname)" -c "/workspace" -- bash -lic "pushd /workspace/$(hostname) && exec pi -c --name $(hostname) --model ${MODEL?MODEL env var empty or unset}" &

# shellcheck disable=SC2016
exec ttyd -p 7681 -w "/workspace/$(hostname)" -W -b "/$(hostname)" -t fontSize=12 -t enableResize=true -t enableTrzsz=true -t enableSixel=true -t scrollback=0 bash -c 'tmux attach -t "$(hostname)" || kill -SIGINT 1'
