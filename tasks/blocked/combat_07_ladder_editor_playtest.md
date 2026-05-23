# Combat 07 Ladder Editor Playtest

## Type
QA artifact

## Context
The first combat role pass is implemented and statically validated. The next step is an in-editor playtest of `res://World/Factory/factory_combat_ladder.tscn` to find the first real gameplay blocker or tuning task.

## References
- docs/combat.md
- docs/enemies.md
- docs/factory_enemy_roles.md
- tasks/review/combat_01_charger_role.md
- tasks/review/combat_02_launcher_role.md
- tasks/review/combat_03_welder_role.md
- tasks/review/combat_04_encounter_ladder.md
- tasks/review/combat_05_static_scene_validation.md
- tasks/review/combat_06_fix_projectile_lifetime_signal.md

## Task
Open `res://World/Factory/factory_combat_ladder.tscn` in Godot and play through the five encounter groups in order.

For each encounter, record:
- What worked.
- What felt unclear.
- Whether depth movement created a valid answer.
- Whether attacks recovered cleanly.
- Whether any enemy, projectile, hitbox, hurt state, or death state got stuck.

Encounter checks:
- Encounter 01: `1 Charger`.
- Encounter 02: `2 Chargers`.
- Encounter 03: `1 Charger + 1 Launcher`.
- Encounter 04: `1 Charger + 1 Welder`.
- Encounter 05: `1 Charger + 1 Launcher + 1 Welder`.

## Output
Add the playtest result to this task's `Completion Note` when moving it to `tasks/review/`.

If one critical gameplay or runtime bug blocks the ladder, create exactly one follow-up bug task in `tasks/ready/` and keep any tuning ideas in `tasks/inbox/`.

If there are no blockers, create the next small tuning or integration task in `tasks/ready/`.

## Do Not Change
- Player/player.gd
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings
- New roles, new enemies, boss behavior, or level art

## Acceptance Criteria
- All five encounter groups are tested in editor/runtime.
- The note identifies the first blocking bug, or explicitly says no blocker was found.
- Any follow-up task is one file with one clear output.
- Tuning observations are separated from blocking bugs.

## Completion Note
Blocked in this shell environment. The task requires opening `res://World/Factory/factory_combat_ladder.tscn` in Godot and playing the five encounter groups, but no usable Godot executable is available here.

Checked:
- `godot`, `godot4`, `godot_console`, `Godot_v4.6-stable_win64`, and `Godot_v4.6-stable_win64_console` are not available in PATH.
- No Godot executable was found inside the project or common local Windows folders checked from this shell.
- Opening `project.godot` through Windows file association failed with `Application not found`.

No gameplay result was produced. The next unblock step is to open the project manually in Godot, run `res://World/Factory/factory_combat_ladder.tscn`, and record the first blocking gameplay/runtime issue.
