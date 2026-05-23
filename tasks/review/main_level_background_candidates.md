# Main Level Background Candidates

## Type
Art artifact

## Context
Generate first-pass background candidates for the five main levels from `LAST_TOAST_scenario_v2.md`: factory, stadium, bridge, metro, and forest camp.

## References
- `assets/requests/factory_background.md`
- `assets/requests/stadium_background.md`
- `assets/requests/bridge_background.md`
- `assets/requests/metro_background.md`
- `assets/requests/forest_camp_background.md`
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`

## Task
Generate one background candidate per main level using the built-in image generation workflow. Save generated candidates under `assets/incoming/` only.

## Output
Art artifact with changed paths, generated paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared combat logic
- Existing final assets
- Existing imported assets

## Acceptance Criteria
- Factory candidate exists under `assets/incoming/factory/`.
- Stadium candidate exists under `assets/incoming/stadium/`.
- Bridge candidate exists under `assets/incoming/bridge/`.
- Metro candidate exists under `assets/incoming/metro/`.
- Forest camp candidate exists under `assets/incoming/forest_camp/`.
- No files are moved to `assets/final/`.
- Requests define prompt, palette, incoming path, and readability constraints.

## Completion Note
Changed paths:
- `assets/requests/factory_background.md`
- `assets/incoming/factory/factory_first_pass_bg_candidate_01.png`
- `assets/incoming/stadium/stadium_first_pass_bg_candidate_01.png`
- `assets/incoming/bridge/bridge_first_pass_bg_candidate_01.png`
- `assets/incoming/metro/metro_first_pass_bg_candidate_01.png`
- `assets/incoming/forest_camp/forest_camp_first_pass_bg_candidate_01.png`
- `tasks/review/main_level_background_candidates.md`

Behavior impact:
- Added one generated first-pass background candidate for each main level.
- Kept all generated files in `assets/incoming/` for review.
- Added the missing factory first-pass background request so all five main levels now have request documentation.
- Did not move or overwrite anything in `assets/final/`.
- Did not modify code, scenes, player logic, combat logic, or imported asset metadata.

Verification notes:
- Used built-in `image_gen` mode from the `imagegen` skill.
- Copied generated images from `C:\Users\ime\.codex\generated_images\019e040c-bc8f-7552-bd46-1414f7809f86\` into project `assets/incoming/` paths.
- Confirmed all five project candidate PNG files exist on disk after copy.
- Visual review in Godot was not run; these are incoming review candidates, not final production assets.
