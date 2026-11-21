#!/bin/sh
set -eu
cd /opt/inferzero
./zero-launcher.sh --check || true
# Inferzero has no built-in authentication; the CA template publishes this port on the configured network.
# shellcheck disable=SC2086
exec ./zero-launcher.sh --model "${MODEL:-4b}" --host 0.0.0.0 --port "${PORT:-8090}" --gpus "${GPUS:-1}" --no-browser --yes -- ${SERVER_ARGS:-}
