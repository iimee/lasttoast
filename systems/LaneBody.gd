extends Node
class_name LaneBody

signal lane_changed(old_lane: int, new_lane: int)

@export var visual_root_path: NodePath
@export var use_visual_offset: bool = true
@export var depth_y: float = 0.0 : set = set_depth_y

# NEW: лок глубины
@export var depth_locked: bool = false

var lane_index: int = 1

var _visual_root: Node2D = null
var _visual_base_y: float = 0.0

func _ready() -> void:
	_visual_root = get_node_or_null(visual_root_path) as Node2D
	if _visual_root and use_visual_offset:
		_visual_base_y = _visual_root.position.y

	depth_y = LaneSystem.clamp_depth(depth_y)
	lane_index = LaneSystem.lane_from_depth(depth_y)
	_apply_visual()

func lock_depth() -> void:
	depth_locked = true

func unlock_depth() -> void:
	depth_locked = false

func set_depth_y(v: float) -> void:
	# NEW: если глубина залочена — игнорируем любые попытки сдвига
	if depth_locked:
		return

	var clamped := LaneSystem.clamp_depth(v)
	if is_equal_approx(clamped, depth_y):
		return

	depth_y = clamped

	var old_lane := lane_index
	var new_lane := LaneSystem.lane_from_depth(depth_y)
	if new_lane != old_lane:
		lane_index = new_lane
		lane_changed.emit(old_lane, new_lane)

	_apply_visual()

func _apply_visual() -> void:
	if not (_visual_root and use_visual_offset):
		return
	_visual_root.position.y = _visual_base_y + depth_y

func get_visual_offset() -> Vector2:
	# Возвращает смещение визуального рута (который реально двигается по depth_y)
	# относительно тела игрока (родителя LaneBody).
	if not (_visual_root and use_visual_offset):
		return Vector2.ZERO

	var body := get_parent() as Node2D
	if body == null:
		return Vector2.ZERO

	return _visual_root.global_position - body.global_position
