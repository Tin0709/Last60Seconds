extends CharacterBody2D

@export var speed: float = 120.0

var recoil_direction: Vector2 = Vector2.ZERO
var recoil_time_remaining: float = 0.0

@onready var player: Node2D = (
	get_tree().get_first_node_in_group("player") as Node2D
)

func _physics_process(delta):
	if player == null:
		return
	if recoil_time_remaining > 0.0:
		recoil_time_remaining = maxf(recoil_time_remaining - delta, 0.0)
		velocity = recoil_direction * 220.0
		move_and_slide()
		return

	var direction = global_position.direction_to(
		player.global_position
	)

	velocity = direction * speed

	move_and_slide()

	# Deep overlaps can be recovered without a reported slide collision.
	var contact_radius: float = player.player_radius + $CollisionShape2D.shape.radius
	var touching_player = global_position.distance_squared_to(player.global_position) < contact_radius * contact_radius
	for index in range(get_slide_collision_count()):
		if get_slide_collision(index).get_collider() == player:
			touching_player = true
			break
	if touching_player and player.take_damage(global_position) and is_physics_processing():
		# Recoil only on an accepted hit, including a safe fallback for overlap.
		recoil_direction = -player.knockback_direction
		recoil_time_remaining = 0.3
		velocity = recoil_direction * 220.0
		move_and_collide(recoil_direction * 12.0)
