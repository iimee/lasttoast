# Level 1 Factory Route Expansion

## Type
Code artifact

## Context
The current level 1 factory blockout is too short: one screen per setpiece does not support the intended feeling of a full factory route. Expand it into one continuous level with multiple internal zones, approaches, combat beats, and rests.

## References
- `docs/level1_factory_setpieces.md`
- `docs/locations.md`
- `docs/gameplay_core.md`
- `docs/combat.md`
- `docs/factory_enemy_roles.md`

## Task
Lengthen `World/Factory/factory_level_1.tscn` so setpieces are not single-screen rooms. Keep it as one level scene made of internal route zones and beats.

## Output
Code artifact with changed paths, behavior impact, and verification notes.

## Do Not Change
- `Player/player.gd`
- Shared depth-space combat logic
- One-shot animation loop settings

## Acceptance Criteria
- Factory level remains one continuous scene, not separate scenes per setpiece.
- The route contains 8 named internal zones based on the level 1 factory rhythm.
- Each major setpiece has room for approach, mechanic read, combat pressure, and exit/rest.
- Camera and floor bounds support the longer route.
- Depth bands remain readable across the whole route.

## Completion Note
Changed paths:
- `World/Factory/factory_level_1.tscn`
- `tasks/review/level1_factory_route_expansion.md`

Behavior impact:
- Expanded the factory from a short blockout into one continuous level route about 12k px wide.
- Added 8 internal zones: gate, conveyor, first valve, welding, warehouse, freight lift, machine hall, and reservoir.
- Each major setpiece now has space for approach/read, combat pressure, and exit/rest instead of being one screen.
- Extended floor collision, background bands, depth bands, and camera bounds to support the longer route.
- Kept the factory as one scene and did not split setpieces into separate levels.
- Did not modify `Player/player.gd`, shared combat/depth logic, or one-shot animation loop settings.

Verification notes:
- Confirmed `World/Factory/factory_level_1.tscn` contains exactly 8 `Zone_0*` nodes.
- Confirmed player, camera, `Main`, skill menu, long camera bounds, and role placeholder enemy nodes are present.
- Confirmed referenced player, UI, and enemy scenes exist on disk.
- Could not run Godot headless validation because no `godot`/`godot4` executable is available in PATH in this shell.
