# Global Enemy Roster Expansion

## Type
Design artifact for level and encounter implementation.

## Shared Rules
- Every attack must respect actual overlap in the shared pseudo-depth combat field.
- No enemy may cover all depth bands alone.
- Ranged attacks must show lane, startup, travel, and impact.
- Area control must always leave at least one readable escape band or timing window.
- Reuse existing placeholder humanoid enemy scenes for first pass if art is not ready.
- Do not require changes to `Player/player.gd`.

## Factory Roles

### Rivet Charger
- Combat role: frontline same-depth bruiser and early pressure anchor.
- Preferred spacing and depth behavior: walks into close range, realigns to the player's depth band, then commits to a short frontal burst or wrench swing.
- Attack range: close range with a narrow forward extension.
- Movement pressure: pushes the player away from comfortable centerline positions and toward factory hazards or support enemies.
- Counterplay: shift depth during startup, bait the committed burst, punish recovery, or poke before melee range.
- Readability: heavy planted windup, short burst, visible miss recovery.
- Minimum animation needs: idle, walk, align/plant, windup, burst or swing, recovery, hit, fall.
- Placeholder reuse: existing bruiser or rusher body with rivet gun, wrench, or heavy work-glove prop.

### Arc Welder
- Combat role: frontal area denial and valve/control guard.
- Preferred spacing and depth behavior: holds a patch of floor, retargets after recovery, and controls only a narrow frontal slice.
- Attack range: short to mid frontal cone, with optional tiny point-blank side spark.
- Movement pressure: makes the player leave a held line and approach from a safer depth or timing window.
- Counterplay: interrupt charge, rotate around the cone, or punish after sparks end.
- Readability: welding mask/torch lift, spark charge, clear cone release, recovery pause.
- Minimum animation needs: idle, walk/reposition, torch charge, spark release, recovery, interrupted, hit, fall.
- Placeholder reuse: static or poker body with welder mask and spark VFX.

### Belt Launcher
- Combat role: backline lane projectile and anti-passive pressure.
- Preferred spacing and depth behavior: keeps clean firing space behind melee enemies and fires along its current depth line.
- Attack range: medium to long fixed-line projectile.
- Movement pressure: forces depth shifts and target-priority decisions behind frontline pressure.
- Counterplay: step off the firing line after the tell, close during reload, or interrupt setup.
- Readability: raised launcher pose, visible projectile spawn, fixed travel lane, impact cue.
- Minimum animation needs: idle, walk/reposition, aim, fire, reload, interrupted, hit, fall.
- Placeholder reuse: ranged body with conveyor scrap, crate shard, or bolt bundle projectile.

### Chief Technologist
- Combat role: Level 1 boss, heavy line-holder, and factory process defender.
- Preferred spacing and depth behavior: holds the reservoir arena center, moves deliberately between the control panel and manual valve, and realigns before each frontal strike.
- Attack range: short heavy swings, medium same-lane pressure bursts, and scripted control interactions that alter steam timing.
- Movement pressure: forces the player to choose between damaging the boss, stopping the line, and crossing depth bands safely.
- Counterplay: dodge same-lane heavy attacks, punish long recovery, interrupt restart attempts, and use safe steam windows to reach controls.
- Readability: large body plant before swings, visible panel/valve intent, pressure gauge or alarm cue before arena changes.
- Minimum animation needs: idle, walk, heavy windup, heavy strike, recovery, panel reach, valve reach, stagger, phase transition, defeat.
- Placeholder reuse: heavy bruiser body with foreman/technologist coat, clipboard/tool prop, and reservoir control VFX.

## Stadium Roles

### Turnstile Shover
- Combat role: close blocker and crowd-pressure body.
- Preferred spacing and depth behavior: holds one lane near gates or railings; sidesteps only after the player changes depth.
- Attack range: short shove in the same depth band.
- Movement pressure: pushes the player sideways along X, trying to pin them toward crowd barriers.
- Counterplay: step to another depth band during startup or punish recovery after the shove.
- Readability: raises shoulder and plants feet before pushing; no invisible wall extension.
- Minimum animation needs: idle, walk, shove startup, shove impact, recovery, hit, fall.
- Placeholder reuse: existing hobo/bruiser body can stand in with a turnstile marker prop.

