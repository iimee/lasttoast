# res://db/SkillsDB.gd
extends Node
# Простая база умений (autoload).
# Порядок — только по sort_key (export в Skill.gd).

signal db_ready

const SKILLS_PATH: String = "res://skills/impl"

var by_id: Dictionary = {}      # id:StringName -> Skill
var all: Array = []             # все скиллы
var by_branch: Dictionary = {}  # branch:StringName -> Array[Skill]

func _ready() -> void:
	reload()

func reload() -> void:
	by_id.clear()
	all.clear()
	by_branch.clear()
	_scan_dir(SKILLS_PATH)

	all.sort_custom(_cmp_sort_key)
	for br in by_branch.keys():
		var arr: Array = by_branch[br]
		arr.sort_custom(_cmp_sort_key)
		by_branch[br] = arr

	db_ready.emit()

# ---------- Загрузка ----------

func _scan_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("[SkillsDB] Can't open %s" % path)
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var full: String = path + "/" + name
		if dir.current_is_dir():
			_scan_dir(full)
		elif name.ends_with(".tres") or name.ends_with(".res"):
			var res: Resource = ResourceLoader.load(full)
			if res is Skill:
				var s: Skill = res
				all.append(s)
				if s.id != StringName():
					by_id[s.id] = s
				var br: StringName = _branch_from_path(full)
				if not by_branch.has(br):
					by_branch[br] = []
				by_branch[br].append(s)
	dir.list_dir_end()

# ---------- API ----------

func get_skill(id: StringName):
	return by_id.get(id)

func get_branches() -> Array:
	var keys: Array = by_branch.keys()
	keys.sort()
	return keys

func get_by_branch(branch: StringName) -> Array:
	return by_branch.get(branch, [])

# ---------- Вспомогательное ----------

func _branch_from_path(p: String) -> StringName:
	var parts: PackedStringArray = p.split("/")
	for i in range(parts.size()):
		if parts[i] == "impl" and i + 1 < parts.size():
			return StringName(parts[i + 1])
	return StringName("default")

func _get_sort_key(s: Skill) -> int:
	var v = s.get("sort_key")
	return int(v) if typeof(v) == TYPE_INT else 0

func _cmp_sort_key(a: Skill, b: Skill) -> bool:
	var ka := _get_sort_key(a)
	var kb := _get_sort_key(b)
	if ka != kb:
		return ka < kb
	return String(a.id) < String(b.id)  # стабильный тай-брейк
