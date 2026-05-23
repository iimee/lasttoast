# Factory Enemy Roles

## Purpose
Define three readable factory enemy roles that pressure the player through depth-aware positioning, distinct attack ranges, and clear counterplay. The roles are designed to combine without breaking combat readability on the shared field.

## Level 1 Factory Implementation Pass

### Roster intent
The first factory pass should stay small and practical: three reusable worker enemy roles, each teaching one combat read. The player learns direct same-depth pressure first, then frontal area denial, then ranged line pressure. Mixed waves should test target priority and depth movement without requiring new global combat rules.

### Shared factory enemy rules
- Enemies must align to the player's current depth band before activating melee or lane attacks.
- No factory enemy may damage the player from a different depth band unless the attack has an explicit telegraph and overlap volume for that band.
- Ranged shots travel on one readable line and do not home after release.
- Area denial must leave either one open depth band or a clear recovery window.
- Enemy attacks should be interruptible during startup unless the encounter is explicitly using a hazard timing window.
- Knockback should push enemies along X first and clamp depth to valid movement bounds after displacement.
- First-pass scenes may reuse existing humanoid placeholders with prop/color differentiation.

### First-pass tuning targets
- Rivet Charger: high presence, low complexity, short recovery punish.
- Arc Welder: medium presence, clear startup, small active area.
- Belt Launcher: low health backline pressure, long reload, readable projectile.
- Standard non-boss factory wave budget: one anchor plus one support. Use all three roles together only after each has appeared alone or in a simple pair.

## Role 1: Rivet Charger

### Gameplay purpose
Frontline bruiser that claims horizontal space and forces the player to respect short windups in close pursuit.

### Space behavior
- Prefers direct pursuit and walks into close range before attacking.
- If the player shifts depth, the Charger re-aligns before restarting pressure.
- Stays grounded in short-range frontal pressure and does not threaten the whole field at once.

### Attack pattern
- Short-range shoulder rush or wrench swing directly in front of itself.
- Uses a visible windup, then commits to a brief forward burst that covers a small horizontal gap.
- Best used as the encounter anchor that keeps the player busy while other enemies set up.

### Attack range
- Close range only.
- Forward burst can extend melee reach slightly but remains narrow and readable.

### Movement pressure
- Steady advance with brief commitment windows.
- Pushes the player toward screen edges or into the threat space created by ranged allies.

### Counterplay
- Step off its approach line during the windup, then punish recovery.
- Bait the forward burst and hit during the committed end-lag.
- Projectiles and poke attacks are effective before the Charger enters melee range.

### Escalation use
- Early waves: appears alone or in pairs to teach direct pressure reads.
- Mid waves: pairs with a ranged unit so dodging the Charger can expose the player to a second angle.

### Constraints
- Burst distance must stay short enough that repositioning in depth remains a reliable answer.
- Recovery must be long enough to preserve readable punish windows.

### Level 1 encounter usage
- Setpiece 1, Gatehouse: single Charger teaches same-depth attack alignment.
- Setpiece 2, Conveyor: two Chargers create X pressure while crates teach movement interruption.
- Setpiece 3, First Valve: delayed Charger enters after the player starts interacting with the valve.
- Setpiece 7, Machine Hall: Charger acts as the stable anchor while hazards and support roles rotate.
- Boss support: one Charger may appear in phase 1 only, then should not stack with dense hazard patterns.

### Implementation notes
- Use an existing melee enemy behavior as the base if possible.
- Attack activation should require same-depth overlap plus frontal facing.
- Burst should lock direction only after startup begins, so depth movement remains valid counterplay.
- Miss recovery must not become a looping attack state.

## Role 2: Arc Welder

### Gameplay purpose
Area denial specialist that controls a narrow frontal slice and forces repositioning without creating unavoidable full-field damage.

### Space behavior
- Holds a chosen patch of floor instead of constantly chasing.
- Repositions only when the player stays out of reach for too long or when allies overcrowd its space.
- Its attack stays mostly frontal, with only a tightly limited side splash at point-blank range.

