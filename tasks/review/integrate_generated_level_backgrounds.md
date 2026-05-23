# Integrate Generated Level Backgrounds

## Type
Code/art integration artifact

## Context
Generated first-pass background candidates exist under `assets/incoming/` for the five main levels. Integrate them into the playable level scenes as background texture references while preserving blockout readability.

## References
- `assets/incoming/factory/factory_first_pass_bg_candidate_01.png`
- `assets/incoming/stadium/stadium_first_pass_bg_candidate_01.png`
- `assets/incoming/bridge/bridge_first_pass_bg_candidate_01.png`
- `assets/incoming/metro/metro_first_pass_bg_candidate_01.png`
- `assets/incoming/forest_camp/forest_camp_first_pass_bg_candidate_01.png`
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`

## Task
Add the generated background candidates to the playable scenes for factory, stadium, bridge, metro, and forest camp. Keep depth bands, collision, route labels, hazard reads, and enemies readable.

## Output
Code/art integration artifact with changed paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- `assets/final/`

## Acceptance Criteria
- Factory playable scene references the factory background candidate.
- Stadium playable scene references the stadium background candidate.
- Bridge playable scene references the bridge background candidate.
- Metro playable scene references the metro background candidate.
- Forest camp playable scene references the forest camp background candidate.
- Backgrounds are visually behind gameplay/readability overlays.
- No files are moved to `assets/final/`.

## Completion Note
Changed paths:
- `World/Factory/factory_level_1.tscn`
- `World/Stadium/stadium_level_2.tscn`
- `World/Bridge/bridge_level_3.tscn`
- `World/Metro/metro_level_4.tscn`
- `World/ForestCamp/forest_camp_level_5.tscn`
- `tasks/review/integrate_generated_level_backgrounds.md`

Behavior impact:
- Integrated generated background candidates into all five playable main-level scenes.
- Added `Texture2D` ext_resource references to each incoming PNG.
- Added repeated `GeneratedBackgrounds` Sprite2D backdrops across each long route so the images cover the playable blockout length.
- Kept depth bands, collision, route labels, hazard read markers, player, enemies, and UI layers above the background images.
- Left all assets in `assets/incoming/`; no files were moved to `assets/final/`.
- Did not modify `Player/player.gd`, shared combat/depth logic, or one-shot animation loop settings.

Verification notes:
- Confirmed this was the single task read from `tasks/ready/`.
- Confirmed each scene references its matching `assets/incoming/..._candidate_01.png` path by text search.
- Confirmed each scene contains `GeneratedBackgrounds` and repeated `Bg` Sprite2D nodes.
- Confirmed all five source PNG files exist on disk.
- Could not run Godot headless validation because no `godot`/`godot4` executable is available in PATH in this shell.
