# Factory Enemy Roles

## Type
Design

## Context
Factory encounters need enemy roles that pressure the player without breaking shared-field combat readability.

## References
- `docs/enemies.md`
- `docs/combat.md`
- `docs/gameplay_core.md`
- `docs/locations.md`

## Task
Define 3 factory enemy roles with space behavior, attack pattern, counterplay, and escalation use.

## Output
Design document in `docs/` or a completed task artifact attached to this task.

## Do Not Change
- Do not edit enemy code.
- Do not change player movement.
- Do not define attacks that ignore spatial readability without explicit limits.

## Acceptance Criteria
- 3 roles are defined.
- Each role has space behavior.
- Each role has attack range and counterplay.
- Roles can combine into readable factory encounters.

## Completion Note
Completed.

Changed paths:
- `docs/factory_enemy_roles.md`
- `tasks/review/factory_enemy_roles.md`

Behavior impact:
- Adds a factory enemy role design artifact only; no code, player movement, depth logic, or combat runtime behavior changed.
- Defines three complementary enemy roles with space behavior, attack range, counterplay, and encounter escalation guidance.
- Preserves shared-field combat readability by keeping attacks narrow and explicit, with only one tightly limited spark side-splash edge case on the Arc Welder.

Verification notes:
- Confirmed all three roles are documented with gameplay purpose, space behavior, attack pattern, attack range, counterplay, and escalation use.
- Confirmed the design fits one shared combat field and explicitly limits any side-splash threat.
- Confirmed the role set can combine into readable factory encounters through the included encounter pairing guidance.
