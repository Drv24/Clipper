#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Clipper"
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGING_DIR="${SCRIPT_DIR}/dist"
APP_BUNDLE="${STAGING_DIR}/${APP_NAME}.app"
DMG_TEMP="${STAGING_DIR}/${APP_NAME}_tmp.dmg"

# Parse --universal flag
UNIVERSAL=false
for arg in "$@"; do
    [[ "${arg}" == "--universal" ]] && UNIVERSAL=true
done

cd "${SCRIPT_DIR}"

if [[ "${UNIVERSAL}" == true ]]; then
    echo "==> Building ${APP_NAME} (release, universal: arm64 + x86_64)..."
    swift build -c release --arch arm64 --arch x86_64
    BINARY="${SCRIPT_DIR}/.build/apple/Products/Release/${APP_NAME}"
    DMG_FINAL="${SCRIPT_DIR}/${APP_NAME}-${VERSION}-universal.dmg"
else
    HOST_ARCH="$(uname -m)"
    echo "==> Building ${APP_NAME} (release, ${HOST_ARCH})..."
    swift build -c release
    BINARY="${SCRIPT_DIR}/.build/release/${APP_NAME}"
    DMG_FINAL="${SCRIPT_DIR}/${APP_NAME}-${VERSION}-${HOST_ARCH}.dmg"
fi

if [[ ! -f "${BINARY}" ]]; then
    echo "ERROR: Binary not found at ${BINARY}" >&2
    exit 1
fi

if [[ "${UNIVERSAL}" == true ]]; then
    echo "==> Architectures in binary: $(lipo -archs "${BINARY}")"
fi

echo "==> Assembling ${APP_NAME}.app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BINARY}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "${SCRIPT_DIR}/Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

echo "==> App bundle assembled at ${APP_BUNDLE}"

echo "==> Creating DMG..."
rm -f "${DMG_TEMP}" "${DMG_FINAL}"
mkdir -p "${STAGING_DIR}"

hdiutil create \
    -size 20m \
    -fs HFS+ \
    -volname "${APP_NAME}" \
    -layout GPTSPUD \
    -ov \
    "${DMG_TEMP}"

MOUNT_POINT=$(hdiutil attach "${DMG_TEMP}" -noautoopen -nobrowse | \
    awk '/\/Volumes/ { print $NF }')

if [[ -z "${MOUNT_POINT}" ]]; then
    echo "ERROR: Failed to mount staging DMG" >&2
    exit 1
fi

cp -R "${APP_BUNDLE}" "${MOUNT_POINT}/"
ln -s /Applications "${MOUNT_POINT}/Applications"

hdiutil detach "${MOUNT_POINT}" -quiet

hdiutil convert "${DMG_TEMP}" \
    -format UDZO \
    -o "${DMG_FINAL}" \
    -ov

rm -f "${DMG_TEMP}"

echo ""
echo "Done. DMG created at:"
echo "  ${DMG_FINAL}"
echo ""
echo "To install: open ${APP_NAME}-${VERSION}.dmg and drag Clipper to Applications."
