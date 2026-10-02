extends CharacterBody2D

@export var speed: float = 120.0

@onready var player: Node2D = (
	get_tree().get_first_node_in_group("player") as Node2D
)

func _physics_process(_delta):
	if player == null:
		return

	var direction = global_position.direction_to(
		player.global_position
	)

	velocity = direction * speed

	move_and_slide()

	for index in range(get_slide_collision_count()):
		if get_slide_collision(index).get_collider() == player:
			player.take_damage()
			break
