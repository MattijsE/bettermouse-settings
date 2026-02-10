#!/usr/bin/env bash
set -euo pipefail

APP_NAME="BetterMouse"
CASK="bettermouse"
BUNDLE_ID="com.naotanhaocan.BetterMouse"

# Your config on GitHub (RAW URL, not the blob page).
RAW_CFG_URL="https://raw.githubusercontent.com/MattijsE/bettermouse-settings/main/bm_cfg_8615-mxmaster4.plist"

# Download location
DEST_DIR="${HOME}/Downloads"
DEST_FILE="bm_cfg_8615-mxmaster4.plist"
DEST_PATH="${DEST_DIR}/${DEST_FILE}"

log()  { printf "\033[1;34m[bettermouse]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warning]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; }

# --- Prechecks --------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  err "Homebrew is required. Install it first:"
  err '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

# --- Quit BetterMouse if running -------------------------------------------
log "Quitting ${APP_NAME} if it is running…"
osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || true
pkill -x "${APP_NAME}" >/dev/null 2>&1 || true

# --- Uninstall (clean) ------------------------------------------------------
log "Completely removing ${APP_NAME} with Homebrew (including zap cleanup)…"
brew uninstall --cask "${CASK}" --zap >/dev/null 2>&1 || true

# Belt-and-suspenders cleanup (matches cask zap)
log "Verifying no leftovers remain…"
rm -rf \
  "${HOME}/Library/Application Support/BetterMouse" \
  "${HOME}/Library/Caches/${BUNDLE_ID}" \
  "${HOME}/Library/HTTPStorages/${BUNDLE_ID}"* \
  "${HOME}/Library/Preferences/${BUNDLE_ID}.plist" \
  "${HOME}/Library/Saved Application State/${BUNDLE_ID}.savedState" || true

# --- Reinstall --------------------------------------------------------------
log "Installing latest ${APP_NAME} via Homebrew…"
brew install --cask "${CASK}"

# --- Download config only (no auto-import) ----------------------------------
log "Downloading settings file to ${DEST_DIR}…"
mkdir -p "${DEST_DIR}"
curl -fsSL -o "${DEST_PATH}" "${RAW_CFG_URL}"

# Optional: validate it’s a well-formed plist
if command -v plutil >/dev/null 2>&1; then
  if plutil -lint "${DEST_PATH}" 2>&1 | grep -q "OK"; then
    log "Settings file validated: ${DEST_PATH}"
  else
    warn "plutil couldn't validate the plist. File: ${DEST_PATH}"
  fi
fi

# --- Open BetterMouse -------------------------------------------------------
log "Opening ${APP_NAME}…"
open -a "${APP_NAME}" || warn "Could not launch ${APP_NAME}; open it manually from /Applications."

log "Done ✅"
echo
echo "Manual import next:"
echo "  1) In ${APP_NAME}, go to the Settings tab."
echo "  2) Click “Load settings from file”."
echo "  3) Select: ${DEST_PATH}"
echo
warn "If macOS prompts for Accessibility access, enable ${APP_NAME} in System Settings → Privacy & Security → Accessibility."
``