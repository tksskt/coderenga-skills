#!/usr/bin/env bash
# Installs CodeRenga from the latest GitHub Release and initializes coderenga.d.
# Usage examples:
#   bash .cursor/skills/coderenga/scripts/install-coderenga.sh
#   REPO=tksskt/CodeRenga INSTALL_DIR=.local/bin INIT_DIR=. bash .cursor/skills/coderenga/scripts/install-coderenga.sh
set -euo pipefail

REPO="${REPO:-tksskt/CodeRenga}"
INSTALL_DIR="${INSTALL_DIR:-.local/bin}"
INIT_DIR="${INIT_DIR:-.}"
INSTALL_DIR="$(mkdir -p "$INSTALL_DIR" && cd "$INSTALL_DIR" && pwd)"

say() { printf '[coderenga-install] %s\n' "$*"; }

find_existing() {
  if command -v coderenga >/dev/null 2>&1; then
    command -v coderenga
    return 0
  fi
  if command -v coderenga.exe >/dev/null 2>&1; then
    command -v coderenga.exe
    return 0
  fi
  if [[ -x "$INSTALL_DIR/coderenga" ]]; then
    printf '%s\n' "$INSTALL_DIR/coderenga"
    return 0
  fi
  if [[ -x "$INSTALL_DIR/coderenga.exe" ]]; then
    printf '%s\n' "$INSTALL_DIR/coderenga.exe"
    return 0
  fi
  return 1
}

if CODERENGA_BIN="$(find_existing)"; then
  say "Found existing CodeRenga: $CODERENGA_BIN"
else
  say "coderenga not found. Fetching latest release from https://github.com/${REPO}/releases/latest"
  api="https://api.github.com/repos/${REPO}/releases/latest"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  json_file="$tmp/release.json"
  curl -fsSL -H 'User-Agent: coderenga-skill-installer' "$api" -o "$json_file" || {
    echo "No latest GitHub Release was found for ${REPO}. Create a release with a CodeRenga binary asset, then rerun this installer." >&2
    exit 1
  }

  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$os" in
    darwin) os_re='darwin|macos|osx' ;;
    linux) os_re='linux' ;;
    msys*|mingw*|cygwin*) os_re='windows|win' ;;
    *) os_re="$os" ;;
  esac

  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) arch_re='amd64|x64|x86_64' ;;
    aarch64|arm64) arch_re='arm64|aarch64' ;;
    *) arch_re="$arch" ;;
  esac

  asset_line="$(python3 - "$os_re" "$arch_re" "$json_file" <<'PY'
import json, re, sys
os_re, arch_re, json_file = sys.argv[1], sys.argv[2], sys.argv[3]
with open(json_file, "r", encoding="utf-8") as f:
    data = json.load(f)
assets = data.get("assets") or []
patterns = [
    rf"coderenga.*({os_re}).*({arch_re}).*\.(zip|tar\.gz|tgz|exe)$",
    rf"coderenga.*({arch_re}).*({os_re}).*\.(zip|tar\.gz|tgz|exe)$",
    rf"coderenga.*\.(zip|tar\.gz|tgz|exe)$",
]
for pat in patterns:
    for asset in assets:
        name = asset.get("name", "")
        url = asset.get("browser_download_url", "")
        if re.search(pat, name, re.I) and url:
            print(name + "\t" + url)
            raise SystemExit(0)
print("", end="")
raise SystemExit(2)
PY
  )" || {
    echo "No suitable CodeRenga asset found in the latest release for ${os}/${arch}." >&2
    exit 1
  }

  if [[ -z "$asset_line" ]]; then
    echo "No suitable CodeRenga asset found in the latest release for ${os}/${arch}." >&2
    exit 1
  fi

  asset_name="${asset_line%%$'\t'*}"
  asset_url="${asset_line#*$'\t'}"
  mkdir -p "$INSTALL_DIR"
  say "Downloading ${asset_name}"
  curl -fL -H 'User-Agent: coderenga-skill-installer' -o "$tmp/$asset_name" "$asset_url"

  out="$tmp/out"
  mkdir -p "$out"
  case "$asset_name" in
    *.zip)
      unzip -q "$tmp/$asset_name" -d "$out"
      ;;
    *.tar.gz|*.tgz)
      tar -xzf "$tmp/$asset_name" -C "$out"
      ;;
    *.exe)
      cp "$tmp/$asset_name" "$out/coderenga.exe"
      ;;
    *)
      echo "Unsupported asset type: $asset_name" >&2
      exit 1
      ;;
  esac

  bin="$(find "$out" -type f \( -name coderenga -o -name coderenga.exe \) | head -n 1)"
  if [[ -z "$bin" ]]; then
    echo "Archive did not contain coderenga or coderenga.exe." >&2
    exit 1
  fi

  if [[ "$bin" == *.exe ]]; then
    cp "$bin" "$INSTALL_DIR/coderenga.exe"
    chmod +x "$INSTALL_DIR/coderenga.exe"
    CODERENGA_BIN="$(cd "$INSTALL_DIR" && pwd)/coderenga.exe"
  else
    cp "$bin" "$INSTALL_DIR/coderenga"
    chmod +x "$INSTALL_DIR/coderenga"
    CODERENGA_BIN="$(cd "$INSTALL_DIR" && pwd)/coderenga"
  fi
fi

say "Initializing CodeRenga under $INIT_DIR"
(cd "$INIT_DIR" && "$CODERENGA_BIN" --init)
say "Done. Try: $CODERENGA_BIN --cwd . --mode reviewer 'inspect this repository'"
