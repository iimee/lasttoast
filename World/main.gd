extends Node

const ItemDB = preload("res://db/ItemDB.gd")
const GLOBAL_HUD_SCENE = preload("res://UI/GlobalHUD.tscn")
const SCENE_CITY: String = "res://World/City/city.tscn"
const SCENE_BAR: String = "res://World/Bar/bar.tscn"
const SCENE_STADIUM: String = "res://World/Stadium/stadium_level_2.tscn"
const SCENE_BRIDGE: String = "res://World/Bridge/bridge_level_3.tscn"
const SCENE_METRO: String = "res://World/Metro/metro_level_4.tscn"
const SCENE_FOREST_CAMP: String = "res://World/ForestCamp/forest_camp_level_5.tscn"
const SCENE_FACTORY_LEVEL_1: String = "res://World/Factory/factory_level_1.tscn"

# Можно задать путь до Player через инспектор (в каждой сцене свой)
@export var player_path: NodePath

# UI-лейблы
var full_bottle_label: Label = null
var empty_bottle_label: Label = null
var cig_pack_label: Label = null
var inebriation_label: Label = null
var nicotine_label: Label = null
var hp_bar: ProgressBar = null

var player: Node = null
var _health_bound_player: Node = null
var skill_menu: Control = null
var _scene_is_changing: bool = false

func _ready() -> void:
	_ensure_compact_hud()
	# --- UI-лейблы ---
	full_bottle_label   = _find_ui_label("FullBottleLabel")
	empty_bottle_label  = _find_ui_label("EmptyBottleLabel")
	cig_pack_label      = _find_ui_label("CigPackLabel")
	inebriation_label   = _find_ui_label("InebriationLabel")
	nicotine_label      = _find_ui_label("NicotineLabel")
	hp_bar = _find_ui_progress_bar("HPBar")
	_ensure_hp_bar()

	# --- Игрок ---
	player = _resolve_player()
	_bind_player_health(player)
	var tree := get_tree()
	if not tree.node_added.is_connected(Callable(self, "_on_node_added")):
		tree.node_added.connect(Callable(self, "_on_node_added"))

	# --- Инвентарь ---
	if not Inventory.inventory_changed.is_connected(_on_inventory_changed):
		Inventory.inventory_changed.connect(_on_inventory_changed)

	# --- Ресурсы ---
	var res: Node = get_node_or_null("/root/Resources")
	if res != null:
		if res.has_signal("inebriation_changed") \
		and not res.is_connected("inebriation_changed", Callable(self, "_on_inebriation_changed")):
			res.connect("inebriation_changed", Callable(self, "_on_inebriation_changed"))
		if res.has_signal("nicotine_changed") \
		and not res.is_connected("nicotine_changed", Callable(self, "_on_nicotine_changed")):
			res.connect("nicotine_changed", Callable(self, "_on_nicotine_changed"))
	else:
		push_warning("[MAIN] Autoload 'Resources' not found — resource labels will show 0.")

	# --- Инициализация HUD ---
	_refresh_inventory_labels()
	_refresh_resource_labels()
	_refresh_player_health_from_props()

	# --- Уже существующие пикапы ---
	for b in get_tree().get_nodes_in_group("bottle"):
		_connect_bottle(b)
	for c in get_tree().get_nodes_in_group("cigarette"):
		_connect_cigarette(c)

	# --- Меню скиллов ---
	var sm_list := get_tree().get_nodes_in_group("skill_menu")
	if sm_list.is_empty():
		push_error("[MAIN] SkillSelectMenu в группе 'skill_menu' не найден. Повесь узел в сцену и добавь в группу.")
	else:
		skill_menu = sm_list[0]
		skill_menu.hide()
		if not skill_menu.skill_chosen.is_connected(_on_skill_chosen):
			skill_menu.skill_chosen.connect(_on_skill_chosen)
		if not skill_menu.equip_requested.is_connected(_on_equip_requested):
			skill_menu.equip_requested.connect(_on_equip_requested)

	_setup_scene_transitions()

