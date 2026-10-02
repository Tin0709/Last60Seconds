extends CharacterBody2D

signal health_changed(health: int)

@export var speed: float = 300.0
@export var player_radius: float = 20.0

var health: int = 3
var damage_cooldown: float = 0.0

func _physics_process(delta):
	damage_cooldown = maxf(damage_cooldown - delta, 0.0)
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = direction * speed
	move_and_slide()

	keep_inside_screen()


func take_damage() -> void:
	if damage_cooldown > 0.0 or health <= 0:
		return
	health -= 1
	damage_cooldown = 1.0
	health_changed.emit(health)


func keep_inside_screen():
	var screen_size = get_viewport_rect().size

	position.x = clamp(
		position.x,
		player_radius,
		screen_size.x - player_radius
	)

	position.y = clamp(
		position.y,
		player_radius,
		screen_size.y - player_radius
	)
