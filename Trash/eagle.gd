extends Area2D

@onready var collision_shape = $CollisionShape2D

func _ready():
	# Подключаем сигнал
	connect("body_entered", Callable(self, "_on_gem_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.max_jumps = 2
		body.jumps_left = 2
		queue_free()
