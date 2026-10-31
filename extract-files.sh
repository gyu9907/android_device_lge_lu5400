#!/bin/sh

set -eu

VENDOR=lge
DEVICE=lu5400

DEVICE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$DEVICE_DIR/../../.." && pwd)
BASE="$ROOT_DIR/vendor/$VENDOR/$DEVICE/proprietary"
# The manifest contains only required original blobs. In particular, do not
# extract the source-built rild/libril or the P940 Broadcom GPS components.
SOURCE=${1:-adb}
if [ "$SOURCE" != adb ] && [ -d "$SOURCE/system" ]; then
    SOURCE="$SOURCE/system"
fi
STAGING="$ROOT_DIR/vendor/$VENDOR/$DEVICE/.proprietary.new.$$"

cleanup() {
    rm -rf "$STAGING"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$STAGING"

while IFS='|' read -r FILE EXPECTED_HASH; do
    case "$FILE" in
        ''|'#'*) continue ;;
    esac

    DEST="$STAGING/$FILE"
    mkdir -p "$(dirname -- "$DEST")"

    if [ "$SOURCE" = adb ]; then
        adb pull "/system/$FILE" "$DEST"
    else
        cp "$SOURCE/${FILE#/}" "$DEST"
    fi

    ACTUAL_HASH=$(sha1sum "$DEST" | awk '{print $1}')
    if [ -z "${EXPECTED_HASH:-}" ]; then
        echo "Missing SHA-1 for $FILE" >&2
        exit 1
    fi
    if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
        echo "SHA-1 mismatch for $FILE" >&2
        echo "  expected: $EXPECTED_HASH" >&2
        echo "  actual:   $ACTUAL_HASH" >&2
        exit 1
    fi
done < "$DEVICE_DIR/proprietary-files.txt"

rm -rf "$BASE"
mv "$STAGING" "$BASE"
trap - EXIT HUP INT TERM

"$DEVICE_DIR/setup-makefiles.sh"
