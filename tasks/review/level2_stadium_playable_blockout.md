# Level 2 Stadium Playable Blockout

## Type
Code artifact

## Context
Implement the first playable blockout pass for level 2 using `docs/level2_stadium_design.md`. The old `World/Stadium/stadium.tscn` exists and should be preserved as a reference.

## References
- `docs/level2_stadium_design.md`
- `docs/global_enemy_roster.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/enemies.md`

## Task
Create a new continuous stadium blockout scene under `World/Stadium/` with six internal zones, readable pseudo-depth lanes, placeholder enemy roles, player/camera/HUD/skill menu integration, and a city return exit.

## Output
Code artifact with changed paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- Existing `World/Stadium/stadium.tscn`

## Acceptance Criteria
- New scene exists under `World/Stadium/` and preserves the old stadium scene.
- Route contains six named zones: gate, turnstiles, lower corridor, stands, field edge, center event area.
- The scene has near/center/far depth bands and a long continuous floor collision.
- Placeholder enemies represent Turnstile Shovers, Bottle Throwers, Flag Runners, and Champion.
- Scene includes player, camera, `Main`, UI labels, and skill menu integration.
- City `STADIUM` transition loads the new playable stadium blockout.
- No changes are made to `Player/player.gd`.

## Completion Note
Changed paths:
- `World/Stadium/stadium_level_2.tscn`
- `World/main.gd`
- `tasks/review/level2_stadium_playable_blockout.md`

Behavior impact:
- Added a new continuous playable stadium blockout scene while preserving the existing `World/Stadium/stadium.tscn` reference scene.
- The route contains six named internal zones: gate, turnstiles, lower corridor, stands, field edge, and center event area.
- Added readable near/center/far depth bands, long floor collision, stadium setpiece markers, crowd/floodlight/bottle/shockwave read markers, and placeholder enemies for Turnstile Shovers, Bottle Throwers, Flag Runners, and Champion.
- Included player, camera, `Main`, UI labels, and `SkillSelectMenu` integration matching the existing factory blockout pattern.
- Updated the `STADIUM` scene transition constant in `World/main.gd` to load `res://World/Stadium/stadium_level_2.tscn`.
- Did not modify `Player/player.gd`, shared combat/depth logic, one-shot animation loop settings, or the existing `World/Stadium/stadium.tscn`.

Verification notes:
- Confirmed this was the single task read from `tasks/ready/`.
- Confirmed the new scene contains all six `Zone_0*` nodes, expected placeholder enemy role names, player, camera, skill menu, `Main`, and HUD labels by text search.
- Confirmed `World/main.gd` now points `SCENE_STADIUM` at the new playable blockout.
- Could not run Godot headless validation because no `godot`/`godot4` executable is available in PATH in this shell.
