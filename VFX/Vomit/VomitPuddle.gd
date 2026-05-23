extends Node2D

@export var lifetime: float = 3.0
@export var fade_time: float = 0.25
@export var render_z_offset: int = 0
@export var sprite_local_offset: Vector2 = Vector2.ZERO
@export var puddle_anim: StringName = &"default"
@export var slow_radius: float = 24.0
@export var slow_multiplier: float = 0.6
@export var slow_refresh_time: float = 0.18
@export var depth_hit_tolerance: float = 8.0
@export var affect_player: bool = true
@export var affect_enemies: bool = true
@export var firearea_detect_radius: float = 28.0
@export var firearea_sustain_window: float = 0.35
@export var fire_scene: PackedScene = preload("res://VFX/FireArea/FireArea.tscn")
@export var fire_chain_radius: float = 42.0

var lane_index: int = -1
var depth_y: float = 0.0
var _sprite_base_position: Vector2 = Vector2.ZERO
var _flip_h: bool = false
var _ignited: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite2D

func _ready() -> void:
	set_physics_process(true)
	add_to_group("vomit_puddle")

	# Default fallback if caller did not provide explicit render layer.
	z_as_relative = true
	z_index = render_z_offset

	if sprite:
		_sprite_base_position = sprite.position
		sprite.flip_h = _flip_h
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(puddle_anim):
			sprite.play(String(puddle_anim))
	_apply_lane_visual()

	if lifetime <= 0.0:
		queue_free()
		return

	await get_tree().create_timer(lifetime).timeout
	if not is_inside_tree():
		return

	if fade_time <= 0.0 or sprite == null:
		queue_free()
		return

	var tw: Tween = create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, fade_time)
	await tw.finished
	queue_free()

func _physics_process(_delta: float) -> void:
	if not _ignited and _is_touching_firearea():
		_ignite_connected_cluster()
	_apply_slow()
	_sustain_touching_fireareas()

func set_render_z_layer(base_z: int, offset: int = -1) -> void:
	# Keep relative layering so puddle stays visible in world and only shifts under actors.
	z_as_relative = true
	z_index = offset

func set_lane_index(i: int) -> void:
	lane_index = i
	if lane_index != -1:
		depth_y = LaneSystem.center_from_lane(lane_index)
	_apply_lane_visual()

func set_depth_y(v: float) -> void:
	depth_y = v
	_apply_lane_visual()

func set_facing_dir(dir: Vector2) -> void:
	_flip_h = dir.x < 0.0
	if sprite:
		sprite.flip_h = _flip_h

func _apply_lane_visual() -> void:
	if sprite:
		sprite.position = _sprite_base_position + sprite_local_offset + Vector2(0.0, depth_y)

func _apply_slow() -> void:
	if slow_radius <= 0.0:
		return

	if affect_player:
		for n in get_tree().get_nodes_in_group("Player"):
			_try_apply_slow_to_node(n)

	if affect_enemies:
		for n in get_tree().get_nodes_in_group("Enemy"):
			_try_apply_slow_to_node(n)

func _try_apply_slow_to_node(n: Node) -> void:
	if n == null or not is_instance_valid(n):
		return
	if not (n is Node2D):
		return
	if not _is_same_lane_or_unknown(n):
		return

	var n2: Node2D = n as Node2D
	if global_position.distance_squared_to(n2.global_position) > slow_radius * slow_radius:
		return

	var slow_mul: float = clampf(slow_multiplier, 0.1, 1.0)
	if n.has_method("apply_surface_slow"):
		n.call("apply_surface_slow", slow_mul, slow_refresh_time)

func _sustain_touching_fireareas() -> void:
	if firearea_sustain_window <= 0.0 or firearea_detect_radius <= 0.0:
		return

	for n in get_tree().get_nodes_in_group("Hazard"):
		if n == null or not is_instance_valid(n):
			continue
		if not n.has_method("extend_lifetime"):
			continue
		if not (n is Node2D):
			continue
		if not _is_same_lane_or_unknown(n):
			continue

		var n2: Node2D = n as Node2D
		if global_position.distance_squared_to(n2.global_position) > firearea_detect_radius * firearea_detect_radius:
			continue

		if n.has_method("sustain_from_puddle"):
			n.call("sustain_from_puddle", firearea_sustain_window)
		elif n.has_method("extend_lifetime"):
			n.call("extend_lifetime", firearea_sustain_window)