### Attack pattern
- Charges a welding arc in front of itself, then emits a short cone of sparks.
- Core hit area remains in front of the enemy.
- Optional edge splash may threaten only immediate side proximity to sell heat and sparks, never the whole screen.

### Attack range
- Short to mid range.
- Strongest when the player stands directly in front of it at matching depth.

### Movement pressure
- Creates temporary no-go space that discourages holding centerline positions.
- Encourages flanks, depth shifts, or interrupt timing instead of pure backpedaling.

### Counterplay
- Interrupt during charge-up with quick attacks or projectiles.
- Rotate around its frontal cone before the sparks release, then re-enter on recovery.
- Force the Welder to retarget by attacking from outside its narrow frontal control zone.

### Escalation use
- Mid waves: supports Chargers by punishing players who retreat in a straight line.
- Higher pressure groups: two Welders on offset depths create readable safe pockets without covering the whole screen.

### Constraints
- Any side splash must be visually explicit and limited to immediate proximity.
- Charge timing must leave a clear reaction window.

### Level 1 encounter usage
- Setpiece 3, First Valve: first Welder holds the center band while the player learns to work around the valve.
- Setpiece 4, Welding Shop: primary teaching space for frontal cones and offset safe pockets.
- Setpiece 7, Machine Hall: one Welder can protect a valve or machine lane, but should not overlap with another active area-control hazard.
- Boss phase 2: one Welder may guard a control path while steam alternates elsewhere.

### Implementation notes
- Build the arc as a telegraphed hitbox in front of the enemy, not as a full radial area.
- Optional side splash should be separate, short-lived, and smaller than the main frontal hitbox.
- The enemy should retarget only after recovery, not during active frames.
- If two Welders are ever active, their cones must be offset so a visible route remains open.

## Role 3: Belt Launcher

### Gameplay purpose
Backline disruptor that punishes passive play and makes the player read projectile timing while respecting depth and line of fire.

### Space behavior
- Prefers backline spacing and tries to keep clean firing space behind melee allies.
- Fires along a direct horizontal line.
- If crowded or directly pressured, it relocates to an open patch before resuming fire.

### Attack pattern
- Launches a crate shard, bolt bundle, or compressed scrap shot straight ahead.
- Uses a readable setup pose and moderate projectile speed so the player can react.
- May fire a two-shot sequence at higher escalation, but never as an instant barrage.

### Attack range
- Mid to long range along its current firing line.
- No homing or field-wide shots that ignore spacing.

### Movement pressure
- Forces the player to close distance or shift depth instead of turtling.
- Makes screen position matter by threatening predictable firing lines behind frontline enemies.

### Counterplay
- Step off the firing line after the tell, then advance during the reload gap.
- Use melee rushdown, knockback, or projectile interruption before the Launcher resets spacing.
- Prioritize it when frontline enemies are already committed elsewhere.

### Escalation use
- Core support piece behind a Charger.
- Strongest in mixed groups where a Welder limits one escape route and the Launcher covers another.

### Constraints
- Projectile speed must stay readable in shared-screen combat.
- Reload gap must remain long enough that repositioning and advances are rewarding.

### Level 1 encounter usage
- Setpiece 2, Conveyor: first Launcher appears after the player has seen crate movement, firing down one center line.
- Setpiece 5, Storage Line: main teaching space for backline pressure behind barrels and stacked goods.
- Setpiece 7, Machine Hall: Launcher covers a single line while other hazards create timing, not total lockdown.
- Boss phase support: use sparingly; if the boss already pressures range, replace Launcher with a Charger.

### Implementation notes
- Use existing projectile conventions for spawn, travel, impact, and one-hit damage.
- Projectile lane should be derived from the Launcher's current depth band at fire time.
- The Launcher should relocate only during reload or when directly pressured, never while a shot is active.
- Two-shot escalation is allowed only after the single shot has been taught and must preserve a reload gap.

## Factory Encounter Ramp

