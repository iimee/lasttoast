# Combat 03 Welder Role

## Type
Code artifact

## Context
After Charger melee and Launcher projectile pressure are stable, the third factory role is a short frontal area denial enemy. The Welder should create a readable temporary danger zone without covering all depth bands.

## References
- docs/combat.md
- docs/enemies.md
- docs/architecture.md
- docs/factory_enemy_roles.md
- tasks/review/combat_00_baseline_audit.md
- tasks/review/combat_01_charger_role.md
- tasks/review/combat_02_launcher_role.md

## Task
Build or configure the first playable Arc Welder role using existing enemy and hitbox conventions.

The Welder should:
- Hold or approach to a short-to-mid frontal range.
- Telegraph before releasing sparks.
- Damage only through a short frontal active area at valid depth.
- Leave either an open depth route or a clear recovery window.
- Retarget only after recovery, not during active frames.

## Output
Produce a code artifact with changed paths, behavior impact, and verification notes in this task's `Completion Note` when moving it to `tasks/review/`.

## Do Not Change
- Player/player.gd
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings
- Charger or Launcher behavior except for required compatibility fixes
- Boss or mixed encounter behavior

## Acceptance Criteria
- One Welder scene or variant is usable as the first factory area denial enemy.
- Startup, active window, and recovery are readable.
- Welder does not damage across all depth bands.
- Player can interrupt startup or punish recovery.
- Verification notes cover startup interrupt, active hit, off-depth safety, recovery punish, and death cleanup.

## Completion Note
Completed the first playable Arc Welder role as a focused `hobo1` variant that reuses the existing enemy runtime and `AttackArea` damage contract.

Changed paths:
- `Enemies/hobo1/hobo1_welder.gd`
- `Enemies/hobo1/hobo1_welder.tscn`

Behavior impact:
- Adds a `hobo1_welder` scene for the first factory frontal area-denial role.
- The Welder approaches to short-to-mid frontal range, locks depth during attack through the inherited baseline behavior, and uses the existing `attack` animation as startup telegraph.
- The Welder configures its inherited `AttackArea/CollisionShape2D` at runtime into a wider frontal rectangle for the spark arc while keeping depth reach narrow through `welder_attack_range_y_px = 4.0`.
- The attack has explicit telegraph, active, and recovery phases through `welder_telegraph_sec`, `welder_active_sec`, and `welder_recovery_sec`.
- The Welder does not retarget during active/recovery; it finishes the fixed attack sequence before returning to chase.

Verification notes:
- Static verification confirmed `hobo1_welder.tscn` instances `hobo1.tscn` with `hobo1_welder.gd`.
- Static verification confirmed the Welder uses inherited `_is_target_in_depth_reach` through `_apply_attack_hits`, so damage remains depth-aware.
- Static verification confirmed active damage only occurs after the telegraph timer, then the hitbox is disabled before recovery.
- Static verification confirmed hurt/death cleanup remains inherited from the audited `hobo1` baseline, with attack timers invalidated by the Welder token on damage.
- In-game verification was not run because no `godot`, `godot4`, or `godot_console` command is available in this shell. The next runtime check should confirm startup interrupt, active hit, off-depth safety, recovery punish, and death cleanup.