func _is_touching_firearea() -> bool:
	if firearea_detect_radius <= 0.0:
		return false

	for n in get_tree().get_nodes_in_group("Hazard"):
		if n == null or not is_instance_valid(n):
			continue
		if not n.has_method("extend_lifetime"):
			continue
		if not (n is Node2D):
			continue
		if not _is_same_lane_or_unknown(n):
			continue

		var n2: Node2D = n as Node2D
		if global_position.distance_squared_to(n2.global_position) <= firearea_detect_radius * firearea_detect_radius:
			return true

	return false

func _ignite_connected_cluster() -> void:
	var cluster: Array = _collect_connected_puddles()
	for n in cluster:
		if n == null or not is_instance_valid(n):
			continue
		if n.has_method("_ignite_self"):
			n.call("_ignite_self")

func _collect_connected_puddles() -> Array:
	var result: Array = []
	var queue: Array = [self]
	var visited: Dictionary = {}

	var sqr_radius: float = fire_chain_radius * fire_chain_radius
	if sqr_radius <= 0.0:
		sqr_radius = 1.0

	while queue.size() > 0:
		var cur_v: Variant = queue.pop_front()
		if not (cur_v is Node2D):
			continue

		var cur: Node2D = cur_v as Node2D
		if cur == null or not is_instance_valid(cur):
			continue

		var cur_id: int = cur.get_instance_id()
		if visited.has(cur_id):
			continue
		visited[cur_id] = true
		result.append(cur)

		for other in get_tree().get_nodes_in_group("vomit_puddle"):
			if other == null or not is_instance_valid(other):
				continue
			if not (other is Node2D):
				continue
			var other2d: Node2D = other as Node2D
			if other2d == cur:
				continue

			if cur.global_position.distance_squared_to(other2d.global_position) > sqr_radius:
				continue
			if not _is_same_lane_or_unknown_between(cur, other2d):
				continue

			queue.append(other2d)

	return result

func _ignite_self() -> void:
	if _ignited:
		return
	_ignited = true
	_spawn_fire_here()

func _spawn_fire_here() -> void:
	if fire_scene == null:
		return
	var parent: Node = _resolve_fire_parent()
	if parent == null:
		return

	var fire: Node = fire_scene.instantiate()
	parent.add_child(fire)

	if fire is Node2D:
		var f2d: Node2D = fire as Node2D
		f2d.global_position = global_position

	if fire is Object:
		var fo: Object = fire as Object
		if fo.get("lane_index") != null:
			fo.set("lane_index", lane_index)
		if fo.has_method("set_depth_y"):
			fo.call("set_depth_y", depth_y)
		elif fo.get("depth_y") != null:
			fo.set("depth_y", depth_y)

func _resolve_fire_parent() -> Node:
	if get_parent() != null:
		return get_parent()
	if get_tree().current_scene != null:
		return get_tree().current_scene
	return get_tree().root

func _is_same_lane_or_unknown(target: Node) -> bool:
	var target_depth: float = _get_target_depth_y(target)
	if is_inf(target_depth):
		return true
	return absf(target_depth - depth_y) <= maxf(0.0, depth_hit_tolerance)

func _is_same_lane_or_unknown_between(a: Node, b: Node) -> bool:
	var depth_a: float = _get_target_depth_y(a)
	var depth_b: float = _get_target_depth_y(b)
	if is_inf(depth_a) or is_inf(depth_b):
		return true
	return absf(depth_a - depth_b) <= maxf(0.0, depth_hit_tolerance)

func _get_target_depth_y(target: Node) -> float:
	if target == null:
		return INF
	if not (target is Object):
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
