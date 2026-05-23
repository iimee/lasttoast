# Intoxication System Context: Inebriation = HP

## Goal
Use one source of truth for combat and narrative: player HP and inebriation are the same pool.

- `0` inebriation = death (empty state).
- `100%` pool (`hp == hp_max`) = control break (Frenzy), not death.
- Strong actions spend HP, drinking restores HP, but pushes consequences.

## Current Implementation

### 1) Unified HP <-> inebriation pool
File: `Player/player.gd`

Key functions:
- `_bind_hp_to_inebriation_pool()`
- `_on_inebriation_pool_changed(v)`
- `_set_hp_pool(target_value)`
- `spend_skill_hp(cost)`
- `gain_skill_hp(amount)`

Behavior:
- On player init, `hp_max` is taken from `Resources.max_inebriation`.
- Current `hp` is taken from `Resources.inebriation`.
- Any HP change is synced back to `Resources.inebriation`.
- HUD HP bar continues to use `health_changed` (no UI architecture change required).

### 2) Global resource owner
File: `Autoloads/Resources.gd`

- Stores `inebriation`, `max_inebriation`, `nicotine`.
- `add_inebriation(n)` is the central entry for pool updates.

### 3) Bottle/cigarette as pool inputs
File: `Autoloads/ItemEffects.gd`

- `use_full_bottle()`:
  - spends `FULL_BOTTLE`
  - adds `bottle_charges` to `inebriation`
  - gives back `EMPTY_BOTTLE`
- `use_cig_pack()`:
  - spends `CIG_PACK`
  - adds `pack_charges` to nicotine
  - adds `cig_inebriation_gain` to inebriation

## Skill Costs From HP (instead of separate mana)

Current combat-facing skills already use `hp_cost` (and partly `nicotine_cost`):

- `BottleThrowSkill`: `hp_cost = 1` + bottle consumption
- `MolotovThrowSkill`: `hp_cost = 2`, `nicotine_cost = 1` + bottle consumption
- `VomitSkill`: `hp_cost = 1`
- `FireBreathSkill`: `hp_cost = 2`, `nicotine_cost = 1`
- `SmokeRing`: `hp_cost = 1`, `nicotine_cost = 1`
- `Dash`: `nicotine_cost = 1`
- `Dodge`: `nicotine_cost = 1`
- `Berserk`: `hp_cost = 0`, `nicotine_cost = 2`

Skill contract:
- check before cast: `user.can_pay_hp_cost(cost)`
- spend on cast: `user.spend_skill_hp(cost)`

## Consequence Logic

### Low end
- `hp == 0` -> normal death path via `_die()`.

### High end
- `hp == hp_max` -> should trigger uncontrolled behavior (Frenzy).
- This is a separate state, not death.
- Recommended behavior:
  - auto-run to nearest enemy in same lane,
  - auto-attack/aggression for 2-4 seconds,
  - short recovery after Frenzy.

## Resource Roles (design intent)

- `Inebriation/HP`: survival + fuel for risky power actions.
- `Nicotine`: control, tempo, stabilization (dash/dodge/cancel), not primary damage fuel.

## Why This Supports "Consequences"

- Player literally pays with self-state for power.
- Recovering HP via alcohol raises risk of control loss.
- Both ends of the same bar are dangerous, but differently:
  - low end = death,
  - high end = loss of agency.

## Open Design Questions

1. Exact pool size (`max_inebriation`) so that 2-3 bottles frequently push to the top.
2. Exact Frenzy rules at full pool (trigger, duration, cooldown, target priority).
3. Whether to persist consequence debt between encounters (meta layer).
4. Remove/freeze excluded branches (`bag/flight/ball/smokeplatform`) in final rules.

## Fast Verification Checklist

1. Bottle increases HP bar through inebriation, with no double gain.
2. Any skill with `hp_cost` correctly spends HP/inebriation.
3. `hp=0` still triggers death reliably.
4. `hp=hp_max` can host Frenzy logic without breaking current state locks.
