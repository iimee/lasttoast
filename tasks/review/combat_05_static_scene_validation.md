# Combat 05 Static Scene Validation

## Type
QA artifact

## Context
The first combat role pass added explicit Charger, Launcher, Welder, and combat ladder scenes. Before adding more content, validate that the new scenes and referenced runtime pieces are wired coherently enough for an editor playtest.

## References
- docs/combat.md
- docs/enemies.md
- docs/architecture.md
- tasks/review/combat_01_charger_role.md
- tasks/review/combat_02_launcher_role.md
- tasks/review/combat_03_welder_role.md
- tasks/review/combat_04_encounter_ladder.md

## Task
Perform a static validation pass on the combat role scenes and the combat ladder scene.

Check:
- New role scenes reference existing base scenes and scripts.
- The combat ladder references all three role scenes.
- Encounter names and counts match the requested ladder.
- Launcher projectile setup uses the intended target group, collision mask, fixed release depth, and no player dash-combo behavior.
- Welder active damage still routes through depth-aware hit validation.
- Any obvious stale scene signal or missing method that can affect the new role pass is identified.

## Output
Add the validation result to this task's `Completion Note` when moving it to `tasks/review/`.

If one blocking wiring bug is found, create exactly one follow-up task in `tasks/ready/` scoped to that bug.

## Do Not Change
- Player/player.gd
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings
- Role balance or encounter tuning

## Acceptance Criteria
- Static validation covers Charger, Launcher, Welder, and the combat ladder.
- Any blocker is split into one follow-up task instead of hidden inside broad cleanup.
- If no blocker is found, `tasks/ready/` ends empty.

## Completion Note
Completed static validation for the first combat role pass.

Checked:
- `hobo1_charger.tscn` references the existing rusher/base scene.
- `hobo1_launcher.tscn` references `hobo1_launcher.gd`.
- `hobo1_welder.tscn` references `hobo1_welder.gd`.
- `factory_combat_ladder.tscn` references Charger, Launcher, Welder, and contains the five requested encounter groups.
- Launcher setup configures projectile target group, player collision mask, fixed release depth, and disables dash-combo behavior.
- Welder active damage routes through inherited `_apply_attack_hits`, which uses baseline depth-aware target validation.

Result:
- Found one wiring blocker: `Combat/Projectiles/Projectile.tscn`, `Combat/Projectiles/BottleFly.tscn`, and `Combat/Projectiles/MolotovFly.tscn` connect `LifetimeTimer.timeout` to stale method `_on_lifetimetimer_timeout`, while their scripts define `_on_lifetime_timeout`.
- Created follow-up task `tasks/ready/combat_06_fix_projectile_lifetime_signal.md` scoped only to that signal-name bug.

No role balance, encounter layout, player code, depth logic, or projectile behavior values were changed in this validation task.