# -------------------- Поиск игрока --------------------
func _resolve_player() -> Node:
	# 1) Пробуем явный путь из инспектора
	if player_path != NodePath(""):
		var p := get_node_or_null(player_path)
		if p:
			print("[MAIN] Player resolved by path: ", p)
			player = p
			return player
		else:
			push_warning("[MAIN] player_path задан, но нода не найдена: %s" % String(player_path))

	# 2) Пробуем кэш, если он ещё жив
	if is_instance_valid(player) and player.is_inside_tree():
		return player

	# 3) Фоллбек — первая нода в группе Player
	var g := get_tree().get_nodes_in_group("Player")
	if g.size() > 0:
		player = g[0]
		print("[MAIN] Player resolved by group: ", player)
		return player

	push_warning("[MAIN] Player not found (no path, no group match)")
	return null

func _get_player() -> Node:
	# Обёртка, которую вызываем из любых мест
	return _resolve_player()

# -------------------- Ввод --------------------
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_quit"):
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_skills_menu") or event.is_action_pressed("open_skills_menu"):
		_toggle_skill_menu()
		get_viewport().set_input_as_handled()

# -------------------- Тоггл меню --------------------
func _toggle_skill_menu() -> void:
	if skill_menu == null:
		push_error("[MAIN] skill_menu = null — узел не найден/не в группе 'skill_menu'")
		return
	if skill_menu.visible:
		skill_menu.hide()
	else:
		skill_menu.show()
		skill_menu.grab_focus()

# -------------------- Реакция на появление новых нод --------------------
func _on_node_added(n: Node) -> void:
	if n.is_in_group("Player"):
		# каждый новый Player переопределяет ссылку
		player = n
		print("[MAIN] node_added -> Player set to: ", player)
		_bind_player_health(player)
	if n.is_in_group("bottle"):
		_connect_bottle(n)
	if n.is_in_group("cigarette"):
		_connect_cigarette(n)

func _ensure_hp_bar() -> void:
	if hp_bar != null:
		return
	var ui: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui == null:
		return
	var pb := ProgressBar.new()
	pb.name = "HPBar"
	pb.min_value = 0.0
	pb.max_value = 100.0
	pb.value = 100.0
	pb.step = 1.0
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(268.0, 12.0)
	pb.offset_left = 8.0
	pb.offset_top = 40.0
	pb.offset_right = 276.0
	pb.offset_bottom = 52.0
	ui.add_child(pb)
	hp_bar = pb

func _ensure_compact_hud() -> void:
	var ui: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui == null:
		ui = CanvasLayer.new()
		ui.name = "UI"
		add_child(ui)
	if ui.get_node_or_null("HUDRoot") != null:
		return

	for child in ui.get_children():
		child.free()

	var hud := GLOBAL_HUD_SCENE.instantiate()
	ui.add_child(hud)

func _find_ui_label(node_name: String) -> Label:
	return _find_ui_node(node_name) as Label

func _find_ui_progress_bar(node_name: String) -> ProgressBar:
	return _find_ui_node(node_name) as ProgressBar

func _find_ui_node(node_name: String) -> Node:
	var ui: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui == null:
		return null
	return ui.find_child(node_name, true, false)

func _bind_player_health(p: Node) -> void:
	if _health_bound_player != null \
	and is_instance_valid(_health_bound_player) \
	and _health_bound_player.is_connected("health_changed", Callable(self, "_on_player_health_changed")):
		_health_bound_player.disconnect("health_changed", Callable(self, "_on_player_health_changed"))

	_health_bound_player = p
	if p == null:
		_set_hp_bar_values(0, 1)
		return
	if p.has_signal("health_changed") \
	and not p.is_connected("health_changed", Callable(self, "_on_player_health_changed")):
		p.connect("health_changed", Callable(self, "_on_player_health_changed"))

	_refresh_player_health_from_props()

