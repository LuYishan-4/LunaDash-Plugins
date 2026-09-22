# Plugin store security

Registry validation is not a sandbox or signature.

- Quickshell plugins execute with the desktop user's permissions.
- OpenGL plugins execute shader code in LunaDash's supported Qt Quick visual slots.
- Native effect plugins load code into the compositor process.

The store accepts source only and rejects compiled/generated packages and archives. Reviewers should pay special attention to external data access, elevated operations, process launching, data collection, and native code. Native effects must default to disabled.

Report security-sensitive problems privately through GitHub security reporting when possible.
