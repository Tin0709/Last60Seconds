extends AnimatedSprite2D

@export var directional: bool = true

var facing: String = "down"

func _ready() -> void:
	if not directional:
		facing = "side"
	play("idle_" + facing)

func _process(_delta: float) -> void:
	var body: CharacterBody2D = get_parent()
	var movement = body.get_real_velocity() if body.is_physics_processing() else Vector2.ZERO
	var moving = movement.length_squared() > 1.0
	if moving:
		if not directional or absf(movement.x) > absf(movement.y):
			facing = "side"
			if absf(movement.x) > 1.0:
				flip_h = movement.x < 0.0
		else:
			facing = "up" if movement.y < 0.0 else "down"
			flip_h = false
	play(("run_" if moving else "idle_") + facing)
