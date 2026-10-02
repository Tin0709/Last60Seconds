extends Node2D

@export var world_bounds: Rect2 = Rect2(0, 0, 2400, 1600)

var time_remaining: float = 60.0
var game_ended: bool = false
var spawn_time_remaining: float = 5.0

@onready var time_label: Label = $HUD/TimeLabel
@onready var survived_label: Label = $HUD/SurvivedLabel
@onready var health_label: Label = $HUD/HealthLabel

func _ready() -> void:
	$Player.world_bounds = world_bounds
	var camera: Camera2D = $Player/Camera2D
	camera.limit_left = int(world_bounds.position.x)
	camera.limit_top = int(world_bounds.position.y)
	camera.limit_right = int(world_bounds.end.x)
	camera.limit_bottom = int(world_bounds.end.y)
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
		var progress: float = clampf(1.0 - time_remaining / 60.0, 0.0, 1.0)
		spawn_time_remaining = lerpf(5.0, 2.0, progress)

func spawn_enemy() -> void:
	var radius: float = $Enemy/CollisionShape2D.shape.radius
	var spawn_bounds = world_bounds.grow(-radius)
	for attempt in range(8):
		var spawn_position: Vector2
		match randi_range(0, 3):
			0:
				spawn_position = Vector2(spawn_bounds.position.x, randf_range(spawn_bounds.position.y, spawn_bounds.end.y))
			1:
				spawn_position = Vector2(spawn_bounds.end.x, randf_range(spawn_bounds.position.y, spawn_bounds.end.y))
			2:
				spawn_position = Vector2(randf_range(spawn_bounds.position.x, spawn_bounds.end.x), spawn_bounds.position.y)
			3:
				spawn_position = Vector2(randf_range(spawn_bounds.position.x, spawn_bounds.end.x), spawn_bounds.end.y)
		if spawn_position.distance_to($Player.global_position) < 100.0:
			continue
		var enemy = $Enemy.duplicate()
		add_child(enemy)
		enemy.global_position = spawn_position
		return

func end_game(message: String) -> void:
	if game_ended:
		return
	game_ended = true
	survived_label.text = message
	survived_label.show()
	$HUD/RestartButton.show()
	set_process(false)
	$Player.set_physics_process(false)
	$Player.velocity = Vector2.ZERO
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.velocity = Vector2.ZERO

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
