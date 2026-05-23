extends Area2D
# Hitbox рвоты: бьёт по врагам и удаляется по таймеру. ВИЗУАЛЬНОЙ АНИМАЦИИ ТУТ НЕТ.

@export var puddle_scene: PackedScene = preload("res://VFX/Vomit/VomitPuddle.tscn")
@export var damage: int = 1
@export var knockback: float = 140.0
@export var enemy_group: String = "Enemy"
@export var ignore_groups: Array[String] = ["Player"]
@export var depth_hit_tolerance: float = 8.0

@export var lifetime: float = 0.22 # подгони под длительность анимации "vomit" у игрока
@export var puddle_spawn_delay: float = 0.8
@export var puddle_x_offset: float = -15.6
@export var puddle_x_offset_flipped: float = -9.6
@export var puddle_y_offset: float = 13.8
@export var puddle_z_offset: int = 0

var _facing: Vector2 = Vector2.RIGHT
var _hit_once: bool = true
var _hit_cache: Dictionary = {}
var lane_index: int = -1
var depth_y: float = 0.0
var render_base_z: int = 0

var facing: Vector2:
	set(value):
		_facing = value
	get:
		return _facing

var direction: Vector2:
	set(value):
		facing = value
	get:
		return facing

func _ready() -> void:
	monitoring = true
	monitorable = true
	add_to_group("attack")

	area_entered.connect(_on_area)
	body_entered.connect(_on_body)

	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)
	else:
		_on_lifetime_timeout()

func set_lane_index(i: int) -> void:
	lane_index = i

func set_depth_y(v: float) -> void:
	depth_y = v

func set_render_base_z(v: int) -> void:
	render_base_z = v

func _on_lifetime_timeout() -> void:
	if puddle_spawn_delay > 0.0:
		await get_tree().create_timer(puddle_spawn_delay).timeout
		if not is_inside_tree():
			return
	_spawn_puddle()
	queue_free()

func _on_attack_timer_timeout() -> void:
	# Timer из сцены оставлен для совместимости со старой настройкой.
	pass

func _spawn_puddle() -> void:
	if puddle_scene == null:
		return
	var parent: Node = _resolve_vfx_parent()
	if parent == null:
		return

	var p: Node = puddle_scene.instantiate()
	parent.add_child(p)
	_place_below_player_in_draw_order(parent, p)

	if p is Node2D:
		# Apply lane depth once in world-space to avoid double visual offset.
		var x_offset: float = puddle_x_offset
		if _facing.x < 0.0:
			x_offset = puddle_x_offset_flipped
		(p as Node2D).global_position = global_position + Vector2(x_offset, depth_y + puddle_y_offset)

	if lane_index != -1:
		if "lane_index" in p:
			p.lane_index = lane_index
		elif p.has_method("set_lane_index"):
			p.call("set_lane_index", lane_index)

	if p.has_method("set_facing_dir"):
		p.call("set_facing_dir", _facing)

	# Do not pass depth_y into puddle node; it is already baked into spawn position above.

	if p.has_method("set_render_z_layer"):
		p.call("set_render_z_layer", render_base_z, puddle_z_offset)
	elif p is CanvasItem:
		var ci: CanvasItem = p as CanvasItem
		ci.z_as_relative = true
		ci.z_index = puddle_z_offset

func _resolve_vfx_parent() -> Node:
	# Important: VFX layer in this project is forced to z=1000 and always above player.
	# Puddle is ground decal, so spawn in gameplay scene layer instead of VFX.
	if get_parent() != null:
		return get_parent()
	if get_tree().current_scene:
		return get_tree().current_scene
	return get_tree().root

func _place_below_player_in_draw_order(parent: Node, puddle: Node) -> void:
	if parent == null or puddle == null:
		return
	var player: Node = _find_player_root_in_parent(parent)
	if player == null:
		return
	var player_idx: int = player.get_index()
	parent.move_child(puddle, maxi(0, player_idx))

func _find_player_root_in_parent(parent: Node) -> Node:
	# Group "Player" also contains Camera2D/AudioStreamPlayer in this project.
	# We need the actual player root node that is a direct child of the same parent.
	for n in get_tree().get_nodes_in_group("Player"):
		if n == null:
			continue
		if n.get_parent() != parent:
			continue
		if n.name == "Player":
			return n
		if n is CharacterBody2D or n is Node2D:
			return n
	return null

func _on_area(a: Area2D) -> void:
	_apply_hit(a)

func _on_body(b: Node2D) -> void:
	_apply_hit(b)

func _should_hit(target: Node) -> bool:
	if target == null:
		return false
	for g in ignore_groups:
		if target.is_in_group(g):
			return false
	if enemy_group != "" and not target.is_in_group(enemy_group):
		return false
	if not _is_same_lane_or_unknown(target):
		return false
	if _hit_once and _hit_cache.has(target.get_instance_id()):
		return false
	return true

func _mark_hit(target: Node) -> void:
	_hit_cache[target.get_instance_id()] = true

func _apply_hit(target: Node) -> void:
	if not _should_hit(target):
		return
	_mark_hit(target)

	if target.has_method("apply_damage"):
		target.apply_damage(damage, _facing * knockback, global_position)
	elif target is Node2D and target.has_node("Health"):
		var h = target.get_node("Health")
		if h and h.has_method("apply_damage"):
			h.apply_damage(damage, _facing * knockback, global_position)

func _is_same_lane_or_unknown(target: Node) -> bool:
	var target_depth: float = _get_target_depth_y(target)
	if is_inf(target_depth):
		return true
	return absf(target_depth - depth_y) <= maxf(0.0, depth_hit_tolerance)

func _get_target_depth_y(target: Node) -> float:
	if target == null or not (target is Object):
		return INF
	var to: Object = target as Object
	var lb: Variant = to.get("lane_body")
	if lb != null and lb is Object:
		var lbo: Object = lb as Object
		var d1: Variant = lbo.get("depth_y")
		if typeof(d1) == TYPE_FLOAT or typeof(d1) == TYPE_INT:
			return float(d1)
	var d2: Variant = to.get("depth_y")
	if typeof(d2) == TYPE_FLOAT or typeof(d2) == TYPE_INT:
		return float(d2)
	return INF

func _get_target_lane(target: Node) -> int:
	if target == null:
		return -1
	if not (target is Object):
		return -1

	var to: Object = target as Object
	var lb: Variant = to.get("lane_body")
	if lb != null and lb is Object:
		var lbo: Object = lb as Object
		var li: Variant = lbo.get("lane_index")
		if typeof(li) == TYPE_INT:
			return int(li)

	var li2: Variant = to.get("lane_index")
	if typeof(li2) == TYPE_INT:
		return int(li2)

	return -1
