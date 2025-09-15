# Frida Detection Bypass Reconnaissance Findings

## Overview
This document contains the results of deep reconnaissance performed on the Frida codebase to identify files and code locations that need modification to bypass common iOS Frida detection techniques.

## Detection Techniques & Findings

### 1. Process Name Detection
**Detection Method**: Apps scan running processes for Frida executables using sysctl or /proc

**Key Files to Modify**:
- **Primary**: `/Users/vinay/frida-project/frida/subprojects/frida-core/server/meson.build:39`
  ```meson
  server_name = 'frida-server' + exe_suffix
  ```
  **Bypass Strategy**: Change `'frida-server'` to a disguised name like `'system-service'` or `'app-helper'`

- **Additional Tools** (CI/CD References):
  - `frida-inject` - Referenced in `.github/workflows/ci.yml`
  - `frida-portal` - Referenced in `.github/workflows/ci.yml`
  - `frida-trace` - Referenced in documentation and build logs

### 2. Port Scanning Detection
**Detection Method**: Apps scan for default Frida ports using TCP port enumeration

**Key Files to Modify**:
- **Primary**: `/Users/vinay/frida-project/frida/subprojects/frida-core/lib/base/socket.vala:2`
  ```vala
  public const uint16 DEFAULT_CONTROL_PORT = 27042;
  ```
  **Bypass Strategy**: Change `27042` to a different port like `31337` or `54321`

- **Secondary**: `/Users/vinay/frida-project/frida/subprojects/frida-python/subprojects/frida-core/lib/base/socket.vala:2` (same content)

- **Related Constants**:
  ```vala
  public const uint16 DEFAULT_CLUSTER_PORT = 27052;
  ```
  Should also be changed to maintain offset (e.g., to `31347` if control port becomes `31337`)

### 3. Library Loading Detection
**Detection Method**: Apps check loaded libraries for Frida signatures in /proc/self/maps or dlopen calls

**Key Files to Modify**:
- **Primary**: `/Users/vinay/frida-project/frida/subprojects/frida-core/lib/gadget/meson.build:90-92`
  ```meson
  if host_os == 'macos'
    identity = '@executable_path/../Frameworks/FridaGadget.dylib'
  elif host_os in ['ios', 'tvos']
    identity = '@executable_path/Frameworks/FridaGadget.dylib'
  ```
  **Bypass Strategy**: Change `'FridaGadget.dylib'` to disguised names like:
  - `'SystemFramework.dylib'`
  - `'AppSupport.dylib'`
  - `'CoreServices.dylib'`

- **Agent Library**: `/Users/vinay/frida-project/frida/subprojects/frida-core/lib/agent/meson.build:67`
  ```meson
  identity = 'FridaAgent'
  ```
  **Bypass Strategy**: Change to disguised identity like `'SystemAgent'` or `'AppAgent'`

### 4. Bundle/Service Identifier Detection
**Detection Method**: Apps check for Frida bundle IDs and service names

**Key Files to Modify**:
- **Server Bundle ID**: `/Users/vinay/frida-project/frida/subprojects/frida-core/server/frida-server.plist:8`
  ```xml
  <string>re.frida.Server</string>
  ```
  **Bypass Strategy**: Change to disguised ID like `com.system.server`

- **Helper Bundle ID**: `/Users/vinay/frida-project/frida/subprojects/frida-core/src/darwin/frida-helper.plist:8`
  ```xml
  <string>re.frida.Helper</string>
  ```
  **Bypass Strategy**: Change to disguised ID like `com.system.helper`

- **Gadget App ID**: Multiple locations (droidy-host-session.vala, fruity-host-session.vala)
  ```vala
  private const string GADGET_APP_ID = "re.frida.Gadget";
  ```
  **Bypass Strategy**: Change to disguised ID like `com.system.gadget`

- **Policy Daemon**: `/Users/vinay/frida-project/frida/subprojects/frida-core/src/darwin/policyd.h:6`
  ```c
  #define FRIDA_POLICYD_SERVICE_NAME "re.frida.policyd"
  ```
  **Bypass Strategy**: Change to disguised name like `com.system.policyd`

### 5. Directory Name Detection
**Detection Method**: Apps check for Frida-specific directory structures

**Key Files to Modify**:
- **Server Directory**: `/Users/vinay/frida-project/frida/subprojects/frida-core/server/server.vala:4`
  ```vala
  private const string DEFAULT_DIRECTORY = "re.frida.server";
  ```
  **Bypass Strategy**: Change to disguised directory like `system.server.data`

### 6. DBus Interface Detection
**Detection Method**: Apps check for Frida DBus interfaces

