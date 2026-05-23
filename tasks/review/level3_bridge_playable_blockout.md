# Level 3 Bridge Playable Blockout

## Type
Code artifact

## Context
Implement the first playable blockout pass for level 3 using `docs/level3_bridge_design.md`. Preserve the old `World/Bridge/bridge.tscn` as a reference.

## References
- `docs/level3_bridge_design.md`
- `docs/global_enemy_roster.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/enemies.md`

## Task
Create a new continuous bridge blockout scene under `World/Bridge/` with six internal zones, readable pseudo-depth lanes, placeholder bridge enemy roles, player/camera/HUD/skill menu integration, and a city return exit.

## Output
Code artifact with changed paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings
- Existing `World/Bridge/bridge.tscn`

## Acceptance Criteria
- New scene exists under `World/Bridge/` and preserves the old bridge scene.
- Route contains six named zones: approach road, first railing, truck lane, service shoulder, cracked span, central break.
- The scene has near/center/far depth bands and a long continuous floor collision.
- Placeholder enemies represent Cable Hook, Raincoat Guard, Headlight Sprinter, and Engineer.
- Scene includes player, camera, `Main`, UI labels, and skill menu integration.
- City `BRIDGE` transition loads the new playable bridge blockout.
- No changes are made to `Player/player.gd`.

## Completion Note
Changed paths:
- `World/Bridge/bridge_level_3.tscn`
- `World/main.gd`
- `tasks/review/level3_bridge_playable_blockout.md`

Behavior impact:
- Added a new continuous playable bridge blockout scene while preserving the existing `World/Bridge/bridge.tscn` reference scene.
- The route contains six named internal zones: approach road, first railing, truck lane, service shoulder, cracked span, and central break.
- Added readable near/center/far depth bands, long floor collision, bridge setpiece markers, wind/cable/headlight/crack/puddle read markers, and placeholder enemies for Cable Hook, Raincoat Guard, Headlight Sprinter, and Engineer.
- Included player, camera, `Main`, UI labels, and `SkillSelectMenu` integration matching the factory/stadium blockout pattern.
- Updated the `BRIDGE` scene transition constant in `World/main.gd` to load `res://World/Bridge/bridge_level_3.tscn`.
- Did not modify `Player/player.gd`, shared combat/depth logic, one-shot animation loop settings, or the existing `World/Bridge/bridge.tscn`.

Verification notes:
- Confirmed this was the single task read from `tasks/ready/`.
- Confirmed the new scene contains all six `Zone_0*` nodes, expected placeholder enemy role names, player, camera, skill menu, `Main`, and HUD labels by text search.
- Confirmed `World/main.gd` now points `SCENE_BRIDGE` at the new playable blockout.
- Could not run Godot headless validation because no `godot`/`godot4` executable is available in PATH in this shell.
