extends Node

const SKILLS_DB_PATH: String = "/root/SkillsDB"
const DEFAULT_SLOT_COUNT: int = 4

@export var enabled: bool = true
@export var preset_name: String = "combo_mix"
@export var apply_delay_frames: int = 1

func has_active_preset() -> bool:
	return enabled and not preset_name.is_empty()

func get_preset(slot_count: int) -> Array:
	if not enabled or preset_name.is_empty():
		return []

	var db: Node = get_node_or_null(SKILLS_DB_PATH)
	if db == null or not db.has_method("get_skill"):
		push_warning("[DevLoadout] SkillsDB autoload not found")
		return []

	var skill_ids: PackedStringArray = _preset_ids(preset_name)
	if skill_ids.is_empty():
		push_warning("[DevLoadout] Unknown preset: %s" % preset_name)
		return []

	var result: Array = []
	for i in range(min(slot_count, skill_ids.size())):
		var skill_id: StringName = StringName(skill_ids[i])
		var skill: Variant = db.call("get_skill", skill_id)
		if skill != null:
			result.append(skill)
	return result

func apply_to_player(p: Node) -> void:
	if not enabled or p == null or not p.has_method("skills_apply_loadout"):
		return

	var slot_count: int = DEFAULT_SLOT_COUNT
	var list: Array = get_preset(slot_count)
	if list.is_empty():
		return
	p.skills_apply_loadout(list)

func safe_apply_later(p: Node) -> void:
	if not enabled:
		return
	for i in range(apply_delay_frames):
		await get_tree().process_frame
	apply_to_player(p)

func _preset_ids(name: String) -> PackedStringArray:
	match name:
		"combo_mix":
			return PackedStringArray([
				"Molotov Throw",
				"Vomit",
				"Dash",
				"Smoke",
			])
		_:
			return PackedStringArray()
