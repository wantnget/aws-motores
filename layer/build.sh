#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "==> [1/2] Construyendo imagen Docker para Lambda Layer..."
docker build -t lambda-layer-builder .

echo "==> [2/2] Extrayendo layer.zip compatible con Lambda..."
docker run --rm \
  --entrypoint /bin/sh \
  -v "$DIR:/output" \
  lambda-layer-builder \
  -c 'cd /opt && zip -r9 /output/layer.zip python'

echo "==> Layer empaquetada exitosamente en $DIR/layer.zip"