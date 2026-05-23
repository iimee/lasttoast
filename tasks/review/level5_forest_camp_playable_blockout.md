# Level 5 Forest Camp Playable Blockout

## Type
Code artifact

## Context
Implement the first playable blockout pass for level 5 using `docs/level5_forest_camp_design.md`.

## References
- `docs/level5_forest_camp_design.md`
- `docs/global_enemy_roster.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/enemies.md`

## Task
Create a new continuous forest camp blockout scene under `World/ForestCamp/` with seven internal zones, readable pseudo-depth lanes, placeholder forest enemy roles, player/camera/HUD/skill menu integration, and city transition support.

## Output
Code artifact with changed paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- Existing level scenes

## Acceptance Criteria
- New scene exists under `World/ForestCamp/`.
- Route contains seven named zones: road edge, first cabins, dining hall, sports ground, pump shed, roof/beam hazard, fireline finale.
- The scene has near/center/far depth bands and a long continuous floor collision.
- Placeholder enemies represent Ash Runner, Ember Carrier, Wet Plank Brute, and Forester.
- Scene includes player, camera, `Main`, UI labels, and skill menu integration.
- City contains a `FOREST` transition that loads the new playable forest camp blockout, and forest camp can return to city.
- No changes are made to `Player/player.gd`.

## Completion Note
Changed paths:
- `World/ForestCamp/forest_camp_level_5.tscn`
- `World/main.gd`
- `tasks/review/level5_forest_camp_playable_blockout.md`

Behavior impact:
- Added a new continuous playable forest camp blockout scene.
- The route contains seven named internal zones: road edge, first cabins, dining hall, sports ground, pump shed, roof/beam hazard, and fireline finale.
- Added readable near/center/far depth bands, long floor collision, forest camp setpiece markers, ash/smoke/fire/pump/beam/fireline read markers, and placeholder enemies for Ash Runner, Ember Carrier, Wet Plank Brute, and Forester.
- Included player, camera, `Main`, UI labels, and `SkillSelectMenu` integration matching the existing blockout pattern.
- Added `SCENE_FOREST_CAMP`, a city `FOREST` transition, and a forest camp return-to-city transition in `World/main.gd`.
- Did not modify `Player/player.gd`, shared combat/depth logic, or one-shot animation loop settings.

Verification notes:
- Confirmed this was the single task read from `tasks/ready/`.
- Confirmed the new scene contains all seven `Zone_0*` nodes, expected placeholder enemy role names, player, camera, skill menu, `Main`, and HUD labels by text search.
- Confirmed `World/main.gd` contains `SCENE_FOREST_CAMP`, `ExitToForestCamp`, and forest camp return handling.
- Could not run Godot headless validation because no `godot`/`godot4` executable is available in PATH in this shell.
