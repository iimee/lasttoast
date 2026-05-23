# Last Toast: Technical Context

## 1. Stack and runtime
- Engine: Godot 4.6
- Language: GDScript
- Genre model: 2D beat'em up with pseudo-depth lanes (`depth_y`) and lane-aware combat/projectiles.

## 2. Entry points and scene flow
- Project entry scene: `res://UI/menu.tscn` (`project.godot` -> `run/main_scene`).
- Main menu script: `UI/menu.gd`
  - Start action loads `res://World/City/city.tscn`.
- World coordinator: `World/main.gd`
  - Resolves player node.
  - Binds HUD (inventory, resources, HP).
  - Handles skill menu and equips skills to player.

## 3. Global singletons (Autoload)
- `SkillsDB` -> `db/SkillsDB.gd`
- `LaneSystem` -> `systems/LaneSystem.gd`
- `Resources` -> `Autoloads/Resources.gd`
- `Inventory` -> `Autoloads/Inventory.gd`
- `ItemEffects` -> `Autoloads/ItemEffects.gd`
- `UtilsNode`, `DevLoadout`, `MetSys` also autoloaded.

Notes:
- `Resources` stores `inebriation` and `nicotine`, emits change signals.
- `Inventory` is item-count storage (`full_bottle`, `empty_bottle`, `cig_pack`).
- `ItemEffects` consumes items and mutates `Resources`.

## 4. Player architecture
Core file: `Player/player.gd` (large central gameplay script).

### Responsibilities
- Movement, jump/air states, animation selection.
- Action lock/state machine (`ActionState`, `AirState`).
- Lane/depth integration via child `LaneBody`.
- Skill slots/cooldowns/use flow.
- Melee combo and melee hitbox integration (`Attack` node).
- Damage intake, invulnerability, berserk modifiers, hitstop/camera shake.

### Important contracts exposed by player
- Skills API:
  - `skills_use_slot(slot)`
  - `equip_skill(slot, skill)`
  - `equip_skill_by_id(slot_index, skill_id)`
  - `skills_spawn_projectile(scene, pos, dir, speed)` (lane-aware spawn helper)
  - `skills_get_aim_dir()`
  - `play_cast_anim(name)`
- Combat/status API used by systems:
  - `apply_damage(amount, a, b)`
  - `apply_surface_slow(multiplier, duration_sec)`
  - `apply_updraft(strength)` (used by fire updraft hazards)

### State safety mechanisms
- Non-loop one-shot animation enforcement.
- Animation-finish handling with fallback to locomotion.
- `_animation_watchdog()` to recover from interrupted/invalid action locks.

## 5. Lane/depth model
Files:
- `systems/LaneSystem.gd`
- `systems/LaneBody.gd`

### Model
- 3 lanes (`LANE_COUNT = 3`), depth range `[-14, 14]`.
- Lane is mostly visual depth, not pure world Y.
- `LaneBody` tracks:
  - `depth_y`
  - `lane_index`
  - optional visual root offset (`visual_root_path`)
  - depth lock (`depth_locked`)

### Collision strategy
- Layer constants:
  - lane_0 -> physics layer 9
  - lane_1 -> layer 10
  - lane_2 -> layer 11
- Player/enemy scripts switch or query masks by lane to avoid cross-lane interactions.

## 6. Skills system
Base: `skills/Skill.gd` (`Resource`, `class_name Skill`).

### Storage/discovery
- Skills are `.tres` resources under `res://skills/impl/**`.
- `db/SkillsDB.gd` recursively loads resources, indexes:
  - by id (`by_id`)
  - by branch (folder under `impl`, e.g. `alcohol`, `cigarette`, `combo`, `bag`)
  - sorted by `sort_key`.

### Runtime usage
- Player has 4 battle slots (`skill_1..skill_4` input actions).
- On use:
  - checks lock/cooldown
  - calls `can_use(user)` and `execute(user)` on skill resource
  - emits `skill_used` / `skill_ready` signals.

