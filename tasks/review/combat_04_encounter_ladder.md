# Combat 04 Encounter Ladder

## Type
Design / Code artifact

## Context
After the three factory roles are stable individually, the next step is a small encounter ladder that proves the combat system remains readable when enemies are combined.

## References
- docs/combat.md
- docs/enemies.md
- docs/architecture.md
- docs/factory_enemy_roles.md
- tasks/review/combat_01_charger_role.md
- tasks/review/combat_02_launcher_role.md
- tasks/review/combat_03_welder_role.md

## Task
Create or update a small combat test route or encounter sequence that validates the factory role ramp.

Encounter ladder:
- 1 Charger.
- 2 Chargers.
- 1 Charger + 1 Launcher.
- 1 Charger + 1 Welder.
- 1 Charger + 1 Launcher + 1 Welder.

Each encounter should make the player's available answer readable through depth movement, interrupt timing, recovery punish, or reload windows.

## Output
Produce the requested design/code artifact with changed paths, behavior impact, and verification notes in this task's `Completion Note` when moving it to `tasks/review/`.

## Do Not Change
- Player/player.gd
- Shared depth-space combat logic
- Depth lock logic
- Depth-aware targeting
- One-shot animation loop settings
- Boss behavior
- New level art or final level polish

## Acceptance Criteria
- The encounter ladder exists in a playable test route, factory blockout section, or clearly documented executable setup.
- Mixed encounters never cover all depth bands at once.
- The densest encounter leaves a readable route, stagger window, recovery punish, or reload punish.
- Verification notes cover each encounter in the ladder.
- Any failed role interaction is split into one follow-up task instead of being hidden inside broad tuning.

## Completion Note
Completed the first combat encounter ladder as a standalone playable test scene.

Changed paths:
- `World/Factory/factory_combat_ladder.tscn`

Behavior impact:
- Adds a focused factory combat ladder scene with a simple floor, readable far/center/near depth bands, player spawn, camera, labels, and five encounter groups.
- Encounter 01 places `1 Charger`.
- Encounter 02 places `2 Chargers` on offset start lanes.
- Encounter 03 places `1 Charger + 1 Launcher`.
- Encounter 04 places `1 Charger + 1 Welder`.
- Encounter 05 places `1 Charger + 1 Launcher + 1 Welder`, with Charger/Welder pressure on center depth and Launcher on far depth so the near lane remains a readable reset route.
- Enemy drops are disabled in this test scene to keep repeated combat checks clean.

Verification notes:
- Static verification confirmed the scene references `hobo1_charger.tscn`, `hobo1_launcher.tscn`, and `hobo1_welder.tscn`.
- Static verification confirmed all five requested encounter groups exist and are labeled in route order.
- Static verification confirmed the densest trio does not intentionally occupy every depth band at spawn; near depth is left open as the reset route while Launcher reload and Welder recovery remain punish windows.
- In-game verification was not run because no `godot`, `godot4`, or `godot_console` command is available in this shell. The next runtime check should open `res://World/Factory/factory_combat_ladder.tscn` and test each encounter in order.
