# Seamless Texture Generation Pipeline

## Type
Art/tooling artifact

## Context
Levels need repeatable seamless texture generation for three stacked visual layers: parallax backdrop, near background, and floor / playfield. The floor must preserve shared pseudo-depth combat readability.

## References
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`
- `docs/task_rules.md`
- `tasks/review/background_generation_pipeline.md`
- `tasks/review/split_generated_backgrounds_into_layers.md`

## Task
Create a reusable pipeline for generating seamless level textures by layer. The pipeline must keep generated candidates in `assets/incoming/`, define layer responsibilities, and protect combat readability.

## Output
Design/artifact documentation with changed paths, behavior impact, verification notes, and acceptance criteria.

## Do Not Change
- `Player/player.gd`
- Shared combat logic
- One-shot animation loop settings
- Existing final assets
- Existing generated candidates

## Acceptance Criteria
- Adds a reusable seamless texture pipeline under `docs/`.
- Adds a reusable request template under `assets/requests/`.
- Defines gameplay purpose, space/positioning behavior, constraints, and acceptance criteria.
- Covers exactly three layers: far parallax backdrop, near background, and floor / playfield.
- Keeps generated candidates under `assets/incoming/`.
- Does not move anything to `assets/final/`.

## Completion Note
Completed.

Changed paths:
- `docs/seamless_texture_pipeline.md`
- `assets/requests/seamless_texture_request_template.md`
- `tasks/review/seamless_texture_generation_pipeline.md`

Behavior impact:
- Added a repeatable generation pipeline for seamless level textures split into far parallax, near background, and floor / playfield layers.
- Added a reusable request template that requires gameplay purpose, positioning behavior, canvas size, incoming/final paths, prompt, negative prompt, constraints, and review criteria.
- No code, scenes, combat logic, player files, existing generated images, or final assets were changed.

Verification notes:
- `tasks/ready/` was empty, so no ready task could be moved forward.
- Read `docs/art_style_guide.md`, `docs/asset_pipeline.md`, `docs/task_rules.md`, and relevant existing review artifacts before adding the pipeline.
- Confirmed the new pipeline keeps candidates in `assets/incoming/` and reserves `assets/final/` for post-review promotion.
