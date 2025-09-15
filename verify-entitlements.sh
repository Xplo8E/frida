#!/bin/bash

# Script to verify entitlements are preserved throughout the build process
set -e

echo "=== Frida System-Service Entitlements Verification ==="
echo

# Check if system-service binary exists
SYSTEM_SERVICE_PATH="build/subprojects/frida-core/server/system-service"
ASSETS_PATH="build/ios-assets/usr/bin/system-service"

if [ ! -f "$SYSTEM_SERVICE_PATH" ]; then
    echo "❌ Original system-service binary not found at: $SYSTEM_SERVICE_PATH"
    echo "Please run the build process first."
    exit 1
fi

echo "✅ Found original system-service binary"
echo

# Check entitlements on original binary
echo "📋 Entitlements on original binary ($SYSTEM_SERVICE_PATH):"
if codesign -d --entitlements - "$SYSTEM_SERVICE_PATH"; then
    echo "✅ Original binary has entitlements"
else
    echo "❌ Original binary has no entitlements or is not signed"
fi
echo

# Check if assets copy exists
if [ -f "$ASSETS_PATH" ]; then
    echo "✅ Found assets copy: $ASSETS_PATH"
    echo "📋 Entitlements on assets copy:"
    if codesign -d --entitlements - "$ASSETS_PATH"; then
        echo "✅ Assets copy has entitlements"
    else
        echo "❌ Assets copy has no entitlements or is not signed"
    fi
    echo
else
    echo "⚠️  Assets copy not found at: $ASSETS_PATH"
    echo "Run the build process to create it."
    echo
fi

# Check if .deb package exists and extract it for verification
DEB_PATH="build/frida_16.7.11_iphoneos-arm64_fix.deb"
if [ -f "$DEB_PATH" ]; then
    echo "✅ Found .deb package: $DEB_PATH"

    # Create temp directory for extraction
    TEMP_DIR=$(mktemp -d)
    echo "📦 Extracting .deb package to verify final binary..."

    dpkg-deb -x "$DEB_PATH" "$TEMP_DIR"

    # Check entitlements on extracted binary
    EXTRACTED_BINARY=""
    if [ -f "$TEMP_DIR/var/jb/usr/sbin/system-service" ]; then
        EXTRACTED_BINARY="$TEMP_DIR/var/jb/usr/sbin/system-service"
    elif [ -f "$TEMP_DIR/usr/sbin/system-service" ]; then
        EXTRACTED_BINARY="$TEMP_DIR/usr/sbin/system-service"
    fi

    if [ -n "$EXTRACTED_BINARY" ]; then
        echo "✅ Found extracted binary: $EXTRACTED_BINARY"
        echo "📋 Entitlements on final packaged binary:"
        if codesign -d --entitlements - "$EXTRACTED_BINARY"; then
            echo "✅ Final packaged binary has entitlements"
            echo "🎉 SUCCESS: Entitlements preserved through entire build process!"
        else
            echo "❌ Final packaged binary has no entitlements"
            echo "💥 FAILURE: Entitlements were lost during packaging!"
        fi
    else
        echo "❌ Could not find system-service binary in extracted package"
    fi

    # Cleanup
    rm -rf "$TEMP_DIR"
    echo
else
    echo "⚠️  .deb package not found at: $DEB_PATH"
    echo "Run the complete build process to create it."
    echo
fi

echo "=== Verification Complete ==="