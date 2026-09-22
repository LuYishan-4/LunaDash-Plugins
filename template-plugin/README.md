# LunaDash SDK 2 plugin template

Copy this directory to `plugins/<your-id>/`, update runtime/store metadata, and add source.

Native `effect` plugins use `SOURCES` with `lunadash_add_plugin`. OpenGL plugins declare `shaders` in metadata and ship GLSL sources. LunaDash validates the package during CMake configuration.
