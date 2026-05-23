# Factory Tileset V1

## Type
Art

## Context
The factory location needs first-pass 16-bit pixel tiles for readable shared-field combat with depth.

## References
- `docs/art_style_guide.md`
- `docs/asset_pipeline.md`
- `docs/locations.md`

## Task
Generate 3 factory tiles: floor plate, cracked concrete edge, and hazard stripe trim. Place outputs in `assets/incoming/factory/`.

## Output
Three image files in `assets/incoming/factory/` plus a short note describing size and palette.

## Do Not Change
- Do not overwrite files in `assets/final/`.
- Do not add imported Godot metadata unless the asset is opened by Godot.
- Do not create unreadable noisy tiles.

## Acceptance Criteria
- Exactly 3 tile images are produced.
- Tiles use grounded 16-bit pixel art style.
- Floor readability supports shared-field combat with depth.
- Files are located under `assets/incoming/factory/`.

## Completion Note
Completed.

Changed paths:
- `assets/incoming/factory/factory_floor_plate.png`
- `assets/incoming/factory/factory_cracked_concrete_edge.png`
- `assets/incoming/factory/factory_hazard_stripe_trim.png`

Behavior impact:
- Adds first-pass factory tile candidates only; no Godot scene, script, import metadata, depth logic, or final assets changed.
- Floor and edge tiles use broad value bands and sparse cracks to preserve actor foot readability across the shared combat field.
- Hazard trim provides a readable industrial boundary/accent without defining damage or special spatial interaction.

Verification notes:
- Confirmed exactly 3 PNG files under `assets/incoming/factory/`.
- Confirmed each output is 32x32 pixels.
- Palette direction: grounded gray concrete/steel, muted concrete edge highlights, restrained yellow-black hazard contrast.
