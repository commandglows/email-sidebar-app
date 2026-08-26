#!/usr/bin/env bash
set -euo pipefail

readonly flutter_version="3.41.7"
cache_root="${VERCEL_CACHE_DIR:-${PWD}/.vercel/cache}"
while [[ "${cache_root}" != "/" && "${cache_root}" == */ ]]; do
  cache_root="${cache_root%/}"
done
readonly cache_root
readonly flutter_root="${cache_root}/flutter-${flutter_version}"

assert_safe_managed_flutter_root() {
  local expected_root
  expected_root="${cache_root}/flutter-${flutter_version}"

  if [[ -z "${cache_root}" || "${cache_root}" != /* ||
        "${cache_root}" == "/" || "${cache_root}" == *"/./"* ||
        "${cache_root}" == *"/../"* || "${cache_root}" == */. ||
        "${cache_root}" == */.. ||
        -z "${flutter_root}" || "${flutter_root}" == "/" ||
        "${flutter_root}" == "${cache_root}" ||
        "${flutter_root}" != "${expected_root}" ]]; then
    echo "Refusing unsafe managed Flutter cache target: ${flutter_root}" >&2
    return 1
  fi
}

install_managed_flutter() {
  assert_safe_managed_flutter_root
  mkdir -p "${cache_root}"
  git clone \
    --branch "${flutter_version}" \
    --depth 1 \
    https://github.com/flutter/flutter.git \
    "${flutter_root}"
}

remove_managed_flutter() {
  assert_safe_managed_flutter_root
  rm -rf -- "${flutter_root}"
}

validate_managed_flutter() {
  [[ -x "${flutter_root}/bin/flutter" ]] &&
    "${flutter_root}/bin/flutter" --version
}

if [[ -n "${FLUTTER_BIN:-}" ]]; then
  flutter_cmd="${FLUTTER_BIN}"
else
  if [[ ! -e "${flutter_root}" && ! -L "${flutter_root}" ]]; then
    install_managed_flutter
  fi

  if ! validate_managed_flutter; then
    echo "Managed Flutter cache is invalid; rebuilding ${flutter_root}." >&2
    remove_managed_flutter
    install_managed_flutter

    if ! validate_managed_flutter; then
      echo "Managed Flutter ${flutter_version} is still invalid after one rebuild." >&2
      exit 1
    fi
  fi

  flutter_cmd="${flutter_root}/bin/flutter"
fi

"${flutter_cmd}" config --no-analytics
(
  cd demo
  "${flutter_cmd}" pub get
  "${flutter_cmd}" build web --release
)
