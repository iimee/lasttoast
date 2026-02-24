extends Node

const ItemDB = preload("res://db/ItemDB.gd")

# Можно задать путь до Player через инспектор (в каждой сцене свой)
@export var player_path: NodePath

# UI-лейблы
var full_bottle_label: Label = null
var empty_bottle_label: Label = null
var cig_pack_label: Label = null
var inebriation_label: Label = null
var nicotine_label: Label = null

var player: Node = null
var skill_menu: Control = null

func _ready() -> void:
	# --- UI-лейблы ---
	full_bottle_label   = get_node_or_null("UI/FullBottleLabel") as Label
	empty_bottle_label  = get_node_or_null("UI/EmptyBottleLabel") as Label
	cig_pack_label      = get_node_or_null("UI/CigPackLabel") as Label
	inebriation_label   = get_node_or_null("UI/InebriationLabel") as Label
	nicotine_label      = get_node_or_null("UI/NicotineLabel") as Label

	# --- Игрок ---
	player = _resolve_player()
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
	if n.is_in_group("bottle"):
		_connect_bottle(n)
	if n.is_in_group("cigarette"):
		_connect_cigarette(n)

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
		full_bottle_label.text = "Full Bottles: %d" % v

func _update_empty_bottle_label(v: int) -> void:
	if empty_bottle_label:
		empty_bottle_label.text = "Empty Bottles: %d" % v

func _update_cig_pack_label(v: int) -> void:
	if cig_pack_label:
		cig_pack_label.text = "Cig Packs: %d" % v

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
		inebriation_label.text = "Inebriation: %d" % v

func _update_nicotine_label(v: int) -> void:
	if nicotine_label:
		nicotine_label.text = "Nicotine: %d" % v

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
