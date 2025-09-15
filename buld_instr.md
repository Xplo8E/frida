## Complete Build Script

Here's a complete script that performs all the above steps:

```bash
#!/bin/bash
# set -e

# Activate frida-env
# source /Users/vinay/frida-project/frida/frida-env/bin/activate

# Clean any previous build
# make clean

# Build web UI components
# cd subprojects/frida-tools/apps/tracer
# npm install
# npm run build
# cd ../../../../

# Build core components without code signing
$ pwd
~/frida

## mac builds, for building, frida, frida-tools, agent

source frida-env/bin/activate
make distclean
export MACOS_CERTID=frida-cert
./configure --enable-gadget --enable-server
make

# Copy web UI assets
# cp ./build/subprojects/frida-tools/apps/tracer/tracer_ui.zip subprojects/frida-tools/frida_tools/

# Install packages
pip uninstall -y frida frida-tools 

# pip install -e subprojects/frida-python --no-deps && pip install -e subprojects/frida-tools --no-deps

FRIDA_EXTENSION=/Users/vinay/frida-project/frida/build/subprojects/frida-python/frida/_frida/_frida.abi3.so pip install -e subprojects/frida-python --no-deps

pip install -e subprojects/frida-tools --no-deps

. ./frida-env/bin/activate && python -c "import frida._frida; print(frida._frida.__file__)"

# copy
# cp build/subprojects/frida-python/frida/_frida/_frida.abi3.so subprojects/frida-python/frida/_frida.abi3.so

. ./frida-env/bin/activate && python -c "import frida; print('Frida version:', frida.__version__)"

cp /Users/vinay/frida-project/frida/build/subprojects/frida-core/lib/gadget/SystemFramework.dylib ~/.cache/frida

## to build frida-server deb for ios with preserved entitlements


  make distclean
  export IOS_CERTID=frida-cert
  ./configure --host=ios-arm64 --enable-server
  make

  # Code sign the binary
  codesign -v build/subprojects/frida-core/server/system-service
  codesign -d --entitlements - build/subprojects/frida-core/server/system-service 2>/dev/null | head -10

  # Prepare iOS assets directory
  mkdir -p build/ios-assets/usr/bin build/ios-assets/usr/lib/frida

  # Copy with CORRECT naming (preserve system-service name AND entitlements)
  cp -p build/subprojects/frida-core/server/system-service build/ios-assets/usr/bin/system-service

  # Re-sign to ensure entitlements are preserved after copy
  codesign -f -s "$IOS_CERTID" --preserve-metadata=entitlements build/ios-assets/usr/bin/system-service

  # Verify entitlements are still present
  echo "Verifying entitlements after copy and re-signing:"
  codesign -d --entitlements - build/ios-assets/usr/bin/system-service 2>/dev/null | head -10

  cp build/subprojects/frida-core/lib/agent/system-agent.dylib build/ios-assets/usr/lib/frida/

codesign -f -s "$IOS_CERTID" --preserve-metadata=entitlements build/ios-assets/usr/lib/frida/system-agent.dylib
  # Package the .deb with disguised identifiers (using modified packaging script)
FRIDA_VERSION=16.7.11 subprojects/frida-core/tools/package-server-fruity-with-entitlements.sh iphoneos-arm64 build/ios-assets build/frida_16.7.11_iphoneos-arm64_fix.deb

  # Verify entitlements are preserved in the final .deb package
  ./verify-entitlements.sh
```

## Key Changes Made:

1. **Use `cp -p` instead of `cp`**: Preserves file metadata including extended attributes
2. **Re-sign after copy**: Uses `codesign -f -s "$IOS_CERTID" --preserve-metadata=entitlements`
3. **Modified packaging script**: `package-server-fruity-with-entitlements.sh` that preserves entitlements
4. **Verification steps**: Added multiple verification points to check entitlements at each stage
5. **Final verification script**: `verify-entitlements.sh` to validate the complete process

## Usage:
Run the iOS build section in `buld_instr.md` and it will now preserve entitlements throughout the entire process.