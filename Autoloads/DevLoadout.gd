extends Node

@export var enabled: bool = true           # выкл в билдах
@export var preset_name: String = "combo_mix"
@export var apply_delay_frames: int = 1    # чтобы SkillsDB успел загрузиться
@export var respect_unlocked_only: bool = false  # true — ставить только те, что уже открыты

func get_preset(slot_count: int) -> Array[Skill]:
	# дерни базу
	var db := get_node_or_null("/root/db/SkillsDB")
	if db == null:
		push_warning("[DevLoadout] SkillsDB not found")
		return []
	# используй уже предложенные утилиты из SkillsDB:
	# db.preset_loadout(name, slot_count)
	return db.preset_loadout(preset_name, slot_count)

func apply_to_player(p: Node) -> void:
	if not enabled: return
	if not p.has_method("skills_apply_loadout"): return
	var list := get_preset(p.SKILLS_SLOT_COUNT)
	if respect_unlocked_only and p.has_method("filter_unlocked_skills"):
		list = p.filter_unlocked_skills(list)
	p.skills_apply_loadout(list)

func safe_apply_later(p: Node) -> void:
	if not enabled: return
	# даём кадр/два, чтобы ресурсы базы успели прогрузиться
	for i in range(apply_delay_frames):
		await get_tree().process_frame
	apply_to_player(p)
