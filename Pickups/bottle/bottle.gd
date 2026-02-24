extends Area2D
# Пикап полной бутылки

@export var amount: int = 1
@export var feedback_scene: PackedScene = preload("res://Pickups/Feedback/feedback.tscn")
@export var pickup_sfx: AudioStream = null

var _audio: AudioStreamPlayer2D

const ItemDB = preload("res://db/ItemDB.gd")

func _ready() -> void:
	add_to_group("pickup_bottle")
	monitoring = true
	monitorable = true
	set_physics_process(false)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if pickup_sfx:
		_audio = AudioStreamPlayer2D.new()
		_audio.stream = pickup_sfx
		add_child(_audio)

func _on_area_entered(a: Area2D) -> void:
	if _as_player(a): _pickup()

func _on_body_entered(b: Node) -> void:
	if _as_player(b): _pickup()

func _as_player(n: Node) -> Node:
	var up := n
	for i in range(4):
		if up == null: break
		if up.is_in_group("Player"): return up
		up = up.get_parent()
	return null

func _pickup() -> void:
	var inv := _get_inventory()
	if inv:
		inv.add(ItemDB.FULL_BOTTLE, amount)
	else:
		push_warning("Inventory autoload not found. Expected /root/Inventory or /root/Autoloads/Inventory.")
	if _audio: _audio.play()
	_spawn_feedback()
	queue_free()

func _get_inventory() -> Node:
	var root := get_tree().root
	if root.has_node("Inventory"):
		return root.get_node("Inventory")
	if root.has_node("Autoloads/Inventory"):
		return root.get_node("Autoloads/Inventory")
	return null

func _spawn_feedback() -> void:
	if not feedback_scene: return
	var fx := feedback_scene.instantiate()
	var host := get_tree().current_scene if get_tree().current_scene else get_tree().root
	host.add_child(fx)
	if fx is Node2D:
		(fx as Node2D).global_position = global_position
