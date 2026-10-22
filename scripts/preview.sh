#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAME=180
THEME="dark"
OUTPUT="preview.png"
BRAND="GARGPROTOCOL"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --frame) FRAME="$2"; shift ;;
        --theme) THEME="$2"; shift ;;
        --output) OUTPUT="$2"; shift ;;
        --brand) BRAND="$2"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

clang -framework Foundation -framework AppKit -framework CoreGraphics -O3 \
    -o /tmp/apple_motion_engine "$DIR/render_engine.m"

/tmp/apple_motion_engine --theme "$THEME" --frame "$FRAME" "$OUTPUT" --brand "$BRAND"
echo "Preview exported to $OUTPUT"
ls -lh "$OUTPUT"
