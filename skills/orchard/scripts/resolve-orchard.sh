#!/usr/bin/env bash
set -u

usage() {
  cat >&2 <<'USAGE'
Usage: resolve-orchard.sh [--bin|--route|--app|--version|--info|--shell]

Resolves the Orchard CLI in this order:
  1. global `orchard` from PATH
  2. bundled `orchard-cli` inside Orchard.app
USAGE
}

shell_quote() {
  printf "%q" "$1"
}

find_app() {
  local candidate

  if command -v mdfind >/dev/null 2>&1; then
    while IFS= read -r candidate; do
      if [ -x "$candidate/Contents/MacOS/orchard-cli" ]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done < <(mdfind 'kMDItemCFBundleIdentifier == "tech.5km.orchard"' 2>/dev/null)
  fi

  for candidate in "/Applications/Orchard.app" "$HOME/Applications/Orchard.app"; do
    if [ -x "$candidate/Contents/MacOS/orchard-cli" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

ORCHARD_BIN=""
ORCHARD_APP_PATH=""
ORCHARD_ROUTE="missing_app"

if ORCHARD_BIN="$(command -v orchard 2>/dev/null)"; then
  ORCHARD_ROUTE="global_cli"
else
  ORCHARD_BIN=""
  if ORCHARD_APP_PATH="$(find_app)"; then
    ORCHARD_BIN="$ORCHARD_APP_PATH/Contents/MacOS/orchard-cli"
    ORCHARD_ROUTE="bundle_cli"
  fi
fi

ORCHARD_VERSION=""
if [ -n "$ORCHARD_BIN" ]; then
  ORCHARD_VERSION="$("$ORCHARD_BIN" --version 2>/dev/null | head -n 1 || true)"
fi

case "${1:---info}" in
  --bin)
    if [ -z "$ORCHARD_BIN" ]; then
      echo "Orchard CLI not found. Install Orchard.app first." >&2
      exit 1
    fi
    printf '%s\n' "$ORCHARD_BIN"
    ;;
  --route)
    printf '%s\n' "$ORCHARD_ROUTE"
    ;;
  --app)
    printf '%s\n' "$ORCHARD_APP_PATH"
    ;;
  --version)
    printf '%s\n' "$ORCHARD_VERSION"
    ;;
  --info)
    printf 'route=%s\n' "$ORCHARD_ROUTE"
    printf 'orchard_bin=%s\n' "$ORCHARD_BIN"
    printf 'app_path=%s\n' "$ORCHARD_APP_PATH"
    printf 'version=%s\n' "$ORCHARD_VERSION"
    ;;
  --shell)
    printf 'ORCHARD_ROUTE=%s\n' "$(shell_quote "$ORCHARD_ROUTE")"
    printf 'ORCHARD_BIN=%s\n' "$(shell_quote "$ORCHARD_BIN")"
    printf 'ORCHARD_APP_PATH=%s\n' "$(shell_quote "$ORCHARD_APP_PATH")"
    printf 'ORCHARD_VERSION=%s\n' "$(shell_quote "$ORCHARD_VERSION")"
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
