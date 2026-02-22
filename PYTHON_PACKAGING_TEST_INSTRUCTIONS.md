# Python Packaging Test Instructions (Stable 16.7.11)

This guide captures the exact command flow to:
- build custom `frida` and `frida-tools` wheels,
- install and verify them in a separate test venv,
- create a portable offline bundle.

Important constraints:
- Do not touch `frida-env` (safe working env).
- Do not let pip pull upstream `frida` during install.

## 0) Repo and branch

```bash
cd /Users/vinay/frida-project/frida
git switch stable-16.7.11
```

## 1) Create and prepare test venv (not frida-env)

```bash
python3 -m venv .venv-stable-16.7.11
source .venv-stable-16.7.11/bin/activate
python -m pip install -U pip setuptools wheel build twine
```

## 2) Build wheels

Use the known-good extension from `subprojects/frida-python/frida/_frida.abi3.so`.

```bash
mkdir -p dist/custom-safe dist/custom

FRIDA_EXTENSION="$PWD/subprojects/frida-python/frida/_frida.abi3.so" \
python -m build --wheel --outdir dist/custom-safe subprojects/frida-python

python -m build --wheel --outdir dist/custom subprojects/frida-tools

python -m twine check dist/custom-safe/*.whl dist/custom/frida_tools-*.whl
```

## 3) Strict local install (never pull upstream frida)

```bash
pip uninstall -y frida frida-tools || true

pip install --no-deps --force-reinstall \
  dist/custom-safe/frida-16.7.11-cp37-abi3-macosx_15_0_arm64.whl

pip install --no-deps --force-reinstall \
  dist/custom/frida_tools-13.7.2.dev0-py3-none-any.whl

pip install --upgrade \
  colorama==0.4.6 \
  prompt-toolkit==3.0.52 \
  pygments==2.19.2 \
  websockets==13.1 \
  wcwidth==0.6.0
```

## 4) Verify runtime and package metadata

Expected pattern:
- `pkg_frida` is `16.7.11`
- runtime (`frida --version`) is custom build (example: `16.7.12-dev.1`)

```bash
python -c "import frida,frida._frida,importlib.metadata as md; \
print('runtime_frida', frida.__version__); \
print('pkg_frida', md.version('frida')); \
print('pkg_frida_tools', md.version('frida-tools')); \
print('websockets', md.version('websockets')); \
print('extension', frida._frida.__file__)"

frida --version
frida-ps --help | head -n 6
pip show frida frida-tools
```

## 5) Build portable offline bundle

```bash
rm -rf dist/portable
mkdir -p dist/portable/wheelhouse

cp dist/custom-safe/frida-16.7.11-cp37-abi3-macosx_15_0_arm64.whl dist/portable/wheelhouse/
cp dist/custom/frida_tools-13.7.2.dev0-py3-none-any.whl dist/portable/wheelhouse/

pip download -d dist/portable/wheelhouse \
  colorama==0.4.6 prompt-toolkit==3.0.52 pygments==2.19.2 websockets==13.1 wcwidth==0.6.0

cat > dist/portable/requirements-pinned.txt <<'EOF'
frida==16.7.11
frida-tools==13.7.2.dev0
colorama==0.4.6
prompt-toolkit==3.0.52
pygments==2.19.2
websockets==13.1
wcwidth==0.6.0
EOF

cat > dist/portable/INSTALL.txt <<'EOF'
python3 -m venv .venv
source .venv/bin/activate
pip install --no-index --find-links wheelhouse -r requirements-pinned.txt
python -c "import frida,importlib.metadata as md; print('runtime', frida.__version__); print('pkg frida', md.version('frida')); print('pkg tools', md.version('frida-tools'))"
frida --version
frida-ps --help
EOF

tar -czf dist/portable/frida-custom-python-bundle-stable-16.7.11-macos-arm64.tar.gz \
  -C dist/portable wheelhouse requirements-pinned.txt INSTALL.txt
```

## 6) Generate checksums

```bash
shasum -a 256 \
  dist/custom-safe/frida-16.7.11-cp37-abi3-macosx_15_0_arm64.whl \
  dist/custom/frida_tools-13.7.2.dev0-py3-none-any.whl \
  dist/portable/frida-custom-python-bundle-stable-16.7.11-macos-arm64.tar.gz
```

## 7) Optional: true offline install test in temp venv

```bash
tmpdir=$(mktemp -d /tmp/frida-portable-test.XXXXXX)
python3 -m venv "$tmpdir/venv"

"$tmpdir/venv/bin/pip" install --no-index \
  --find-links "$PWD/dist/portable/wheelhouse" \
  -r "$PWD/dist/portable/requirements-pinned.txt"

"$tmpdir/venv/bin/python" -c "import frida,importlib.metadata as md; \
print('runtime_frida', frida.__version__); \
print('pkg_frida', md.version('frida')); \
print('pkg_frida_tools', md.version('frida-tools')); \
print('websockets', md.version('websockets'))"

"$tmpdir/venv/bin/frida" --version
"$tmpdir/venv/bin/frida-ps" --help | head -n 4
```

