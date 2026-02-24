extends Node
class_name Utils  # оставь; автолоад назван по-другому — конфликта нет

# -------- СТАТИКА (как было) --------
static func get_scene_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

static func get_vfx_parent(tree: SceneTree = null) -> Node:
	tree = tree if tree != null else get_scene_tree()
	var groups: Array[Node] = tree.get_nodes_in_group("vfx_layer")
	if groups.size() > 0: return groups[0]
	if tree.current_scene and tree.current_scene.has_node("VFX"):
		return tree.current_scene.get_node("VFX")
	return tree.current_scene if tree.current_scene else tree.root

# -------- ИНСТАНС (для UtilsNode) --------
signal bus(event: StringName, data)   # глобальная шина событий

var debug_mode: bool = false
var _tree: SceneTree
var _vfx_parent: Node

func _ready() -> void:
	_tree = get_tree()
	_vfx_parent = Utils.get_vfx_parent(_tree)

func set_debug(on: bool) -> void:
	debug_mode = on

func notify(event: StringName, data=null) -> void:
	bus.emit(event, data)

func spawn_vfx_i(scene: PackedScene, pos: Vector2) -> Node:
	if scene == null: return null
	var parent := _vfx_parent if _vfx_parent != null else Utils.get_vfx_parent(_tree)
	var fx: Node = scene.instantiate()
	parent.add_child(fx)
	if fx is Node2D:
		(fx as Node2D).global_position = pos
	return fx

func after(seconds: float, fn: Callable) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = seconds
	add_child(t)
	t.timeout.connect(fn)
	t.start()
