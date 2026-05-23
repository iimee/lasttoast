# Architecture

Godot scenes own presentation and node wiring. Scripts own runtime rules. Scene tree structure and node names are stable contracts and must not change unless a task explicitly requires it.

Core ownership:
- `Player/player.gd`: player movement, state, animation recovery, skills, damage, and depth integration.
- `systems/LaneSystem.gd`: legacy-named helper for depth math and ordering rules.
- `skills/Skill.gd`: base skill contract.
- `db/SkillsDB.gd`: skill loading and registration.
- `Combat/Hitboxes/`: melee, dash, and area damage contracts.
- `Combat/Projectiles/`: projectile movement, collision, spatial filtering, lifetime.

Use existing public methods and signals. Rename nothing unless every callsite is updated in the same task.
