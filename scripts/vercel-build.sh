#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR=".vercel/flutter"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"
: "${API_BASE_URL:?API_BASE_URL must point to the Django /api/v1 endpoint}"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
fi

"$FLUTTER_BIN" config --enable-web
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" build web \
  --release \
  --base-href=/ \
  --no-wasm-dry-run \
  --dart-define=API_BASE_URL="$API_BASE_URL"
