extends CharacterBody2D

const SPEED = 80.0
const JUMP_VELOCITY = -400.0

var direction := 1
var state := "idle"

# Гравитация из настроек проекта
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var max_hp: int = 2
@export var knockback_friction: float = 600.0  # чем больше, тем быстрее гасится нокбэк

var hp: int
var knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	hp = max_hp
	add_to_group("Enemy")

func _physics_process(delta: float) -> void:
	# ===== НОКБЭК ИМЕЕТ ПРИОРИТЕТ =====
	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		# Плавно гасим отдачу
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

		# Анимации во время нокбэка
		if velocity.y > 0:
			$AnimatedSprite2D.play("fall")
		else:
			# если есть клип "hit" — можно сыграть его; иначе используем "jump"
			if $AnimatedSprite2D.sprite_frames and $AnimatedSprite2D.sprite_frames.has_animation("hit"):
				$AnimatedSprite2D.play("hit")
			else:
				$AnimatedSprite2D.play("jump")

	else:
		# ===== ТВОЯ БАЗОВАЯ ЛОГИКА =====
		if is_on_floor():
			# stop if is on the floor
			velocity.x = 0
			$AnimatedSprite2D.play("idle")
		else:
			# Add the gravity and move horizontally if in air.
			velocity.x = direction * SPEED
			velocity.y += gravity * delta
			if velocity.y > 0:
				$AnimatedSprite2D.play("fall")
			else:
				$AnimatedSprite2D.play("jump")

	move_and_slide()

	# flip sprite (ориентируемся по направлению; при нокбэке — по текущей скорости)
	if knockback_velocity.length() > 1.0:
		$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		$AnimatedSprite2D.flip_h = direction > 0

func jump() -> void:
	velocity.y = JUMP_VELOCITY

func _on_timer_timeout() -> void:
	# when timer finish, change direction and jump
	direction *= -1
	jump()

func apply_damage(dmg: int, kb: Vector2, source_pos: Vector2) -> void:
	hp -= max(0, dmg)
	knockback_velocity = kb
	if hp <= 0:
		die()

func die() -> void:
	queue_free()
