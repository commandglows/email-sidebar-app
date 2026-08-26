#!/usr/bin/env bash
set -euo pipefail

readonly flutter_version="3.41.7"
readonly cache_root="${VERCEL_CACHE_DIR:-${PWD}/.vercel/cache}"
readonly flutter_root="${cache_root}/flutter-${flutter_version}"

if [[ -n "${FLUTTER_BIN:-}" ]]; then
  flutter_cmd="${FLUTTER_BIN}"
else
  if [[ ! -x "${flutter_root}/bin/flutter" ]]; then
    mkdir -p "${cache_root}"
    git clone \
      --branch "${flutter_version}" \
      --depth 1 \
      https://github.com/flutter/flutter.git \
      "${flutter_root}"
  fi
  flutter_cmd="${flutter_root}/bin/flutter"
fi

"${flutter_cmd}" config --no-analytics
(
  cd demo
  "${flutter_cmd}" pub get
  "${flutter_cmd}" build web --release
)
