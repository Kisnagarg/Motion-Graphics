#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="dark"
OUTPUT="apple_motion_output.mp4"
FRAMES=2400
FPS=60
AUDIO_FILE=""
BRAND="GARGPROTOCOL"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --theme) THEME="$2"; shift ;;
        --output) OUTPUT="$2"; shift ;;
        --frames) FRAMES="$2"; shift ;;
        --audio) AUDIO_FILE="$2"; shift ;;
        --brand) BRAND="$2"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

echo "=== Apple Motion Graphics Production Pipeline ==="
echo "Theme: $THEME"
echo "Output: $OUTPUT"
echo "Frames: $FRAMES (${FPS} fps)"

# Compile engine if needed
echo "[1/3] Compiling native CoreGraphics render engine..."
clang -framework Foundation -framework AppKit -framework CoreGraphics -O3 \
    -o /tmp/apple_motion_engine "$DIR/render_engine.m"

echo "[2/3] Rendering and streaming frames directly into FFmpeg..."
if [ -n "$AUDIO_FILE" ] && [ -f "$AUDIO_FILE" ]; then
    /tmp/apple_motion_engine --theme "$THEME" --frames "$FRAMES" --brand "$BRAND" | \
    ffmpeg -y \
        -f rawvideo -pix_fmt bgra -s 1920x1080 -r "$FPS" -i - \
        -i "$AUDIO_FILE" \
        -c:v libx264 -preset medium -crf 17 -pix_fmt yuv420p \
        -c:a aac -b:a 320k \
        -movflags +faststart \
        "$OUTPUT"
else
    /tmp/apple_motion_engine --theme "$THEME" --frames "$FRAMES" --brand "$BRAND" | \
    ffmpeg -y \
        -f rawvideo -pix_fmt bgra -s 1920x1080 -r "$FPS" -i - \
        -c:v libx264 -preset medium -crf 17 -pix_fmt yuv420p \
        -movflags +faststart \
        "$OUTPUT"
fi

echo "[3/3] Master video successfully created at: $OUTPUT"
ls -lh "$OUTPUT"
