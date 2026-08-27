#!/bin/sh
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd -P)"
UID_NUM="$(id -u)"
LABEL="org.hister.agent"
BIN="$HOME/.local/bin/hister"
CONF_DIR="$HOME/Library/Preferences/hister"
DATA_DIR="$(yq '.app.directory' < config.yml)"

mkdir -p "$HOME/.local/bin" "$CONF_DIR" "$DATA_DIR" "$HOME/Library/LaunchAgents"

if [ ! -x "$BIN" ]; then
  case "$(uname -m)" in
    arm64)  ARCH=darwin_arm64  ;;
    x86_64) ARCH=darwin_amd64  ;;
    *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
  esac
  echo "fetching hister ($ARCH)..."
  URL="$(curl -fsSL https://api.github.com/repos/asciimoo/hister/releases/latest \
         | grep -o '"browser_download_url": *"[^"]*'"$ARCH"'[^"]*"' \
         | cut -d'"' -f4 | head -n1)"
  [ -n "$URL" ] || { echo "no $ARCH asset found; download manually" >&2; exit 1; }
  curl -fsSL "$URL" -o "$BIN"
  chmod +x "$BIN"
  xattr -d com.apple.quarantine "$BIN" 2>/dev/null || true
fi

ln -sfn "$REPO_DIR/config.yml"      "$CONF_DIR/config.yml"
ln -sfn "$REPO_DIR/$LABEL.plist"    "$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$HOME/Library/LaunchAgents/$LABEL.plist"

echo "hister on http://127.0.0.1:4433 — logs: ~/Library/Logs/hister.log"

