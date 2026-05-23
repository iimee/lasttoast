# Apply Setpiece Seamless Textures

## Type
Art/tooling and scene integration artifact

## Context
All playable main levels need seamless texture candidates per setpiece, split into the pipeline layers:
- far parallax backdrop
- near background
- floor / playfield

The textures must be applied to levels without touching player code, combat logic, collision, depth locks, or one-shot animation settings.

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
Generate seamless texture candidates for every setpiece zone in the five main playable levels and wire those texture layers into the matching scenes.

## Output
Code/art integration artifact with changed paths, behavior impact, verification notes, and generated asset summary.

## Do Not Change
- `Player/player.gd`
- Shared combat logic
- Depth lock logic
- One-shot animation loop settings
- Existing final assets

## Acceptance Criteria
- Every setpiece in the five main playable levels has three texture candidates: far, near, and floor.
- Texture candidates land under `assets/incoming/<level>/textures/`.
- Scenes reference the generated candidates through low-alpha Sprite2D layer nodes.
- Added scene texture layers sit under enemies/player and do not change floor collision or depth-band nodes.
- No assets are moved to `assets/final/`.

## Completion Note
Superseded by `tasks/review/apply_setpiece_seamless_scenes.md`.

Changed paths:
- `tools/generate_setpiece_seamless_textures.ps1`
- `assets/requests/setpiece_seamless_texture_manifest.md`
- `assets/incoming/factory/textures/`
- `assets/incoming/stadium/textures/`
- `assets/incoming/bridge/textures/`
- `assets/incoming/metro/textures/`
- `assets/incoming/forest_camp/textures/`
- `World/Factory/factory_level_1.tscn`
- `World/Stadium/stadium_level_2.tscn`
- `World/Bridge/bridge_level_3.tscn`
- `World/Metro/metro_level_4.tscn`
- `World/ForestCamp/forest_camp_level_5.tscn`
- `tasks/review/apply_setpiece_seamless_textures.md`

Behavior impact:
- The generated PNG texture pass was rejected visually and removed from scene wiring.
- The follow-up scene-native pass now lives in `tasks/review/apply_setpiece_seamless_scenes.md`.

Generated asset summary:
- Factory: 8 zones, 24 textures.
- Stadium: 6 zones, 18 textures.
- Bridge: 6 zones, 18 textures.
- Metro: 7 zones, 21 textures.
- Forest camp: 7 zones, 21 textures.

Verification notes:
- `tasks/ready/` was empty, so no ready task could be moved.
- Superseded texture wiring was removed by the seamless scene pass.
- No generated texture candidates were moved to `assets/final/`.