### Bottle Thrower
- Combat role: ranged lane denial.
- Preferred spacing and depth behavior: stays behind blockers on far or center lane and retreats before throwing.
- Attack range: medium to long arcing bottle.
- Movement pressure: forces the player to move out of marked landing circles.
- Counterplay: close distance, dodge before impact, or use enemies/props as interruption pressure.
- Readability: bottle arc shadow and landing mark appear before impact.
- Minimum animation needs: windup, throw, bottle travel, shatter, recovery.
- Placeholder reuse: existing ranged enemy body plus bottle projectile placeholder.

### Flag Runner
- Combat role: fast flanker.
- Preferred spacing and depth behavior: moves diagonally between lanes, then commits to a straight attack lane.
- Attack range: short shoulder/flagpole swipe.
- Movement pressure: interrupts passive backpedaling and tests depth tracking.
- Counterplay: wait for lane commit, sidestep, punish long recovery.
- Readability: flag cloth trail shows the chosen lane; no teleporting.
- Minimum animation needs: run, lane change, swipe, miss recovery, hit, fall.
- Placeholder reuse: light hobo/flanker body with flag prop.

## Bridge Roles

### Cable Hook
- Combat role: mid-range pull and spacing disruptor.
- Preferred spacing and depth behavior: aligns on the same depth band before throwing a cable hook.
- Attack range: medium straight hook line.
- Movement pressure: threatens players who stand still at mid-range.
- Counterplay: change depth during startup, attack during cable recovery, or bait hook into railing.
- Readability: cable glints and line preview appear before the hook becomes active.
- Minimum animation needs: windup, hook throw, pull, cable retract, recovery.
- Placeholder reuse: existing poker/ranged body with cable line effect.

### Raincoat Guard
- Combat role: shielded lane anchor.
- Preferred spacing and depth behavior: holds near railings and advances slowly on one band.
- Attack range: short baton or shield bump.
- Movement pressure: narrows safe space but cannot lock all lanes.
- Counterplay: attack from another depth band, wait for shield bump recovery, or use hazards to make them reposition.
- Readability: shield direction must match the protected lane.
- Minimum animation needs: guard, advance, bump, exposed recovery, hit, fall.
- Placeholder reuse: bruiser body with raincoat color swap.

### Headlight Sprinter
- Combat role: telegraphed straight-line rush.
- Preferred spacing and depth behavior: waits off to one side, then rushes on a fixed depth line.
- Attack range: long linear rush on one lane.
- Movement pressure: punishes standing in headlight paths.
- Counterplay: leave the lit lane before the rush or punish the long stop animation.
- Readability: headlights/reflection sweep marks the exact lane before movement.
- Minimum animation needs: crouch, rush, skid stop, recovery, hit, fall.
- Placeholder reuse: rusher body with headlight overlay.

## Metro Roles

### Token Clerk
- Combat role: ranged marker and rhythm control.
- Preferred spacing and depth behavior: keeps medium distance near turnstiles or booth zones.
- Attack range: medium token projectile along one lane.
- Movement pressure: marks a lane and forces movement before the token bounces or lands.
- Counterplay: change depth, interrupt windup, or approach after token throw.
- Readability: coin/token glint and straight lane preview.
- Minimum animation needs: windup, flick throw, projectile, recovery, hit, fall.
- Placeholder reuse: ranged body with token projectile.

### Tunnel Dragger
- Combat role: slow close threat from darkness.
- Preferred spacing and depth behavior: enters from tunnel edges and stays on the lane it emerged from until recovery.
- Attack range: short grab or dragging swing.
- Movement pressure: forces the player away from platform edge/tunnel mouth.
- Counterplay: watch emergence shadow, sidestep, punish slow recovery.
- Readability: silhouette appears before active frames; no instant grab from darkness.
- Minimum animation needs: emerge, drag step, grab, miss, recovery, hit, fall.
- Placeholder reuse: heavy body with dark palette.

### Signal Worker
- Combat role: support and hazard scheduler.
- Preferred spacing and depth behavior: avoids direct brawling and moves toward signal boxes.
- Attack range: short tool strike only if cornered.
- Movement pressure: changes light states, opens door/wind/spark windows.
- Counterplay: interrupt signal interaction or fight around the active warning lane.
- Readability: signal box flashes before hazards activate.
- Minimum animation needs: run, interact, tool swing, interrupted, hit, fall.
- Placeholder reuse: static worker body with signal panel prop.

