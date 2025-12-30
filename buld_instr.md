## Complete Build Script

Here's a complete script that performs all the above steps:

```bash
#!/bin/bash
set -e

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
echo "Current directory: $(pwd)"

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

# cp /Users/vinay/frida-project/frida/build/subprojects/frida-core/lib/gadget/frida-gadget.dylib-arm64 ~/.cache/frida/gadget-ios.dylib


## to build frida-server deb for ios with preserved entitlements


  make distclean
  export IOS_CERTID=frida-cert
  ./configure --host=ios-arm64 --enable-server
  make

  # Code sign the binary

  # Prepare iOS assets directory
  mkdir -p build/ios-assets/usr/bin build/ios-assets/usr/lib/frida

  codesign -f -s "$IOS_CERTID" --preserve-metadata=entitlements build/subprojects/frida-core/server/frida-server
  codesign -d --entitlements - build/subprojects/frida-core/server/frida-server 2>/dev/null | head -10

  # Copy with CORRECT naming (preserve frida-server name AND entitlements)
  cp -p build/subprojects/frida-core/server/frida-server build/ios-assets/usr/bin/frida-server

  # Re-sign to ensure entitlements are preserved after copy
  codesign -f -s "$IOS_CERTID" --preserve-metadata=entitlements build/ios-assets/usr/bin/frida-server

  # Verify entitlements are still present
  echo "Verifying entitlements after copy and re-signing:"
  codesign -d --entitlements - build/ios-assets/usr/bin/frida-server 2>/dev/null | head -10

  cp build/subprojects/frida-core/lib/agent/frida-agent.dylib build/ios-assets/usr/lib/frida/

codesign -f -s "$IOS_CERTID" --preserve-metadata=entitlements build/ios-assets/usr/lib/frida/frida-agent.dylib
  # Package the .deb with original identifiers (using modified packaging script)
FRIDA_VERSION=16.7.11 subprojects/frida-core/tools/package-server-fruity-with-entitlements.sh iphoneos-arm64 build/ios-assets build/frida_16.7.11_iphoneos-arm64_original.deb

  # Verify entitlements are preserved in the final .deb package
  ./verify-entitlements.sh
```

## Key Changes Made:

1. **Fixed incorrect commands**: Replaced `$ pwd` and `~/frida` with proper `echo "Current directory: $(pwd)"`
2. **Consistent codesign usage**: All codesign commands now properly sign with certificate identity
3. **Use `cp -p` instead of `cp`**: Preserves file metadata including extended attributes
4. **Re-sign after copy**: Uses `codesign -f -s "$IOS_CERTID" --preserve-metadata=entitlements`
5. **Modified packaging script**: `package-server-fruity-with-entitlements.sh` that preserves entitlements
6. **Verification steps**: Added multiple verification points to check entitlements at each stage
7. **Final verification script**: `verify-entitlements.sh` to validate the complete process
8. **Error handling**: Enabled `set -e` to exit on errors
9. **Original names**: Using `frida-server` and `frida-agent.dylib` instead of disguised names

## Usage:
Run the iOS build section in `buld_instr.md` and it will now preserve entitlements throughout the entire process while using original Frida names.

---

## Building Python Packages for PyPI (macOS ARM64)

This section covers building Python wheels and source distributions for publishing to PyPI.

### Prerequisites

```bash
# Install required tools
pip install twine build wheel
```

### Build Script for PyPI Packages

```bash
#!/bin/bash
set -e

echo "=== Building Frida Python Packages for PyPI (macOS ARM64) ==="

# Activate virtual environment
source frida-env/bin/activate

# Version is auto-detected from git tags/commits
# (Optional) Override version: export FRIDA_VERSION=16.7.11
# To check what version will be used:
python -c "import sys; sys.path.insert(0, 'releng'); from releng.frida_version import detect; print('Version:', detect('.').name.replace('-dev.', '.dev'))"

# Clean previous distributions
rm -rf subprojects/frida-python/dist/
rm -rf subprojects/frida-tools/dist/
mkdir -p subprojects/frida-python/dist/
mkdir -p subprojects/frida-tools/dist/

# Step 1: Build native Frida components
echo ""
echo "Step 1: Building native Frida components..."
make distclean
export MACOS_CERTID=frida-cert
./configure --enable-gadget --enable-server
make

# Step 2: Build frida-python wheel
echo ""
echo "Step 2: Building frida-python wheel for macOS ARM64..."



# Set platform tag for macOS ARM64
export _PYTHON_HOST_PLATFORM=macosx-11.0-arm64

# Build wheel
cd subprojects/frida-python

# Point to the built native extension
export FRIDA_EXTENSION=$(find . -name "_frida.abi3.so" | head -1)
echo "Using extension: $FRIDA_EXTENSION"

pip wheel -w dist --no-deps .

# Build source distribution (only needed once, platform-independent)
echo "Building frida-python source distribution..."
python setup.py sdist --dist-dir dist/

cd ../..

# Step 3: Build frida-tools
echo ""
echo "Step 3: Building frida-tools (pure Python)..."
cd subprojects/frida-tools

# Build source distribution
python setup.py sdist --dist-dir dist/

# Build wheel (pure Python, works on all platforms)
pip wheel -w dist --no-deps .

cd ../..

# Summary
echo ""
echo "=== Build Complete ==="
echo ""
echo "frida-python packages:"
ls -lh subprojects/frida-python/dist/
echo ""
echo "frida-tools packages:"
ls -lh subprojects/frida-tools/dist/
echo ""
echo "Next steps:"
echo "  1. Test locally: pip install subprojects/frida-python/dist/*.whl"
echo "  2. Upload to Test PyPI: twine upload --repository testpypi subprojects/frida-python/dist/* subprojects/frida-tools/dist/*"
echo "  3. Upload to PyPI: twine upload subprojects/frida-python/dist/* subprojects/frida-tools/dist/*"
```

