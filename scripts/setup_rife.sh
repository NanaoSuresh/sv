#!/bin/bash
# =============================================================================
# Vplayer RIFE Setup Script
# Downloads ncnn Android libraries (with Vulkan) and RIFE v4.6 model files.
# Run from project root: ./scripts/setup_rife.sh
# =============================================================================

set -e

NCNN_VERSION="20260113"
NCNN_URL="https://github.com/Tencent/ncnn/releases/download/${NCNN_VERSION}/ncnn-${NCNN_VERSION}-android-vulkan.zip"

CPP_DIR="android/app/src/main/cpp"
ASSETS_DIR="assets/rife-v4.6"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       Vplayer RIFE Setup                 ║"
echo "║  ncnn + Vulkan + RIFE v4.6 model         ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Step 1: Download ncnn
echo "▸ Downloading ncnn ${NCNN_VERSION} for Android (with Vulkan)..."
curl -L --progress-bar -o /tmp/ncnn-android.zip "$NCNN_URL"

echo "▸ Extracting ncnn libraries..."
mkdir -p "${CPP_DIR}/ncnn"
unzip -qo /tmp/ncnn-android.zip -d /tmp/ncnn-extract

# Copy per-ABI directories
for abi in arm64-v8a armeabi-v7a x86 x86_64; do
    SRC="/tmp/ncnn-extract/ncnn-${NCNN_VERSION}-android-vulkan/${abi}"
    if [ -d "$SRC" ]; then
        echo "  ✓ ${abi}"
        cp -r "$SRC" "${CPP_DIR}/ncnn/"
    fi
done
rm -rf /tmp/ncnn-android.zip /tmp/ncnn-extract

# Step 2: Download RIFE model
echo ""
echo "▸ Downloading RIFE v4.6 model..."
mkdir -p "$ASSETS_DIR"

# RIFE models from rife-ncnn-vulkan release
RIFE_URL="https://github.com/nihui/rife-ncnn-vulkan/releases/download/20221029/rife-ncnn-vulkan-20221029-ubuntu.zip"
curl -L --progress-bar -o /tmp/rife-release.zip "$RIFE_URL"

echo "▸ Extracting RIFE v4.6 model files..."
unzip -qo /tmp/rife-release.zip -d /tmp/rife-extract 2>/dev/null || true

# Find and copy rife-v4.6 model files
RIFE_MODEL_DIR=$(find /tmp/rife-extract -type d -name "rife-v4.6" 2>/dev/null | head -1)
if [ -n "$RIFE_MODEL_DIR" ] && [ -d "$RIFE_MODEL_DIR" ]; then
    cp "$RIFE_MODEL_DIR"/*.param "$ASSETS_DIR/" 2>/dev/null || true
    cp "$RIFE_MODEL_DIR"/*.bin "$ASSETS_DIR/" 2>/dev/null || true
    echo "  ✓ Model files copied to ${ASSETS_DIR}/"
else
    echo "  ⚠ Could not find rife-v4.6 model in release archive."
    echo "    You may need to manually download from:"
    echo "    https://github.com/nihui/rife-ncnn-vulkan/tree/master/models"
    echo "    Place flownet.param and flownet.bin into ${ASSETS_DIR}/"
fi
rm -rf /tmp/rife-release.zip /tmp/rife-extract

# Step 3: Instructions
echo ""
echo "═══════════════════════════════════════════"
echo "Setup complete!"
echo ""
echo "ncnn libraries: ${CPP_DIR}/ncnn/"
echo "RIFE model:     ${ASSETS_DIR}/"
echo ""
echo "Next steps:"
echo ""
echo "1. Add CMake config to android/app/build.gradle.kts:"
echo "   android {"
echo "       externalNativeBuild {"
echo "           cmake {"
echo "               path = file(\"src/main/cpp/CMakeLists.txt\")"
echo "           }"
echo "       }"
echo "       defaultConfig {"
echo "           ndk {"
echo '               abiFilters += listOf("arm64-v8a", "armeabi-v7a")'
echo "           }"
echo "       }"
echo "   }"
echo ""
echo "2. Rebuild: flutter clean && flutter run"
echo ""
echo "═══════════════════════════════════════════"
