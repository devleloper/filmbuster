#!/usr/bin/env bash
# Client checks: the single source of truth for local runs and CI.
#
# Usage: tool/ci.sh [--build-web]
#   --build-web  also run `flutter build web --release`. Web is the deploy
#                target, and `flutter analyze` does not catch broken
#                conditional imports; only a real web build does.
#
# Stops at the first failing step with a non-zero exit code.
set -euo pipefail

usage() {
  sed -n '4,7p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

build_web=false
for arg in "$@"; do
  case "$arg" in
    --build-web) build_web=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "ci.sh: unknown option: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$(dirname "${BASH_SOURCE[0]}")/.."

step() {
  printf '\n==> %s\n' "$*"
  "$@"
}

step flutter --version
step flutter pub get --enforce-lockfile
step dart format --output=none --set-exit-if-changed lib test
step flutter analyze
step flutter test
if [[ "$build_web" == true ]]; then
  step flutter build web --release
fi

printf '\n==> all client checks passed\n'
