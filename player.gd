extends CharacterBody2D

signal health_changed(health: int)

@export var speed: float = 300.0
@export var player_radius: float = 20.0

var health: int = 3
var world_bounds: Rect2
var damage_cooldown: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_time_remaining: float = 0.0

func _physics_process(delta):
	damage_cooldown = maxf(damage_cooldown - delta, 0.0)
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = direction * speed
	if knockback_time_remaining > 0.0:
		velocity = knockback_direction * 400.0
		knockback_time_remaining = maxf(knockback_time_remaining - delta, 0.0)
	move_and_slide()

	keep_inside_world()


func take_damage(enemy_position: Vector2) -> void:
	if damage_cooldown > 0.0 or health <= 0:
		return
	health -= 1
	damage_cooldown = 1.0
	knockback_direction = enemy_position.direction_to(global_position)
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.RIGHT
	knockback_time_remaining = 0.12
	health_changed.emit(health)


func keep_inside_world():

	global_position.x = clampf(
		global_position.x,
		world_bounds.position.x + player_radius,
		world_bounds.end.x - player_radius
	)

	global_position.y = clampf(
		global_position.y,
		world_bounds.position.y + player_radius,
		world_bounds.end.y - player_radius
	)
