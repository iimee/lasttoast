# agents.md

## Project
Godot 4.6 2D beat'em up with shared pseudo-depth combat space, projectiles, skills, hitboxes, knockback, hitstop, and resource-driven combat.

## Hard Rules
- Do not break the shared depth-space combat logic.
- Do not modify `Player/player.gd` unless the active task explicitly says so.
- Do not convert one-shot animations to loops.
- Preserve depth lock logic and depth-aware targeting.
- Keep diffs minimal and execution-focused.

## Workflow
1. Read exactly one task from `tasks/ready/`.
2. Read the relevant files in `docs/`.
3. Modify only the code, design, or assets required by the task.
4. Produce the requested artifact.
5. Move the task file to `tasks/review/`.
6. Add a completion note to the moved task.

## Artifact Rules
- Code artifacts must include changed paths, behavior impact, and verification notes.
- Art artifacts must land in `assets/incoming/` first, then move to `assets/final/` only after review.
- Design artifacts must define gameplay purpose, space/positioning behavior, constraints, and acceptance criteria.
- Every task must be one file with a clear output.
- Do not leave placeholder text in committed task or doc files.
