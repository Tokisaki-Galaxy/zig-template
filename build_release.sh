#!/bin/bash
set -e

# Define project name and version
PROJECT_NAME="zig-template"
VERSION="0.0.0"
echo "Build version: $VERSION"

# Check if zig is installed
if ! command -v zig &> /dev/null; then
  echo "Error: zig is not installed. Install it from: https://ziglang.org/download/"
  exit 1
fi

# Ensure release directory exists
RELEASE_DIR="release"
mkdir -p $RELEASE_DIR

# Build target platform lists
# Format: "arch-os" pairs
# Zig uses its own cross-compilation targets
TARGETS=(
  # Linux targets
  "x86_64-linux-musl"
  "aarch64-linux-musl"
  "arm-linux-musleabihf"
  "riscv64-linux-musl"
  "powerpc64le-linux-musl"
  "mips-linux-musl"
  "mipsel-linux-musl"

  # Windows targets
  "x86_64-windows"
  "aarch64-windows"
)

# Helper to package build artifacts
package_target() {
  local TARGET="$1"
  local TARGET_DIR="$RELEASE_DIR/$PROJECT_NAME-$VERSION-$TARGET"

  # Determine executable name based on OS
  local EXE_NAME="$PROJECT_NAME"
  if [[ "$TARGET" == *"-windows"* ]]; then
    EXE_NAME="${PROJECT_NAME}.exe"
  fi

  local BINARY_PATH="zig-out/bin/$EXE_NAME"

  if [ -f "$BINARY_PATH" ]; then
    mkdir -p "$TARGET_DIR"
    cp "$BINARY_PATH" "$TARGET_DIR/"
    cp LICENSE "$TARGET_DIR/" 2>/dev/null || echo "⚠ Warning: LICENSE file does not exist"
    cp README.md "$TARGET_DIR/" 2>/dev/null || echo "⚠ Warning: README.md file does not exist"

    echo "Creating compressed package..."
    if [[ "$TARGET" == *"-windows"* ]]; then
      # Use zip for Windows targets
      (cd "$RELEASE_DIR" && zip -r "$PROJECT_NAME-$VERSION-$TARGET.zip" "$PROJECT_NAME-$VERSION-$TARGET" > /dev/null)
    else
      tar -czvf "$RELEASE_DIR/$PROJECT_NAME-$VERSION-$TARGET.tar.gz" -C "$RELEASE_DIR" "$PROJECT_NAME-$VERSION-$TARGET" > /dev/null
    fi
    rm -rf "$TARGET_DIR"

    echo "✓ Completed $TARGET build and packaging"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    return 0
  else
    echo "✗ Binary file does not exist: $BINARY_PATH"
    FAILED_COUNT=$((FAILED_COUNT + 1))
    FAILED_TARGETS+=("$TARGET")
    return 1
  fi
}

# Build statistics
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_TARGETS=()

echo "Starting build for all target platforms..."
echo "========================================"

# Build for each target platform using zig build
for TARGET in "${TARGETS[@]}"; do
  echo ""
  echo "Starting build for $TARGET..."

  # Clean previous build artifacts
  rm -rf zig-out .zig-cache

  if zig build -Dtarget="$TARGET" -Doptimize=ReleaseSafe; then
    echo "✓ Build successful: $TARGET"
    package_target "$TARGET"
  else
    echo "✗ zig build failed: $TARGET"
    FAILED_COUNT=$((FAILED_COUNT + 1))
    FAILED_TARGETS+=("$TARGET")
  fi

  echo "----------------------------------------"
done

echo ""
echo "Build completion summary:"
echo "========================================"
echo "✓ Successfully built: $SUCCESS_COUNT targets"
if [ $FAILED_COUNT -gt 0 ]; then
  echo "✗ Failed builds: $FAILED_COUNT targets"
  echo "Failed targets:"
  for target in "${FAILED_TARGETS[@]}"; do
    echo "  - $target"
  done
fi

echo ""
echo "Release packages located in $RELEASE_DIR directory"
if [ $SUCCESS_COUNT -gt 0 ]; then
  echo "Generated files:"
  ls -la $RELEASE_DIR/*.tar.gz $RELEASE_DIR/*.zip 2>/dev/null | sed 's/^/  /' || echo "  No compressed packages generated"
fi

# Display disk usage
echo "Disk usage:"
du -sh $RELEASE_DIR 2>/dev/null | sed 's/^/  Total size: /'

if [ $FAILED_COUNT -eq 0 ]; then
  echo "🎉 All platforms built successfully!"
  exit 0
else
  echo "⚠ Some platforms failed to build, please check error messages"
  exit 1
fi