### Skill menu/equip
- UI: `UI/SkillSelectMenu.gd`
- Emits equip request; `World/main.gd` forwards to player `equip_skill_by_id`.

## 7. Combat and hit contracts

### Common damage contract in project
Most combat systems expect targets to implement:
- `apply_damage(damage, knockback_vec, source_pos)`

Alternative fallbacks exist in some scripts:
- `take_damage(...)`
- `hurt(...)`

### Melee
- Hitbox: `Combat/Hitboxes/Attack.gd`
- Activated by player combo logic (`swing`), has per-target hit cache and optional attacker pushback.

### Dash combat
- Skill: `skills/impl/cigarette/DashSkill.gd`
- Runtime controller: `Combat/Hitboxes/DashController.gd`
- Controller sets `user.is_dashing`, applies hit scans, knockback, and dash animation loop control.

## 8. Projectiles and VFX hazards

### Core projectile-like scripts
- Smoke projectile: `Combat/Projectiles/Projectile.gd`
- Bottle projectile: `Combat/Projectiles/BottleFly.gd`
- Molotov projectile: `Combat/Projectiles/MolotovFly.gd`

### Lane handling pattern
- Projectiles store `lane_index` and optionally `depth_y`.
- Most collision handlers resolve target lane from:
  - `target.lane_body.lane_index`, or
  - `target.lane_index`.
- If both lanes are known and mismatch -> hit is ignored.

### Ground hazards
- Fire hazard: `VFX/FireArea/FireArea.gd`
  - delayed activation
  - periodic damage ticks
  - optional updraft for players
  - lane filtering on damage
- Vomit puddle: `VFX/Vomit/VomitPuddle.gd`
  - slow surface effect by radius
  - can sustain nearby fire hazard lifetime
  - lane-aware effect application
- Vomit hitbox: `Combat/Hitboxes/vomithitbox.gd`
  - short-lifetime hitbox
  - delayed puddle spawn with lane/depth propagation

## 9. Input map (high-signal actions)
- Combat/skills: `attack`, `skill_1..skill_4`, `dodge`, `use_bottle`, `use_cigs`
- Lane movement: `lane_up`, `lane_down` (plus depth axis via `ui_up/ui_down` in player movement)
- UI: `open_skills_menu`, `ui_start`, `ui_quit`.

## 10. Groups conventions used across code
- `Player`
- `Enemy`
- `attack` (many player projectiles/hitboxes)
- `Hazard` (fire area)
- `vfx`, `vfx_layer`
- `skill_menu`
- Pickup groups like `bottle`, `cigarette`.

## 11. Known technical risks / inconsistencies
- `Player/player.gd` is a monolith (movement, combat, skills, damage, camera, animation recovery in one file).
- Comments contain mojibake/encoding artifacts in multiple scripts (source readability issue).
- `Autoloads/DevLoadout.gd` references `/root/db/SkillsDB` and methods not present in current `db/SkillsDB.gd` (`preset_loadout`), likely stale.
- Skill timing relies on animation frame rates plus manual delays; easy to desync if animation assets change.
- Multiple damage entry contracts are supported (`apply_damage`, `take_damage`, `hurt`), which increases integration ambiguity.

## 12. Where to modify for common tasks
- Player state/animation lock issues: `Player/player.gd`
- Dash behavior and dash-hit tuning: `skills/impl/cigarette/DashSkill.gd`, `Combat/Hitboxes/DashController.gd`
- Projectile lane behavior: `Combat/Projectiles/*.gd`
- Fire/vomit interactions: `VFX/FireArea/FireArea.gd`, `VFX/Vomit/VomitPuddle.gd`, `Combat/Hitboxes/vomithitbox.gd`
- Skill DB / loadouts: `db/SkillsDB.gd`, `skills/impl/**/*.tres`, `skills/impl/**/*.gd`
