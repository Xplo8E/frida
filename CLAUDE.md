# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Frida is a dynamic instrumentation toolkit composed of multiple subprojects spanning C, C++, Vala, JavaScript, TypeScript, Python, and assembly. The main repository acts as a meta-build system that orchestrates building all components.

## Architecture

### Core Components
- **frida-gum**: Low-level instrumentation engine (C/C++)
- **frida-core**: High-level APIs and process injection (Vala/C)
- **frida-tools**: CLI tools (frida, frida-trace, etc.) (Python/JavaScript)

### Language Bindings
- **frida-python**: Python bindings
- **frida-node**: Node.js bindings
- **frida-clr**: .NET bindings (Windows only)
- **frida-swift**: Swift bindings (macOS only)
- **frida-qml**: Qt/QML bindings

### Build Products
- **frida-server**: Remote debugging server for embedded/mobile targets
- **frida-gadget**: Injectable library for self-instrumentation
- **frida-inject**: Process injection tool

## Build System

Frida uses Meson build system wrapped by Make for convenience:

### Basic Build Commands
```bash
make                    # Build all components
make clean              # Clean build artifacts
make distclean          # Clean everything including dependencies
make install            # Install built components
make test               # Run test suite
```

### Build Configuration
Configure build options before building:
```bash
./configure --prefix=/usr/local --enable-shared
# or specify options directly to meson
```

### Build Options (meson.options)
Key options include:
- `frida_tools`: Build CLI tools (auto)
- `gadget`: Build frida-gadget (auto for cross-builds)
- `server`: Build frida-server (auto for cross-builds)
- `inject`: Build frida-inject (auto for cross-builds)
- `frida_python`: Build Python bindings (auto)
- `frida_node`: Build Node.js bindings (disabled by default)

### Testing
```bash
make test                           # Run all tests
FRIDA_TEST_OPTIONS="-k pattern" make test  # Run specific tests
```

## Development Workflow

### Submodule Management
Frida uses git submodules extensively. Use the helper script:
```bash
python tools/ensure-submodules.py           # Fetch core submodules
python tools/ensure-submodules.py <name>    # Fetch specific submodule
```

### Code Organization
- Each subproject is a git submodule in `subprojects/`
- Build outputs go to `build/`
- Dependencies are managed in `deps/`
- Release engineering scripts in `releng/`

### Cross-platform Building
Frida supports extensive cross-compilation. On macOS, code signing certificates are required:
```bash
export MACOS_CERTID=frida-cert
export IOS_CERTID=frida-cert
export WATCHOS_CERTID=frida-cert
export TVOS_CERTID=frida-cert
make
```

## Coding Standards

### General Rules (from CONTRIBUTING.md)
- Use meaningful variable/function names instead of comments
- Higher-level functions before lower-level functions
- Minimize nesting when possible
- No trailing spaces
- Extract repeated code into functions

### Language-Specific Rules

#### C/C++ (frida-gum: 80 chars, frida-core: 140 chars max line length)
- Space before parentheses in function calls: `func (args)`
- Space around pointer asterisks: `Type * var`
- Curly braces on new lines
- 2-space indentation
- Function names prefixed with `frida_` in frida-core

#### JavaScript
- Single quotes for strings
- 2-space indentation
- Curly braces on same line
- Semicolons mandatory
- Strict equality operators (`===`)

#### TypeScript
- Double quotes for strings
- 4-space indentation
- Pascal case for enum values
- Prefer `interface` over `type`

#### Vala
- Tab indentation
- `var` type when obvious
- Same spacing rules as C
- Curly braces on same line

#### Python
- Follow PEP-8
- Double quotes for regular strings, single for enum-like values
- Alphabetical import ordering

## File Structure

When editing existing files, examine the surrounding code to understand:
- Framework/library choices (check package.json, imports, etc.)
- Naming conventions
- Code organization patterns
- Existing utilities and patterns

## Security Notes

- Never expose or log secrets/keys
- Never commit secrets to repository
- Follow security best practices for dynamic instrumentation code