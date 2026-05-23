# Seamless Texture Generation Pipeline

## Purpose
Repeatable workflow for generating seamless level textures split into three readable visual layers:
- far parallax backdrop
- near background
- floor / playfield

The pipeline supports long side-scrolling beat'em up spaces without breaking pseudo-depth readability, actor foot visibility, projectile lanes, or hazard reads.

## Layer Roles

### Far Parallax Backdrop
Gameplay purpose:
- Establishes location identity and distance.
- Moves slower than the camera or repeats as a low-contrast strip.

Space / positioning behavior:
- Sits behind all playable space and mid background art.
- Uses large silhouettes and low detail.
- Avoids strong horizontal floor-like lines that could be mistaken for walkable depth bands.

Texture requirements:
- Seamless horizontally.
- Recommended base size: `512 x 144` or `1024 x 144`.
- Keep value contrast lower than the near background and floor.

### Near Background
Gameplay purpose:
- Adds readable set dressing close to the playfield without competing with combat.
- Supports route mood, hazards, and level landmarks.

Space / positioning behavior:
- Sits behind actors, hitboxes, pickups, hazards, and labels.
- May include walls, fences, props, machines, trees, stands, columns, vehicles, or tunnels.
- Must not place dark vertical props over common actor foot positions.

Texture requirements:
- Seamless horizontally.
- Recommended base size: `512 x 160` or `1024 x 160`.
- Stronger silhouettes than far parallax, but still less contrast than active actors and hazards.

### Floor / Playfield
Gameplay purpose:
- Defines the shared pseudo-depth combat space.
- Makes player, enemies, knockback, projectiles, and depth-aware targeting readable.

Space / positioning behavior:
- Anchors the lower playable area.
- Must preserve clear top-to-bottom depth bands.
- Must not hide actor feet, shadows, pickups, projectile lanes, or hazard telegraphs.

Texture requirements:
- Seamless horizontally.
- Recommended base size: `512 x 96` or `1024 x 96`.
- Use broad value grouping, not noisy micro-detail.
- Add depth-band hints through subtle value shifts, cracks, lane wear, stains, or surface direction.

## File Naming
Use this convention for generated candidates:

```text
assets/incoming/<level>/textures/<level>_far_parallax_seamless_01.png
assets/incoming/<level>/textures/<level>_near_background_seamless_01.png
assets/incoming/<level>/textures/<level>_floor_playfield_seamless_01.png
```

After review only:

```text
assets/final/<level>/textures/<level>_far_parallax_seamless.png
assets/final/<level>/textures/<level>_near_background_seamless.png
assets/final/<level>/textures/<level>_floor_playfield_seamless.png
```

## Request Workflow
1. Create one request file from `assets/requests/seamless_texture_request_template.md`.
2. Define level, layer, target size, palette, prompt, negative prompt, incoming path, and final path.
3. Generate candidates into `assets/incoming/<level>/textures/`.
4. Check horizontal tiling by repeating the candidate at least 3 times.
5. Check readability against a player/enemy silhouette sample before integration.
6. Keep accepted assets in `assets/incoming/` until review approves moving to `assets/final/`.

## Generation Prompt Pattern
Use one layer per prompt. Do not ask the generator for a full background when producing a texture layer.

```text
Grounded 16-bit pixel art seamless horizontal texture for <level location>, <layer role>, side-scrolling beat'em up, late 1990s Russian setting, limited palette, strong readable shapes, clean value grouping, tileable left and right edges, no visible seam, designed to sit <behind/under> combat actors, <layer-specific details>.
```

Negative prompt:

```text
No visible seams, no non-tileable unique center object, no modern sci-fi styling, no excessive noise, no tiny unreadable details, no foreground props hiding feet, no text, no UI, no gore, no high-contrast clutter in combat lanes.
```

## Layer-Specific Prompt Additions

Far parallax:
```text
distant large silhouettes, softened contrast, atmospheric depth, no floor markings, no high-detail foreground objects
```

Near background:
```text
medium-distance set dressing, readable landmark shapes, low clutter behind the playfield, clear separation from actor silhouettes
```

Floor / playfield:
```text
walkable beat'em up floor texture, subtle pseudo-depth bands, actor feet remain readable, broad stains and cracks, projectile lanes stay clean
```

## Review Checklist
- Left and right edges tile without a visible seam.
- Repeated texture does not create obvious mirrored or stamped artifacts.
- Layer role is clear when stacked with the other two layers.
- Floor keeps three readable pseudo-depth bands.
- Actor feet remain visible over the floor.
- Hazards, pickups, hitboxes, and projectile lanes remain readable.
- Palette follows `docs/art_style_guide.md`.
- Candidate remains in `assets/incoming/`; nothing is moved to `assets/final/` before review.

## Acceptance Criteria
- Each level texture set has exactly three requested layers: far parallax, near background, floor / playfield.
- Each generated file lands under `assets/incoming/<level>/textures/`.
- Each request defines gameplay purpose, space behavior, constraints, prompt, negative prompt, and review criteria.
- No generated texture is promoted to `assets/final/` without a review task.
- Floor textures preserve shared depth-space combat readability.