### Testing the Built Packages Locally

```bash
# Create a test virtual environment
python -m venv test-env
source test-env/bin/activate

# Install the built wheel
pip install subprojects/frida-python/dist/frida-*.whl
pip install subprojects/frida-tools/dist/frida_tools-*.whl

# Test it works
python -c "import frida; print('Frida version:', frida.__version__)"
frida --version

# Clean up
deactivate
rm -rf test-env
```

### Upload to PyPI

#### Configure PyPI Credentials

Create `~/.pypirc`:

```ini
[distutils]
index-servers =
    pypi
    testpypi

[pypi]
username = __token__
password = pypi-YOUR_API_TOKEN_HERE

[testpypi]
repository = https://test.pypi.org/legacy/
username = __token__
password = pypi-YOUR_TEST_API_TOKEN_HERE
```

Or use environment variables:
```bash
export TWINE_USERNAME=__token__
export TWINE_PASSWORD=pypi-YOUR_API_TOKEN_HERE
```

#### Upload Commands

```bash
# 1. Upload to Test PyPI first (recommended)
twine upload --repository testpypi subprojects/frida-python/dist/* subprojects/frida-tools/dist/*

# 2. Test install from Test PyPI
pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple frida frida-tools

# 3. Upload to Production PyPI
twine upload subprojects/frida-python/dist/* subprojects/frida-tools/dist/*
```

### Notes for Multi-Platform Releases

The wheel built above is **only for macOS ARM64**. For a complete PyPI release supporting all platforms, you need to build wheels on:

- **Windows**: x86, x86_64
- **macOS**: x86_64, arm64
- **Linux**: x86, x86_64, armhf, arm64

Each platform builds its wheel separately, then all wheels + one source distribution are uploaded together.

The official Frida project uses GitHub Actions CI to build all platform wheels automatically (see `.github/workflows/ci.yml`).

For personal/testing use, the macOS ARM64 wheel is sufficient for your machine.

### Quick Build Command

Save this as `build-pypi-packages.sh`:

```bash
#!/bin/bash
set -e

source frida-env/bin/activate

# Optional: Override auto-detected version
# export FRIDA_VERSION=16.7.11

make distclean
export MACOS_CERTID=frida-cert
./configure --enable-gadget --enable-server
make

export FRIDA_EXTENSION=$(find build/subprojects/frida-python -name "_frida.abi3.so" | head -1)
export _PYTHON_HOST_PLATFORM=macosx-11.0-arm64

cd subprojects/frida-python
rm -rf dist/ && mkdir dist/
pip wheel -w dist --no-deps .
python setup.py sdist --dist-dir dist/
cd ../..

cd subprojects/frida-tools
rm -rf dist/ && mkdir dist/
python setup.py sdist --dist-dir dist/
pip wheel -w dist --no-deps .
cd ../..

echo "Done! Packages in subprojects/frida-python/dist/ and subprojects/frida-tools/dist/"
ls -lh subprojects/frida-python/dist/
ls -lh subprojects/frida-tools/dist/
```

Then run:
```bash
chmod +x build-pypi-packages.sh
./build-pypi-packages.sh
```

### Version Detection

The version is automatically detected from git in this order:
1. Git tags (e.g., `16.7.11`)
2. Git commit + branch info (e.g., `16.7.12-dev.1`)
3. Fallback to `0.0.0` if git info unavailable

**Only set `FRIDA_VERSION` manually if you need to override the auto-detection.**