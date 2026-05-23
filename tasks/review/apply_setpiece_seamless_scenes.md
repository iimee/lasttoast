# Apply Setpiece Seamless Scenes

## Type
Scene integration artifact

## Context
The generated seamless texture pass was visually unsuccessful. Replace it with editable Godot scene geometry that can act as seamless setpiece dressing without external PNG texture dependencies.

## References
- `docs/seamless_texture_pipeline.md`
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`
- `docs/level1_factory_setpieces.md`
- `docs/level2_stadium_design.md`
- `docs/level3_bridge_design.md`
- `docs/level4_metro_design.md`
- `docs/level5_forest_camp_design.md`

## Task
Remove failed setpiece texture wiring and add seamless scene layers to every setpiece zone in the five main playable levels.

## Output
Scene integration artifact with changed paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared combat logic
- Depth lock logic
- One-shot animation loop settings
- Existing final assets

## Acceptance Criteria
- No playable scene references the failed `assets/incoming/<level>/textures/*_seamless_01.png` files.
- Every setpiece zone has one `SeamlessSceneLayers` node.
- `SeamlessSceneLayers` contains editable ColorRect scene layers for far backdrop, near backdrop, and floor/playfield washes.
- Added scene layers sit under setpiece props, enemies, player, and UI.
- Floor washes preserve pseudo-depth readability and do not alter collision or depth lock logic.

## Completion Note
Completed.

Changed paths:
- `tools/generate_setpiece_seamless_scenes.ps1`
- `assets/requests/setpiece_seamless_scene_manifest.md`
- `World/Factory/factory_level_1.tscn`
- `World/Stadium/stadium_level_2.tscn`
- `World/Bridge/bridge_level_3.tscn`
- `World/Metro/metro_level_4.tscn`
- `World/ForestCamp/forest_camp_level_5.tscn`
- `tasks/review/apply_setpiece_seamless_scenes.md`

Behavior impact:
- Replaced failed generated PNG texture wiring with scene-native `SeamlessSceneLayers` under every setpiece zone.
- Added far backdrop, near scene, floor depth wash, depth seam, and small accent ColorRect nodes per zone.
- Removed references to failed setpiece texture resources from playable scenes.
- Removed generated `*_seamless_01.png` and matching `.import` files from `assets/incoming/*/textures/`.
- Did not modify player code, combat logic, collision, depth bands, or final assets.

Verification notes:
- Confirmed all five playable scenes have matching setpiece zone counts and `SeamlessSceneLayers` counts.
- Confirmed zero `SetpieceTextureLayers`, `stx_*`, `tex_*`, or `assets/incoming/*/textures/` references remain in the five touched scenes.
- Confirmed touched scenes are UTF-8 without BOM.
- Confirmed `load_steps` matches resource counts in the five touched scenes.
- Confirmed no duplicate or missing `ExtResource` ids in the five touched scenes.
- Godot runtime validation was not run because no `godot` or `godot4` executable is available in PATH.
