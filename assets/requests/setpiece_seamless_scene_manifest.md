# Setpiece Seamless Scene Manifest

Generated from `tools/generate_setpiece_seamless_scenes.ps1`.

This replaces the failed generated PNG texture pass with editable Godot scene primitives.

Rules:
- Each setpiece gets one `SeamlessSceneLayers` node.
- Layers are ColorRect scene geometry, not external seamless PNG textures.
- Nodes sit at `z_index = -2` under setpiece props, enemies, player, and UI.
- Floor washes preserve broad pseudo-depth bands and avoid actor-foot clutter.
- No assets are promoted to `assets/final/`.