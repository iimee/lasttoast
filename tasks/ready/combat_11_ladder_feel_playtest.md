# Combat 11 Ladder Feel Playtest

## Type
QA artifact

## Context
The factory combat ladder has the first playable `Charger / Launcher / Welder` role set and synchronized closer enemy spacing. The next step is a manual Godot playtest focused on combat feel and readability, not new content or broad tuning.

## References
- docs/combat.md
- docs/enemies.md
- docs/factory_enemy_roles.md
- tasks/review/combat_01_charger_role.md
- tasks/review/combat_02_launcher_role.md
- tasks/review/combat_03_welder_role.md
- tasks/review/combat_04_encounter_ladder.md
- tasks/review/combat_10_sync_ladder_spacing.md

## Task
Open `res://World/Factory/factory_combat_ladder.tscn` in Godot and play through the five encounter groups in order:
- `1 Charger`
- `2 Chargers`
- `1 Charger + 1 Launcher`
- `1 Charger + 1 Welder`
- `1 Charger + 1 Launcher + 1 Welder`

For each encounter, record:
- Distance to first meaningful contact.
- Whether the enemy attack read is clear before damage.
- Whether depth movement creates a reliable answer.
- Whether there is a punish, reload, or recovery window.
- Whether enemies crowd, overlap, or block each other's readability.
- Whether any enemy, projectile, hitbox, hurt state, death state, or depth lock gets stuck.

## Output
Add the playtest result to this task's `Completion Note` when moving it to `tasks/review/`.

If a runtime bug appears, create exactly one bug task in `tasks/ready/` and postpone tuning.

If no runtime bug appears, create exactly one tuning task in `tasks/ready/`:
- `combat_12_tune_charger_feel.md` if Charger is too sticky, too fast, unclear, or attacks too often.
- `combat_12_tune_launcher_feel.md` if Launcher is unclear, fires too often, or its projectile is too hard to avoid by depth.
- `combat_12_tune_welder_feel.md` if Welder arc is unclear, too wide, too fast, or recovery is too short.

Put lower-priority observations in `tasks/inbox/` as future tasks instead of mixing them into the selected next task.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings
- New roles, new enemies, boss behavior, or level art
- More than one tuning target at once

## Acceptance Criteria
- All five encounter groups are tested in editor/runtime.
- The completion note identifies either the first runtime blocker or the highest-priority feel issue.
- One and only one follow-up task is created in `tasks/ready/`.
- The follow-up task has one clear output.

## Completion Note
