extends RefCounted

# -------------------------
# Slots / Cooldowns
# -------------------------
func clear_slots(player: Node) -> void:
	player.skills_slots.clear()
	player.skills_cooldowns.clear()
	player.emit_signal("skills_changed")

func apply_loadout(player: Node, list: Array) -> void:
	clear_slots(player)
	for i in range(min(list.size(), int(player.SKILLS_SLOT_COUNT))):
		var skill: Variant = list[i]
		if skill:
			player.skills_slots[i + 1] = skill
	player.emit_signal("skills_changed")

func assign(player: Node, slot: int, skill) -> void:
	if slot < 1 or slot > int(player.SKILLS_SLOT_COUNT):
		return
	player.skills_slots[slot] = skill
	player.skills_cooldowns[slot] = 0.0
	player.skills_changed.emit()

func _bind_slot_action(player: Node, slot: int, skill: Variant) -> void:
	if not (skill is Object):
		return
	var skill_obj: Object = skill as Object
	var slot_action: StringName = StringName("skill_%d" % slot)
	if player._obj_has_property(skill_obj, &"action_name"):
		skill_obj.set("action_name", slot_action)
	elif skill_obj.has_method("set_action_name"):
		skill_obj.call("set_action_name", slot_action)

func use_slot(player: Node, slot: int) -> void:
	if player._movement_locked():
		if is_dash_slot(player, slot):
			player._queued_dash_slot = slot
		return
	if player.is_dashing:
		return
	var skill: Variant = player.skills_slots.get(slot)
	if skill == null:
		return
	if bool(player._skill_in_progress.get(slot, false)):
		return
	if float(player.skills_cooldowns.get(slot, 0.0)) > 0.0:
		return
	if not skill.can_use(player):
		return

	_bind_slot_action(player, slot, skill)

	player._skill_in_progress[slot] = true
	skill.execute(player)
	player._skill_in_progress[slot] = false

	player.skills_cooldowns[slot] = skill.cooldown
	player.skill_used.emit(slot, skill.cooldown)

# -------------------------
# Dash / Dodge Helpers
# -------------------------
func is_dash_slot(player: Node, slot: int) -> bool:
	var skill: Variant = player.skills_slots.get(slot)
	return is_dash_skill(player, skill)

func is_dash_skill(player: Node, skill) -> bool:
	return is_skill_with_keywords(player, skill, PackedStringArray(["dash"]))

func is_skill_with_keywords(player: Node, skill, keywords: PackedStringArray) -> bool:
	if skill == null:
		return false
	if skill is Object:
		var skill_obj: Object = skill as Object
		var script_obj: Variant = skill_obj.get_script()
		if script_obj is Script:
			var path: String = String((script_obj as Script).resource_path).to_lower()
			for keyword in keywords:
				if path.find("%sskill.gd" % keyword) != -1:
					return true
		if player._obj_has_property(skill_obj, &"id"):
			var skill_id: String = String(skill_obj.get("id")).to_lower()
			for keyword in keywords:
				if skill_id.find(keyword) != -1:
					return true
		if player._obj_has_property(skill_obj, &"title"):
			var title: String = String(skill_obj.get("title")).to_lower()
			for keyword in keywords:
				if title.find(keyword) != -1:
					return true
	return false

func get_dodge_skill_from_db(player: Node) -> Skill:
	var db: Node = get_skills_db(player)
	if db == null or not db.has_method("get_skill"):
		return null
	var skill: Variant = db.call("get_skill", StringName("Dodge"))
	if skill is Skill:
		return skill as Skill
	return null

func try_use_dodge_action(player: Node) -> void:
	if player._movement_locked() or player.is_dashing:
		return
	var skill: Skill = get_dodge_skill_from_db(player)
	if skill == null:
		return
	if not skill.can_use(player):
		return
	skill.execute(player)

func try_consume_queued_dash(player: Node) -> void:
	if int(player._queued_dash_slot) <= 0:
		return
	if player._movement_locked() or player.is_dashing:
		return
	var slot: int = int(player._queued_dash_slot)
	player._queued_dash_slot = 0
	use_slot(player, slot)

# -------------------------
# Equipment / DB
# -------------------------
func process_cooldowns(player: Node, delta: float) -> void:
	for slot in player.skills_cooldowns.keys():
		if float(player.skills_cooldowns[slot]) > 0.0:
			player.skills_cooldowns[slot] = max(0.0, float(player.skills_cooldowns[slot]) - delta)
			if float(player.skills_cooldowns[slot]) == 0.0:
				player.skill_ready.emit(slot)

func equip_skill(player: Node, slot: int, skill) -> void:
	if slot < 1 or slot > int(player.SKILLS_SLOT_COUNT):
		return
	if skill == null:
		return

	for key in player.skills_slots.keys():
		var other: Variant = player.skills_slots.get(key)
		if key != slot and other and "id" in other and "id" in skill and other.id == skill.id:
			push_warning("Skill already equipped in slot %d" % key)
			return

	player.skills_slots[slot] = skill
	player.skills_cooldowns[slot] = 0.0
	player.skills_changed.emit()

func equip_skill_by_id(player: Node, slot_index: int, skill_id: StringName) -> void:
	if slot_index < 1 or slot_index > int(player.SKILLS_SLOT_COUNT):
		return

	var db: Node = get_skills_db(player)
	if db == null or not db.has_method("get_skill"):
		push_error("[Player] SkillsDB autoload not found")
		return

	var skill: Variant = db.get_skill(skill_id)
	if skill == null:
		push_error("[Player] skill id not found: %s" % String(skill_id))
		return

	player.skills_slots[slot_index] = skill
	player.skills_cooldowns[slot_index] = 0.0
	player.skills_changed.emit()
	print("[Player] equipped slot %d -> %s" % [slot_index, skill.title])

func get_skills_db(player: Node) -> Node:
	for path in player.SKILLS_DB_PATHS:
		var node: Node = player.get_node_or_null(path)
		if node:
			return node
	return null