## Forest Camp Roles

### Ash Runner
- Combat role: evasive skirmisher.
- Preferred spacing and depth behavior: crosses smoke pockets but must reveal before attacking.
- Attack range: short slash or shove.
- Movement pressure: punishes tunnel vision and forces the player to track silhouettes.
- Counterplay: wait for reveal, move out of the committed lane, punish after miss.
- Readability: ash trail shows direction; smoke never fully hides active attack.
- Minimum animation needs: run, smoke pass, reveal, attack, recovery, hit, fall.
- Placeholder reuse: flanker body with gray palette.

### Ember Carrier
- Combat role: small hazard placer.
- Preferred spacing and depth behavior: keeps mid-distance and drops short-lived fire patches on one lane.
- Attack range: short drop or toss.
- Movement pressure: temporarily denies a small patch, never a whole arena.
- Counterplay: move out before ignition, interrupt carrier, wait for patch burnout.
- Readability: ember shake and orange border show patch before damage.
- Minimum animation needs: carry, drop, ignite, panic/recover, hit, fall.
- Placeholder reuse: ranged/static body with ember VFX.

### Wet Plank Brute
- Combat role: slow heavy passage controller.
- Preferred spacing and depth behavior: holds narrow wooden crossings and commits to same-lane slams.
- Attack range: short to medium board swing.
- Movement pressure: discourages direct lane contest.
- Counterplay: bait slam into weak boards, sidestep, punish long recovery.
- Readability: board lift and creaking sound telegraph the attack.
- Minimum animation needs: lumber walk, lift, slam, stuck recovery, hit, fall.
- Placeholder reuse: bruiser body with plank prop.

## Aftermath And Finale Roles

### Debt Echo
- Combat role: temporary memory hazard, not a full enemy swarm.
- Preferred spacing and depth behavior: appears only on a readable lane tied to the current location echo.
- Attack range: one short scripted attack or environmental sweep.
- Movement pressure: makes the player acknowledge previous consequences without crowding the arena.
- Counterplay: read the location cue, leave the marked lane, then resume normal fight.
- Readability: echo tint and location-specific cue appear before active frames.
- Minimum animation needs: appear, warning, attack, dissolve.
- Placeholder reuse: ghosted copy of existing humanoid placeholders.

### Aftermath Bosses
- `Хозяин конвейера`: area-control boss for cooled factory; uses dried foam lanes, stuck conveyor bursts, and slow glass/metal swings.
- `Комментатор`: stadium pressure boss; uses speaker cones, shame/crowd wave lanes, and old commentary timing.
- `Паводок`: bridge mass boss; uses water push lanes, debris drifts, and cold pull zones.
- `Сеть`: metro system boss; uses cable lanes, signal boxes, doors, and announcement rhythms.
- `Следопыт`: forest search boss; uses thermal scan lanes, radio calls, and smoke-reveal attacks.

## Level Mapping
- `level1_factory_setpieces.md`: Rivet Charger, Arc Welder, Belt Launcher, Chief Technologist.
- `level2_stadium_design_and_blockout.md`: Turnstile Shover, Bottle Thrower, Flag Runner, Champion.
- `level3_bridge_design_and_blockout.md`: Cable Hook, Raincoat Guard, Headlight Sprinter, Engineer.
- `level4_metro_design_and_blockout.md`: Token Clerk, Tunnel Dragger, Signal Worker, Duty Officer.
- `level5_forest_camp_design_and_blockout.md`: Ash Runner, Ember Carrier, Wet Plank Brute, Forest Keeper.
- `second_pass_aftermath_levels_design.md`: aftermath bosses and reduced-role support enemies.
- `mirror_toast_final_levels_design.md`: Debt Echo, Reflection, Bartender.

## Implementation Notes
- First code pass should create placeholder scenes only after each level task selects exact encounter needs.
- Prefer extending existing enemy behavior patterns conservatively rather than creating bespoke systems for every role.
- Ranged and area attacks should be implemented as lane-aware telegraphs plus existing hitbox/projectile conventions.
- No placeholder should require player script changes.

## Acceptance Criteria
- All required new enemies have role, spacing, range, movement pressure, counterplay, readability, minimum animation needs, and placeholder reuse guidance.
- Ranged and area-control rules preserve depth-aware combat.
- The roster names which enemies are required by each level task.
