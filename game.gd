extends Node2D

var time_remaining: float = 60.0
var game_ended: bool = false
var spawn_time_remaining: float = 5.0

@onready var time_label: Label = $HUD/TimeLabel
@onready var survived_label: Label = $HUD/SurvivedLabel
@onready var health_label: Label = $HUD/HealthLabel

func _ready() -> void:
	$Player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed($Player.health)

func _on_player_health_changed(health: int) -> void:
	health_label.text = "Health: %d" % health
	if health == 0:
		end_game("GAME OVER")

func _process(delta: float) -> void:
	if game_ended:
		return
	time_remaining = maxf(time_remaining - delta, 0.0)
	time_label.text = "Time: %d" % ceili(time_remaining)

	if time_remaining == 0.0:
		end_game("SURVIVED")
		return

	spawn_time_remaining -= delta
	if spawn_time_remaining <= 0.0:
		spawn_enemy()
		spawn_time_remaining = 5.0

func spawn_enemy() -> void:
	var screen_size = get_viewport_rect().size
	var radius: float = $Enemy/CollisionShape2D.shape.radius
	for attempt in range(8):
		var spawn_position: Vector2
		match randi_range(0, 3):
			0:
				spawn_position = Vector2(radius, randf_range(radius, screen_size.y - radius))
			1:
				spawn_position = Vector2(screen_size.x - radius, randf_range(radius, screen_size.y - radius))
			2:
				spawn_position = Vector2(randf_range(radius, screen_size.x - radius), radius)
			3:
				spawn_position = Vector2(randf_range(radius, screen_size.x - radius), screen_size.y - radius)
		if spawn_position.distance_to($Player.position) < 100.0:
			continue
		var enemy = $Enemy.duplicate()
		enemy.position = spawn_position
		add_child(enemy)
		return

func end_game(message: String) -> void:
	if game_ended:
		return
	game_ended = true
	survived_label.text = message
	survived_label.show()
	set_process(false)
	$Player.set_physics_process(false)
	$Player.velocity = Vector2.ZERO
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.velocity = Vector2.ZERO
