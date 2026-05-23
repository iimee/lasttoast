# Combat 00 Baseline Audit

## Type
Design / QA artifact

## Context
The project already has the player, skills, hitboxes, projectiles, depth helpers, and basic `hobo1` enemy variants. Before adding more combat roles or mixed encounters, the current baseline enemy contract needs to be checked as one small, executable step.

## References
- docs/project_overview.md
- docs/gameplay_core.md
- docs/combat.md
- docs/enemies.md
- docs/architecture.md
- docs/factory_enemy_roles.md

## Task
Audit the current `hobo1` baseline combat behavior as the reference enemy contract. Inspect the relevant enemy, hitbox, projectile, and depth files, then verify the behavior in-game if possible.

Check:
- Enemy approaches the player and enters chase cleanly.
- Enemy aligns to the player's depth before melee damage can apply.
- Enemy melee cannot damage the player from an invalid depth.
- Player melee can damage the enemy when spatially valid.
- Player skills/projectiles respect valid target depth.
- Enemy enters and exits `HURT` cleanly.
- Enemy attack state exits cleanly after hit, miss, or animation end.
- Enemy death disables active damage and does not leave a stuck combat state.

## Output
Add the audit result to this task's `Completion Note` when moving it to `tasks/review/`.

If a critical contract bug is found, create exactly one follow-up bug task in `tasks/ready/` and leave the role tasks in `tasks/inbox/`.

If no critical contract bug blocks role work, move `tasks/inbox/combat_01_charger_role.md` to `tasks/ready/`.

## Do Not Change
- Player/player.gd
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings
- Factory role balance or new enemy role implementation

## Acceptance Criteria
- The audit identifies whether the baseline enemy contract is stable enough for role work.
- Each failed scenario is described with the observed behavior, likely owner file, and why it blocks or does not block the next task.
- Any created follow-up task is scoped to one bug only.
- No code, scene, animation, or asset changes are made during this audit unless a separate ready task explicitly scopes them.

## Completion Note
Completed baseline combat audit as a static code and scene contract pass. Inspected `Enemies/hobo1/hobo1.gd`, `Enemies/hobo1/hobo1.tscn`, `Enemies/hobo1/hobo1_rusher.tscn`, `Enemies/hobo1/hobo1_bruiser.tscn`, `Combat/Hitboxes/Attack.gd`, `Combat/Projectiles/Projectile.gd`, `Combat/Projectiles/BottleFly.gd`, `Combat/Projectiles/MolotovFly.gd`, and the relevant depth API in `Player/player.gd`.

Result: no critical baseline contract bug was found that blocks the Charger role task. The current baseline has chase entry through sight detection, depth follow during chase, depth lock during `ATTACK` and `HURT`, enemy melee depth checks through `_is_target_in_depth_reach`, player melee depth checks through `Attack.gd`, projectile depth checks through each projectile's stored `depth_y`, hurt recovery through the one-shot `hurt_stun` timer plus `_physics_process`, attack exit through range/depth loss, hit application, or animation finish, and death cleanup that disables collision/sight/attack monitoring.

Verification was limited to static inspection because no `godot`, `godot4`, or `godot_console` command was available in this shell. The next task should still perform in-game checks for same-depth hit, off-depth miss, hurt recovery, and death cleanup while implementing the Charger.
