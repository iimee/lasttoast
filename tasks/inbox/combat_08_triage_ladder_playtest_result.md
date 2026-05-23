# Combat 08 Triage Ladder Playtest Result

## Type
Design / QA artifact

## Context
`combat_07_ladder_editor_playtest.md` is blocked in the agent shell because Godot is not available. After the ladder is manually tested in Godot, the result needs to be converted into exactly one next actionable combat task.

## References
- docs/combat.md
- docs/enemies.md
- docs/factory_enemy_roles.md
- tasks/blocked/combat_07_ladder_editor_playtest.md
- tasks/review/combat_01_charger_role.md
- tasks/review/combat_02_launcher_role.md
- tasks/review/combat_03_welder_role.md
- tasks/review/combat_04_encounter_ladder.md

## Task
Read the manual playtest notes for `res://World/Factory/factory_combat_ladder.tscn` and choose the first next task.

Priority order:
1. Runtime crash or script error.
2. Stuck state: attack, hurt, death, projectile, hitbox, or depth lock.
3. Invalid depth hit or invalid depth miss.
4. Unreadable role behavior.
5. Tuning issue.

## Output
Create exactly one follow-up task in `tasks/ready/`.

If there are multiple issues, put lower-priority observations in `tasks/inbox/` as separate future tasks.

## Do Not Change
- Player/player.gd unless the selected follow-up task explicitly requires it
- Shared depth-space combat logic unless the selected follow-up task explicitly requires it
- One-shot animation loop settings
- Multiple roles at once

## Acceptance Criteria
- One next `tasks/ready/` file exists.
- The task has one clear output.
- Any extra observations are not mixed into the selected task.

## Completion Note

