#!/bin/bash
set -e

# ── Config ─────────────────────────────────────────────────────────────────────
# Pour signer avec Developer ID (compte Apple Developer requis) :
#   export DEVELOPER_ID="Developer ID Application: Ton Nom (TEAMID)"
# Laisser vide pour une signature ad-hoc (test local uniquement)
DEVELOPER_ID="${DEVELOPER_ID:-}"

APP_NAME="NEAT"
APP_BUNDLE="neat.app"
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="build/macos/Build/Products/Release"
OUTPUT_DIR="build/macos/dist"
APP_PATH="${BUILD_DIR}/${APP_BUNDLE}"

# ── Colors ─────────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

log()  { echo -e "${CYAN}[▶]${RESET} $1"; }
ok()   { echo -e "${GREEN}[✓]${RESET} $1"; }
fail() { echo -e "${RED}[✗]${RESET} $1"; exit 1; }

# ── Checks ─────────────────────────────────────────────────────────────────────
log "NEAT Build Script — v${VERSION}"
echo ""

if ! command -v create-dmg &> /dev/null; then
  fail "create-dmg not found. Install it with: brew install create-dmg"
fi

# ── Flutter build ──────────────────────────────────────────────────────────────
log "Building macOS release..."
flutter build macos --release
ok "Flutter build complete — ${APP_PATH}"

# ── Code signing ──────────────────────────────────────────────────────────────
if [ -n "${DEVELOPER_ID}" ]; then
  log "Signing with Developer ID: ${DEVELOPER_ID}..."
  codesign --deep --force --options runtime \
    --entitlements "macos/Runner/Release.entitlements" \
    --sign "${DEVELOPER_ID}" "${APP_PATH}"
  ok "App signed."

  log "Notarizing (this may take a few minutes)..."
  xcrun notarytool submit "${APP_PATH}" --wait --keychain-profile "notarytool-profile"
  xcrun stapler staple "${APP_PATH}"
  ok "Notarization complete."
else
  log "No DEVELOPER_ID set — stripping quarantine and signing ad-hoc..."
  sudo xattr -cr "${APP_PATH}" 2>/dev/null || true
  codesign --force --deep --entitlements "macos/Runner/Release.entitlements" --sign - "${APP_PATH}"
  ok "Ad-hoc signature applied with entitlements."
fi

# ── DMG packaging ─────────────────────────────────────────────────────────────
mkdir -p "${OUTPUT_DIR}"

rm -f "${OUTPUT_DIR}/${DMG_NAME}"
log "Creating ${DMG_NAME}..."

create-dmg \
  --volname "${APP_NAME}" \
  --volicon "assets/images/neat_logo.png" \
  --window-pos 200 120 \
  --window-size 540 380 \
  --icon-size 128 \
  --icon "${APP_BUNDLE}" 140 190 \
  --hide-extension "${APP_BUNDLE}" \
  --app-drop-link 400 190 \
  "${OUTPUT_DIR}/${DMG_NAME}" \
  "${APP_PATH}"

# ── Post-DMG Fix ──────────────────────────────────────────────────────────────
log "Applying final security bypass on DMG..."
sudo xattr -cr "${OUTPUT_DIR}/${DMG_NAME}" 2>/dev/null || true
ok "DMG created → ${OUTPUT_DIR}/${DMG_NAME}"
echo ""
echo -e "${GREEN}✓✓ Done!${RESET} ${APP_NAME} v${VERSION} ready for distribution."