func _refresh_player_health_from_props() -> void:
	if player == null:
		_set_hp_bar_values(0, 1)
		return
	var cur: int = int(player.get("hp"))
	var max_hp: int = int(player.get("hp_max"))
	_set_hp_bar_values(cur, max_hp)

func _on_player_health_changed(current: int, max_hp: int) -> void:
	_set_hp_bar_values(current, max_hp)

func _set_hp_bar_values(current: int, max_hp: int) -> void:
	_ensure_hp_bar()
	if hp_bar == null:
		return
	var safe_max: int = max(1, max_hp)
	var safe_cur: int = clampi(current, 0, safe_max)
	hp_bar.min_value = 0.0
	hp_bar.max_value = float(safe_max)
	hp_bar.value = float(safe_cur)

# =========================
#        HUD: Инвентарь
# =========================
func _on_inventory_changed(id: String, _new_count: int) -> void:
	if id == ItemDB.EMPTY_BOTTLE or id == ItemDB.FULL_BOTTLE or id == ItemDB.CIG_PACK:
		_refresh_inventory_labels()

func _refresh_inventory_labels() -> void:
	var full_count: int  = Inventory.get_count(ItemDB.FULL_BOTTLE)
	var empty_count: int = Inventory.get_count(ItemDB.EMPTY_BOTTLE)
	var pack_count: int  = Inventory.get_count(ItemDB.CIG_PACK)

	_update_full_bottle_label(full_count)
	_update_empty_bottle_label(empty_count)
	_update_cig_pack_label(pack_count)

func _update_full_bottle_label(v: int) -> void:
	if full_bottle_label:
		full_bottle_label.text = str(v)

func _update_empty_bottle_label(v: int) -> void:
	if empty_bottle_label:
		empty_bottle_label.text = str(v)

func _update_cig_pack_label(v: int) -> void:
	if cig_pack_label:
		cig_pack_label.text = str(v)

# =========================
#        HUD: Ресурсы
# =========================
func _on_inebriation_changed(v: int) -> void:
	_update_inebriation_label(v)

func _on_nicotine_changed(v: int) -> void:
	_update_nicotine_label(v)

func _refresh_resource_labels() -> void:
	var res: Node = get_node_or_null("/root/Resources")
	var ineb: int = 0
	var nic: int = 0
	if res != null:
		ineb = int(res.get("inebriation"))
		nic  = int(res.get("nicotine"))
	_update_inebriation_label(ineb)
	_update_nicotine_label(nic)

func _update_inebriation_label(v: int) -> void:
	if inebriation_label:
		var res: Node = get_node_or_null("/root/Resources")
		var max_value: int = max(1, int(res.get("max_inebriation")) if res != null else 1)
		inebriation_label.text = "%d/%d" % [v, max_value]

func _update_nicotine_label(v: int) -> void:
	if nicotine_label:
		var res: Node = get_node_or_null("/root/Resources")
		var max_value: int = max(1, int(res.get("max_nicotine")) if res != null else 1)
		nicotine_label.text = "%d/%d" % [v, max_value]

# =========================
#         Пикапы
# =========================
func _connect_bottle(b: Node) -> void:
	if not b.is_connected("picked_up", Callable(self, "_on_bottle_picked_up")):
		b.connect("picked_up", Callable(self, "_on_bottle_picked_up"))

func _on_bottle_picked_up(amount: int = 1) -> void:
	Inventory.add(ItemDB.FULL_BOTTLE, max(1, amount))

func _connect_cigarette(c: Node) -> void:
	if not c.is_connected("picked_up", Callable(self, "_on_cigarette_picked_up")):
		c.connect("picked_up", Callable(self, "_on_cigarette_picked_up"))

func _on_cigarette_picked_up(amount: int = 1) -> void:
	Inventory.add(ItemDB.CIG_PACK, max(1, amount))

# =========================
#       Скилл-меню
# =========================
func _on_skill_chosen(skill_id: StringName) -> void:
	print("[MAIN] skill chosen: %s" % String(skill_id))

