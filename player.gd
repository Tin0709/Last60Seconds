extends CharacterBody2D

@export var speed: float = 300.0
@export var player_radius: float = 20.0

func _physics_process(_delta):
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = direction * speed
	move_and_slide()

	keep_inside_screen()


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
