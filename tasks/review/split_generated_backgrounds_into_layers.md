# Split Generated Backgrounds Into Layers

## Type
Code/art integration artifact

## Context
Generated full-background candidates are currently placed as single flattened Sprite2D backdrops in playable scenes. Split their use into at least three visual layers per level: parallax far background, mid/background, and road/playfield layer.

## References
- `World/Factory/factory_level_1.tscn`
- `World/Stadium/stadium_level_2.tscn`
- `World/Bridge/bridge_level_3.tscn`
- `World/Metro/metro_level_4.tscn`
- `World/ForestCamp/forest_camp_level_5.tscn`
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`

## Task
Restructure generated background placement in the five main playable scenes into layered nodes. Preserve gameplay readability and keep generated images sourced from `assets/incoming/`.

## Output
Code/art integration artifact with changed paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- `assets/final/`
- Source generated PNG files

## Acceptance Criteria
- Each playable scene has at least three generated background layers: far/parallax, mid/background, and road/playfield.
- Layers are ordered behind depth bands and gameplay markers.
- Road/playfield layer does not hide actor feet or hazard reads.
- Existing generated PNG candidates remain in `assets/incoming/`.
- No files are moved to `assets/final/`.

## Completion Note
Completed.

Changed paths:
- `assets/incoming/factory/layers/factory_far_parallax_strip_01.png`
- `assets/incoming/factory/layers/factory_mid_background_strip_01.png`
- `assets/incoming/factory/layers/factory_road_playfield_strip_01.png`
- `assets/incoming/stadium/layers/stadium_far_parallax_strip_01.png`
- `assets/incoming/stadium/layers/stadium_mid_background_strip_01.png`
- `assets/incoming/stadium/layers/stadium_road_playfield_strip_01.png`
- `assets/incoming/bridge/layers/bridge_far_parallax_strip_01.png`
- `assets/incoming/bridge/layers/bridge_mid_background_strip_01.png`
- `assets/incoming/bridge/layers/bridge_road_playfield_strip_01.png`
- `assets/incoming/metro/layers/metro_far_parallax_strip_01.png`
- `assets/incoming/metro/layers/metro_mid_background_strip_01.png`
- `assets/incoming/metro/layers/metro_road_playfield_strip_01.png`
- `assets/incoming/forest_camp/layers/forest_camp_far_parallax_strip_01.png`
- `assets/incoming/forest_camp/layers/forest_camp_mid_background_strip_01.png`
- `assets/incoming/forest_camp/layers/forest_camp_road_playfield_strip_01.png`
- `World/Factory/factory_level_1.tscn`
- `World/Stadium/stadium_level_2.tscn`
- `World/Bridge/bridge_level_3.tscn`
- `World/Metro/metro_level_4.tscn`
- `World/ForestCamp/forest_camp_level_5.tscn`

Behavior impact:
- Replaced flattened generated background placement with three explicit generated layers per playable level: `FarParallaxLayer`, `MidBackgroundLayer`, and `RoadPlayfieldLayer`.
- Layer nodes remain under `Background/GeneratedBackgrounds`, ordered before depth bands and gameplay markers so combat readability and hazard reads remain above the art.
- Original generated candidate PNG files remain in `assets/incoming/`; no assets were moved to `assets/final/`.

Verification notes:
- Confirmed each level has three generated layer PNGs under `assets/incoming/<level>/layers/`.
- Confirmed scenes no longer reference the old flat `8_bg` resource.
- Follow-up parse fix: removed custom `metadata/parallax_factor` scene properties and restored blank line separation before the next background node in all five scene files.
- Rewrote the touched scene files as UTF-8 without BOM.
- Godot runtime validation was not run because no `godot` or `godot4` executable is available in PATH.
