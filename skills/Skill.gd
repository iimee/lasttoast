extends Resource
class_name Skill

@export var id: StringName
@export var title := "Skill"
@export var icon: Texture2D
@export var cooldown := 0.35
@export var sort_key: int = 0
@export var anim_on_execute: StringName = &""   # например, &"throw"

func can_use(user: Node) -> bool: return true
func execute(user: Node) -> void:
	push_warning("%s has no execute()" % title)
