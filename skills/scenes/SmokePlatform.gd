extends StaticBody2D
class_name SmokePlatform

@export var duration: float = 2.0
@export var fade_time: float = 0.25
@export var one_way_margin: float = 6.0
@export var use_world_layer: bool = true  # ставить на World (бит 1)

var _sprite: Sprite2D = null
var _col: CollisionShape2D = null
var _animp: AnimationPlayer = null
var _aspr: AnimatedSprite2D = null

func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_animp = get_node_or_null("AnimationPlayer") as AnimationPlayer
	_aspr = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if _col:
		_col.one_way_collision = true
		_col.one_way_collision_margin = one_way_margin

	# Слой по умолчанию — World (бит 1)
	if use_world_layer:
		collision_layer = 1  # только World

	# Автовоспроизведение анимации
	if _animp:
		if _animp.has_animation("default"):
			_animp.play("default")
		elif _animp.get_animation_list().size() > 0:
			_animp.play(_animp.get_animation_list()[0])
	elif _aspr:
		# если есть анимация "default", попробуем ее; иначе просто play()
		if _aspr.sprite_frames and _aspr.sprite_frames.has_animation("default"):
			_aspr.play("default")
		else:
			_aspr.play()

	var live_time: float = max(0.0, duration - fade_time)
	await get_tree().create_timer(live_time).timeout
	_start_fade_and_free()

func _start_fade_and_free() -> void:
	if _col:
		_col.disabled = true
	# Плавный фейд спрайта (если есть)
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate:a", 0.0, fade_time)
		await tw.finished
	queue_free()

# rect_size — W×H; layer_bitmask — уже битовая маска (например 1 для World)
func configure(rect_size: Vector2, dur: float, layer_bitmask: int = 1) -> void:
	duration = dur
	if _col and _col.shape is RectangleShape2D:
		(_col.shape as RectangleShape2D).size = rect_size
	collision_layer = layer_bitmask
