# AGENTS.md — Godot 4.6 (GDScript) project rules

## Project summary
- Engine: Godot 4.6
- Language: GDScript
- Genre: 2D beat ’em up with slight depth ("lanes") + projectiles/skills.
- Key systems: Player state/animations, skills cooldowns, resources (inebriation/nicotine), projectiles, hitboxes, lane-aware targeting.

## Ground rules (do not break)
1. Do NOT change scene tree structure or node names unless explicitly requested.
2. Do NOT rename public methods/signals/exported vars used by other scripts unless you update all callsites.
3. Keep behavior identical unless the task explicitly asks to change gameplay.
4. Prefer minimal diffs. If a refactor is needed, do it in small safe steps.
5. No new dependencies or addons unless explicitly requested.

## Editing workflow
- Always start by locating relevant files and listing where changes will happen.
- When making changes, produce a clear diff-style patch and explain impact briefly.
- If you touch more than 2 files, explain why each file is needed.
- If you add new helper functions, keep them `private`-ish (prefix `_`) unless requested.

## Coding standards (GDScript)
- Godot 4.x typing: use explicit types where possible to avoid Variant warnings.
- Avoid implicit Variant inference from ProjectSettings / Dictionary access:
  - Cast to `int`, `float`, `String`, etc.
- Prefer early returns and small functions.
- Never block the main thread with long loops; use timers/await.

## Animation/state rules (critical)
- Player movement/idle must always recover after non-loop animations (hit, dash, cast).
- If an animation ends, state must fall back to locomotion unless explicitly locked.
- Any "state lock" must have:
  - a single source of truth (one boolean / enum),
  - an exit condition (timer, anim_finished, or explicit cancel),
  - a watchdog fallback (failsafe) if Godot signal isn't fired.

## Lane / depth system rules (critical)
- Lane-aware entities must not hit across lanes unless explicitly allowed.
- If a projectile has `lane_index`, it must filter targets by lane.
- Spawning should respect the user's current depth (not always lane center) when requested:
  - allow a "depth_offset" that follows player Y within lane bounds.

## Skills system rules
- Skills must:
  - respect cooldown,
  - respect resource costs (inebriation/nicotine),
  - emit skill events consistently (skill_used/skill_ready if present).
- Projectile skills:
  - spawn timing can be tied to animation events or controlled delay,
  - must not desync: projectile should not “finish animation instantly” on spawn.
- When changing timing:
  - preserve feel: avoid delaying damage so much that skill becomes unusable at close range.

## File hot spots (likely relevant)
- `player.gd` (state machine, animation, invuln, movement lock)
- `DashController.gd` (dash logic, i-frames, knockback)
- Skills under `Combat/` or `Skills/` (BottleThrowSkill, MolotovThrowSkill, SmokeRing, etc.)
- Projectiles under `Projectiles/` (BottleFly.gd, MolotovFly.gd, etc.)
- Hitboxes under `Combat/Hitboxes/` (Attack.gd etc.)

## Testing checklist after changes
1. Start scene, move, stop, idle: no stuck states.
2. Use dash repeatedly: always returns to run/idle after dash.
3. Take damage during/after dash: no permanent lockout.
4. Use each equipped skill:
   - projectile spawns at correct time,
   - projectile moves, collides, disappears correctly,
   - damage applies once where intended,
   - lane filtering works (no cross-lane hits).
5. Confirm no new warnings treated as errors (Variant inference, etc.)

## Commands (optional)
If you need a command to run tests/build, ask the user to provide:
- exact Godot executable path
- preferred run args
Do not assume a CLI path on Windows.

## What to ask vs. what to assume
- Assume engine = Godot 4.6 and GDScript unless stated otherwise.
- Ask only if required to avoid breaking behavior (e.g., which scene is main, which nodes exist).
- If unsure about node paths, use search and reference existing usage patterns in the codebase.