### 1. Gatehouse
- Enemy mix: 1 Rivet Charger.
- Purpose: teach that enemies must match depth before melee hits.
- Safe answer: step off the approach line during startup, then punish recovery.
- Acceptance: the player can see the windup, depth shift away, and confirm the Charger misses.

### 2. Conveyor
- Enemy mix: 2 Rivet Chargers, then 1 Belt Launcher.
- Purpose: combine X pressure with a single projectile line.
- Safe answer: use depth movement to avoid the shot, then close during reload.
- Acceptance: crates, Chargers, and projectile timing never cover every depth band at once.

### 3. First Valve
- Enemy mix: 1 Arc Welder, delayed 1 Rivet Charger.
- Purpose: make the player split attention between interaction progress and frontal area denial.
- Safe answer: rotate around the Welder cone and use the Charger's recovery window to resume valve interaction.
- Acceptance: valve interaction has visible progress and never requires standing immobile inside unavoidable damage.

### 4. Welding Shop
- Enemy mix: 1 Arc Welder, then Charger + Welder pair.
- Purpose: teach offset cones and safe pockets.
- Safe answer: interrupt startup or enter from outside the cone after it fires.
- Acceptance: any two area threats leave one readable lane or one readable timing gap.

### 5. Storage Line
- Enemy mix: 1 Belt Launcher behind 1 Charger.
- Purpose: teach target priority against backline pressure.
- Safe answer: bait Charger commitment, shift depth off the shot line, then punish Launcher reload.
- Acceptance: props do not hide feet, projectile origin, or impact path.

### 6. Freight Lift
- Enemy mix: 1 Charger, optional 1 Launcher on later repeat.
- Purpose: compress the arena without adding complex new behavior.
- Safe answer: hold middle depth until the lift timing opens a flank.
- Acceptance: lift boundaries clamp movement cleanly and do not break knockback or depth state.

### 7. Machine Hall
- Enemy mix: 1 Charger + 1 Welder + 1 Launcher, with one environmental hazard active at a time.
- Purpose: final standard enemy exam before the boss.
- Safe answer: prioritize the support role that controls the current route, then reset around the Charger.
- Acceptance: the densest normal wave still leaves either a route, a stagger window, or a reload window.

### 8. Reservoir Boss
- Enemy mix: boss first, then small role assists by phase.
- Purpose: use factory roles as pressure punctuation, not as the main spectacle.
- Safe answer: read boss attacks first; support enemies should force movement but not hide boss telegraphs.
- Acceptance: support spawns never coincide with unavoidable valve/panel interaction damage.

## First Implementation Slice

1. Build or configure Rivet Charger as the first playable factory enemy.
2. Add Belt Launcher only after Charger same-depth behavior is stable.
3. Add Arc Welder after projectile lane behavior is proven.
4. Integrate mixed groups into setpieces only after individual role tests pass.

## Validation Checklist

- Charger cannot hit across depth without actual overlap.
- Welder cone has a visible startup, active window, and recovery.
- Launcher projectile keeps a fixed lane after firing.
- Mixed waves do not cover all depth bands at the same time.
- Hitstop, knockback, and interrupt states always exit cleanly.
- No implementation requires changes to `Player/player.gd`.

## Encounter Readability

### Recommended combinations
- Charger + Launcher: simple pressure pair where the Charger owns close space and the Launcher punishes passive retreat.
- Charger + Welder: forces timely repositioning without requiring wide-area attacks.
- Charger + Welder + Launcher: full factory squad that tests approach choice, depth movement, and target priority.

### Readability rules
- Avoid stacking overlapping area-control roles across the whole field at once.
- Keep at least one visibly safer route or timing window so encounters stay recoverable.
- Use silhouette and telegraph differences so the player can read which enemy is claiming space, denying an approach, or covering range.

## Acceptance Check
- Three roles are defined.
- Each role includes gameplay purpose, space behavior, attack pattern, attack range, counterplay, and escalation use.
- All attacks remain spatially readable, with the Welder's side splash explicitly limited and justified.
- The role set supports readable mixed factory encounters on one shared combat field.