func _on_equip_requested(slot_index: int, skill_id: StringName) -> void:
	print("[MAIN] equip slot %d -> %s" % [slot_index, String(skill_id)])

	var p := _get_player()
	if p and p.has_method("equip_skill_by_id"):
		p.equip_skill_by_id(slot_index, skill_id)
		print("[MAIN] send equip to Player: ", p)
	else:
		push_error("[MAIN] Player not found or has no method 'equip_skill_by_id'")

func _setup_scene_transitions() -> void:
	var root: Node2D = get_parent() as Node2D
	if root == null:
		return
	if root.has_node("SceneExits"):
		return

	var exits: Node2D = Node2D.new()
	exits.name = "SceneExits"
	root.add_child(exits)

	var scene_path: String = root.scene_file_path
	if scene_path == "":
		scene_path = get_tree().current_scene.scene_file_path

	match scene_path:
		SCENE_CITY:
			_add_scene_exit(exits, "ExitToBar", "BAR", Vector2(150, 188), Vector2(52, 42), SCENE_BAR)
			_add_scene_exit(exits, "ExitToStadium", "STADIUM", Vector2(250, 188), Vector2(76, 42), SCENE_STADIUM)
			_add_scene_exit(exits, "ExitToBridge", "BRIDGE", Vector2(370, 188), Vector2(62, 42), SCENE_BRIDGE)
			_add_scene_exit(exits, "ExitToMetro", "METRO", Vector2(600, 188), Vector2(68, 42), SCENE_METRO)
			_add_scene_exit(exits, "ExitToForestCamp", "FOREST", Vector2(720, 188), Vector2(76, 42), SCENE_FOREST_CAMP)
			_add_scene_exit(exits, "ExitToFactoryLevel1", "FACTORY", Vector2(500, 188), Vector2(82, 42), SCENE_FACTORY_LEVEL_1)
		SCENE_BAR:
			_add_scene_exit(exits, "ExitToCity", "CITY", Vector2(80, 188), Vector2(56, 42), SCENE_CITY)
		SCENE_STADIUM:
			_add_scene_exit(exits, "ExitToCity", "CITY", Vector2(80, 188), Vector2(56, 42), SCENE_CITY)
		SCENE_BRIDGE:
			_add_scene_exit(exits, "ExitToCity", "CITY", Vector2(80, 188), Vector2(56, 42), SCENE_CITY)
		SCENE_METRO:
			_add_scene_exit(exits, "ExitToCity", "CITY", Vector2(80, 205), Vector2(56, 48), SCENE_CITY)
		SCENE_FOREST_CAMP:
			_add_scene_exit(exits, "ExitToCity", "CITY", Vector2(80, 205), Vector2(56, 48), SCENE_CITY)
		SCENE_FACTORY_LEVEL_1:
			_add_scene_exit(exits, "ExitToCity", "CITY", Vector2(80, 205), Vector2(56, 48), SCENE_CITY)

func _add_scene_exit(parent: Node2D, node_name: String, label_text: String, pos: Vector2, size: Vector2, target_scene: String) -> void:
	var area: Area2D = Area2D.new()
	area.name = node_name
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 0x7fffffff

	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	area.add_child(shape_node)

	var label: Label = Label.new()
	label.text = label_text
	label.position = Vector2(-size.x * 0.5, -40.0)
	label.modulate = Color(1.0, 0.95, 0.55, 1.0)
	label.add_theme_font_size_override("font_size", 9)
	area.add_child(label)

	area.body_entered.connect(Callable(self, "_on_scene_exit_body_entered").bind(target_scene))
	parent.add_child(area)

func _on_scene_exit_body_entered(body: Node, target_scene: String) -> void:
	if _scene_is_changing:
		return
	if body == null:
		return
	if not body.is_in_group("Player") and body.name != "Player":
		return
	if target_scene == "":
		return

	_scene_is_changing = true
	get_tree().change_scene_to_file(target_scene)
