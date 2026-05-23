# Seamless Texture Request Template

## Source Task

## Level

## Layer
Choose one:
- Far parallax backdrop
- Near background
- Floor / playfield

## Gameplay Purpose

## Space / Positioning Behavior

## Target File Family

## Incoming Path
`assets/incoming/<level>/textures/`

## Final Path After Review
`assets/final/<level>/textures/`

## Canvas Size
Recommended:
- Far parallax: `512 x 144` or `1024 x 144`
- Near background: `512 x 160` or `1024 x 160`
- Floor / playfield: `512 x 96` or `1024 x 96`

## Seam Direction
Horizontal seamless tiling. Left and right edges must connect cleanly.

## Style
Grounded 16-bit pixel art with readable silhouettes and limited value noise.

## Palette

## Constraints
- Keep combat actors readable.
- Do not hide actor feet.
- Preserve pseudo-depth floor readability.
- Avoid high-contrast clutter in projectile and hazard lanes.
- Keep candidates in `assets/incoming/` until review.

## Prompt

## Negative Prompt
No visible seams, no non-tileable unique center object, no excessive pixel noise, no foreground props hiding feet, no text, no UI, no gore, no high-contrast clutter in combat lanes.

## Review Criteria
- Tiles horizontally with no visible seam.
- Repeats three times without obvious stamps or mirrored artifacts.
- Matches the requested layer role.
- Preserves gameplay readability.
- Uses the expected incoming path.
