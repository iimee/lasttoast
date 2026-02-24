extends Control
class_name SkillSelectMenu

signal skill_chosen(skill_id: StringName)
signal equip_requested(slot_index: int, skill_id: StringName)			# совместимость (battle)
signal equip_to_group(group: StringName, slot_index: int, skill_id: StringName)

const ICON_SIZE := Vector2i(48, 48)
const SLOT_COUNT_BATTLE := 4
const SLOT_COUNT_UTILITY := 3
const BRANCH_KEYS := ["alcohol", "cigarette", "combo", "bag"]

@onready var DB = get_node("/root/SkillsDB")

var _branch_grids: Dictionary = {}	# key -> GridContainer
var _info: RichTextLabel
var _equip_btn: Button

var _battle_btns: Array[Button] = []
var _utility_btns: Array[Button] = []

var _current_group: StringName = "battle"	# "battle" | "utility"
var _current_slot: int = 1					# 1..N
var _selected_skill_id: StringName

func _ready() -> void:
	hide()
	_build_ui()
	if DB and DB.has_signal("db_ready"):
		DB.db_ready.connect(_fill)
	_fill()

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var root := HBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	# --------- ЛЕВЫЙ БЛОК: 4 СТОЛБЦА ----------
	var left := HBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	root.add_child(left)

	for key in BRANCH_KEYS:
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(180, 0)
		col.size_flags_vertical = Control.SIZE_EXPAND_FILL
		left.add_child(col)

		var title := Label.new()
		title.text = _branch_title(key)
		title.add_theme_font_size_override("font_size", 22)
		col.add_child(title)

		var grid := GridContainer.new()
		grid.columns = 1
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(grid)

		_branch_grids[key] = grid

	# разделитель между зонами
	var sep := VSeparator.new()
	root.add_child(sep)

	# --------- ПРАВЫЙ БЛОК: слоты + описание + Equip ----------
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(300, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	root.add_child(right)

	var h1 := Label.new()
	h1.text = "Battle Slots"
	h1.add_theme_font_size_override("font_size", 20)
	right.add_child(h1)

	var row_b := HBoxContainer.new()
	row_b.add_theme_constant_override("separation", 8)
	right.add_child(row_b)

	_battle_btns.clear()
	for i in SLOT_COUNT_BATTLE:
		var b := Button.new()
		b.text = str(i + 1)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(64, 56)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var idx := i + 1
		b.pressed.connect(func():
			_select_group_and_slot("battle", idx))
		_battle_btns.append(b)
		row_b.add_child(b)

	var h2 := Label.new()
	h2.text = "Utility Slots"
	h2.add_theme_font_size_override("font_size", 20)
	right.add_child(h2)

	var row_u := HBoxContainer.new()
	row_u.add_theme_constant_override("separation", 8)
	right.add_child(row_u)

	_utility_btns.clear()
	for i in SLOT_COUNT_UTILITY:
		var u := Button.new()
		u.text = str(i + 1)
		u.toggle_mode = true
		u.focus_mode = Control.FOCUS_NONE
		u.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		u.custom_minimum_size = Vector2(64, 56)
		u.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var idxu := i + 1
		u.pressed.connect(func():
			_select_group_and_slot("utility", idxu))
		_utility_btns.append(u)
		row_u.add_child(u)

	# по умолчанию — battle slot 1
	call_deferred("_select_group_and_slot", "battle", 1)

	# Описание
	_info = RichTextLabel.new()
	_info.fit_content = true
	_info.scroll_active = false
	_info.custom_minimum_size = Vector2(0, 160)
	right.add_child(_info)

	# Equip
	_equip_btn = Button.new()
	_equip_btn.text = "Equip Slot"
	_equip_btn.focus_mode = Control.FOCUS_NONE
	_equip_btn.disabled = true
	_equip_btn.pressed.connect(_on_equip_pressed)
	right.add_child(_equip_btn)

func _fill() -> void:
	if DB == null:
		return
	for key in BRANCH_KEYS:
		var grid: GridContainer = _branch_grids.get(key, null)
		if grid == null:
			continue
		for c in grid.get_children():
			c.queue_free()
		var arr: Array = DB.get_by_branch(key)
		for s in arr:
			if s is Skill:
				grid.add_child(_make_skill_button(s))

func _make_skill_button(s: Skill) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(160, 44)
	b.text = s.title
	if s.icon:
		b.icon = s.icon
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		_selected_skill_id = s.id
		_info.text = "[b]%s[/b]\nCooldown: %.2f" % [s.title, s.cooldown]
		_equip_btn.disabled = false
		skill_chosen.emit(s.id)
	)
	return b

func _select_group_and_slot(group: StringName, slot_num: int) -> void:
	_current_group = group
	_current_slot = slot_num
	for i in _battle_btns.size():
		_battle_btns[i].button_pressed = (group == "battle" and i + 1 == slot_num)
	for i in _utility_btns.size():
		_utility_btns[i].button_pressed = (group == "utility" and i + 1 == slot_num)

func _on_equip_pressed() -> void:
	if _selected_skill_id == StringName():
		return
	_set_slot_skill_by_id(_current_group, _current_slot, _selected_skill_id)
	if _current_group == "battle":
		equip_requested.emit(_current_slot, _selected_skill_id)
	equip_to_group.emit(_current_group, _current_slot, _selected_skill_id)

# ---------- ПУБЛИЧНЫЕ МЕТОДЫ ----------
func set_slot_skill_by_id(group: StringName, slot_index: int, skill_id: StringName) -> void:
	_set_slot_skill_by_id(group, slot_index, skill_id)

func set_slot_skill(group: StringName, slot_index: int, skill: Skill) -> void:
	_set_slot_skill(group, slot_index, skill)

# ---------- ВНУТРЕННИЕ ----------
func _set_slot_skill_by_id(group: StringName, slot_index: int, skill_id: StringName) -> void:
	var s: Skill = DB.get_skill(skill_id) as Skill
	if s != null:
		_set_slot_skill(group, slot_index, s)
	else:
		_clear_slot_icon(group, slot_index)

func _set_slot_skill(group: StringName, slot_index: int, s: Skill) -> void:
	var btn := _get_slot_button(group, slot_index)
	if btn == null:
		return
	btn.icon = s.icon
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.text = ""
	btn.tooltip_text = s.title

func _clear_slot_icon(group: StringName, slot_index: int) -> void:
	var btn := _get_slot_button(group, slot_index)
	if btn == null:
		return
	btn.icon = null
	btn.text = str(slot_index)
	btn.tooltip_text = ""

func _get_slot_button(group: StringName, slot_index: int) -> Button:
	if group == "battle":
		if slot_index >= 1 and slot_index <= _battle_btns.size():
			return _battle_btns[slot_index - 1]
		else:
			return null
	else:
		if slot_index >= 1 and slot_index <= _utility_btns.size():
			return _utility_btns[slot_index - 1]
		else:
			return null

func _branch_title(key: String) -> String:
	if DB and DB.has_method("get_branch_title"):
		return DB.get_branch_title(key)
	return key.capitalize()