**Key Files to Modify**:
- **Gadget Session Interface**: `/Users/vinay/frida-project/frida/subprojects/frida-core/lib/base/session.vala:752`
  ```vala
  [DBus (name = "re.frida.GadgetSession17")]
  ```
  **Bypass Strategy**: Change to disguised interface like `com.system.GadgetSession17`

## Implementation Plan

### Phase 1: Core Process & Library Bypass
1. Modify `server/meson.build` in both locations - change `frida-server` name
2. Modify `lib/gadget/meson.build` in both locations - change `FridaGadget.dylib`
3. Modify `lib/agent/meson.build` in both locations - change `FridaAgent` identity
4. Rebuild core components

### Phase 2: Network Bypass
1. Modify `lib/base/socket.vala` in both locations - change ports 27042/27052
2. Update any hardcoded port references in tools/configs
3. Test network connectivity with new ports

### Phase 3: System Integration Bypass
1. Modify plist files - change bundle identifiers
2. Modify service names - change DBus interfaces and service names
3. Modify directory names - change default directory
4. Update all cross-references

### Phase 4: Testing & Validation
1. Test that modified Frida still functions correctly
2. Verify that detection tools no longer identify the signatures
3. Test on actual iOS devices/apps
4. Validate all Frida tools work with new signatures

## Additional Considerations

### Build System Impact
- Changes to meson.build files require rebuild of affected components
- May need to clean build directories before rebuilding
- Cross-platform builds (macOS, iOS, etc.) need consistent changes

### Compatibility
- Ensure changes don't break existing Frida tools and workflows
- Consider backward compatibility for users expecting default ports/names
- Test with popular Frida tools (objection, frida-tools, etc.)

### Advanced Evasion
- Consider randomizing names/ports at build time
- Implement configuration options for custom names/ports
- Add obfuscation layers beyond simple renaming

### Detection Evasion Quality
- **Process Name**: High impact - easily detectable via process listing
- **Port Scanning**: High impact - easily detectable via network scanning
- **Library Loading**: High impact - easily detectable via memory inspection
- **Bundle IDs**: Medium impact - detectable via system enumeration
- **DBus Interfaces**: Low impact - requires deeper system inspection
- **Directory Names**: Low impact - requires file system access

## Complete Signature Coverage

✅ **Process Names**: frida-server, frida-inject, frida-portal, frida-trace
✅ **Network Ports**: 27042 (control), 27052 (cluster)
✅ **Library Names**: FridaGadget.dylib, frida-agent.dylib, FridaAgent
✅ **Bundle IDs**: re.frida.Server, re.frida.Helper, re.frida.Gadget
✅ **Service Names**: re.frida.policyd
✅ **DBus Interfaces**: re.frida.GadgetSession17
✅ **Directory Names**: re.frida.server

## Files Requiring Modification

### Core Files (High Priority)
1. `subprojects/frida-core/server/meson.build`
2. `subprojects/frida-core/lib/base/socket.vala`
3. `subprojects/frida-core/lib/gadget/meson.build`
4. `subprojects/frida-core/lib/agent/meson.build`
5. `subprojects/frida-core/server/frida-server.plist`
6. `subprojects/frida-core/src/darwin/frida-helper.plist`
7. `subprojects/frida-core/server/server.vala`
8. `subprojects/frida-core/lib/base/session.vala`
9. `subprojects/frida-core/src/darwin/policyd.h`

### Python Subproject Mirrors (Medium Priority)
1. `subprojects/frida-python/subprojects/frida-core/server/meson.build`
2. `subprojects/frida-python/subprojects/frida-core/lib/base/socket.vala`
3. `subprojects/frida-python/subprojects/frida-core/lib/gadget/meson.build`
4. `subprojects/frida-python/subprojects/frida-core/lib/agent/meson.build`
5. `subprojects/frida-python/subprojects/frida-core/server/server.vala`
6. `subprojects/frida-python/subprojects/frida-core/lib/base/session.vala`

### Additional Files (Low Priority)
- Various host-session files containing GADGET_APP_ID constants
- Build-generated files (may be auto-updated when core files change)
- **Port Scanning**: Medium impact - requires active port scanning
- **Library Name**: High impact - easily detectable in memory maps

## Files Summary
- **Process**: 2 meson.build files
- **Port**: 2 socket.vala files
- **Library**: 2 meson.build files
- **Total unique files to modify**: 4 files (with duplicates across python subproject)

## Next Steps
1. Implement changes in development environment
2. Test bypass effectiveness against known detection tools
3. Document any additional findings during implementation
4. Consider contributing changes back to Frida project (with appropriate disclaimers)