# Second Pass Aftermath Levels Design

## Type
Design artifact for five short return missions.

## Shared Purpose
Second-pass missions show what remains after the catastrophe. They are shorter than first-pass levels, quieter, and built around recovery or repair. Combat is sparse and should support environmental reading, not replace it.

## Shared Rules
- Each mission is 2-3 compact zones, not a full repeated level.
- Enemy count is lower than first pass.
- Every objective uses short recoverable interactions.
- Depth-aware targeting and safe bands remain mandatory.
- Background variants use the request files under `assets/requests/*_aftermath_background.md`.

## Factory Return: Helmet
- Objective: recover Palych's helmet and close the last valve.
- Route: cooled entrance -> stopped conveyor -> helmet hook near valve.
- Object: helmet.
- Bar reward: helmet on wall; Foreman fixes the tap.
- Emotional beat: the line is silent, and the player handles one thing carefully.
- Enemy/boss: `Хозяин конвейера`.
- Boss role: slow area-control figure made from dried foam, glass, yeast, and machine leftovers.
- Spacing: center/far lanes near stopped conveyor.
- Attack range: short heavy swings and medium conveyor spurts.
- Movement pressure: dried foam lanes slow movement briefly.
- Counterplay: step to clean lane, bait swing into stuck conveyor, use valve windows.
- Background request: `assets/requests/factory_aftermath_background.md`, incoming `assets/incoming/factory_aftermath/`.

## Stadium Return: Uniform
- Objective: find the old bag/uniform under the stands.
- Route: empty gate -> silent stands -> locker alcove.
- Object: old uniform, letter, or photo from the first sports section.
- Bar reward: old uniform; Champion carries boxes and steadies the room.
- Emotional beat: applause is gone, but the body still expects judgment.
- Enemy/boss: `Комментатор`.
- Boss role: pressure and memory controller.
- Spacing: stays far/center near speakers, rarely enters close range.
- Attack range: speaker cone lanes and short microphone swing if approached.
- Movement pressure: commentary marks a lane before a crowd-memory pulse.
- Counterplay: leave marked speaker cone, attack during feedback recovery.
- Background request: `assets/requests/stadium_aftermath_background.md`, incoming `assets/incoming/stadium_aftermath/`.

## Bridge Return: Light
- Objective: restore reserve light and collect the lamp/sign part.
- Route: foggy shoulder -> broken lamp post -> service box.
- Object: light fixture or sign lamp.
- Bar reward: stable light; Engineer repairs the sign.
- Emotional beat: seeing clearly is now the work.
- Enemy/boss: `Паводок`.
- Boss role: moving mass of water, metal, headlights, and river debris.
- Spacing: sweeps along one lane at a time from bridge edge.
- Attack range: long lane push, short debris hit near impact.
- Movement pressure: pushes the player away from service box windows.
- Counterplay: read water bulge, step to a dry lane, repair during retreat.
- Background request: `assets/requests/bridge_aftermath_background.md`, incoming `assets/incoming/bridge_aftermath/`.

## Metro Return: Token
- Objective: retrieve the old token and switch on emergency light.
- Route: quiet platform -> stuck car -> service panel.
- Object: old token.
- Bar reward: token; Duty Officer starts serving orders on time.
- Emotional beat: the schedule becomes human-sized.
- Enemy/boss: `Сеть`.
- Boss role: station systems working without people.
- Spacing: appears as cable/door/speaker hazards across lanes.
- Attack range: medium cable snaps, door slam lanes, announcement pulses.
- Movement pressure: changes safe route through light sections.
- Counterplay: follow signal warnings, interrupt service panels, wait for door recovery.
- Background request: `assets/requests/metro_aftermath_background.md`, incoming `assets/incoming/metro_aftermath/`.

## Forest Return: Guitar
- Objective: recover the guitar from the dining hall and extinguish the last small fire.
- Route: wet ash path -> dining hall -> last ember.
- Object: old guitar.
- Bar reward: guitar near fireplace; Forester tends the fire.
- Emotional beat: warmth is allowed only when someone watches it.
- Enemy/boss: `Следопыт`.
- Boss role: searching figure with thermal camera and radio.
- Spacing: far lane scan, center lane approach, retreats through smoke.
- Attack range: scan-marked shot/sweep and short close shove.
- Movement pressure: marks heat lanes and calls small ember zones.
- Counterplay: break line of sight, leave scan lane, extinguish during radio recovery.
- Background request: `assets/requests/forest_aftermath_background.md`, incoming `assets/incoming/forest_aftermath/`.

## Constraints
- Do not make returns full-length remixes.
- Do not increase enemy density to first-pass levels.
- Do not use abstract horror imagery when an object, silence, or repair action can carry the beat.
- Do not modify `Player/player.gd`.

## Acceptance Criteria
- Five return missions define objective, route, object, bar reward, and emotional beat.
- Each aftermath boss/enemy defines role, spacing, attack range, movement pressure, and counterplay.
- Each mission preserves readable safe depth bands.
- Each mission links to a concrete aftermath background request and incoming path.
- Returns emphasize traces, quiet, and repair instead of repeated catastrophe spectacle.
