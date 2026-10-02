extends Node2D

const HOVER_SOUNDS = [
	preload("res://assets/audio/ui/rollover1.ogg"),
	preload("res://assets/audio/ui/rollover2.ogg"),
]
const CLICK_SOUNDS = [
	preload("res://assets/audio/ui/click1.ogg"),
	preload("res://assets/audio/ui/click2.ogg"),
	preload("res://assets/audio/ui/click3.ogg"),
]

const ENEMY_VISUALS = [
	preload("res://enemy_frames.tres"),
	preload("res://orc_warrior_frames.tres"),
	preload("res://skeleton_warrior_frames.tres"),
]

@export var world_bounds: Rect2 = Rect2(0, 0, 3200, 2240)

var time_remaining: float = 60.0
var game_ended: bool = false
var spawn_time_remaining: float = 5.0
var audio_rng = RandomNumberGenerator.new()
var enemy_template: CharacterBody2D

@onready var time_label: Label = $HUD/TimeLabel
@onready var survived_label: Label = $HUD/SurvivedLabel
@onready var health_display: Control = $HUD/HealthDisplay

func _ready() -> void:
	# Keep a live-spawn template even after the original enemy is defeated.
	enemy_template = $Enemy.duplicate()
	audio_rng.randomize()
	$HUD/RestartButton.mouse_entered.connect(_on_restart_button_hovered)
	$Player.world_bounds = world_bounds
	var camera: Camera2D = $Player/Camera2D
	camera.limit_left = int(world_bounds.position.x)
	camera.limit_top = int(world_bounds.position.y)
	camera.limit_right = int(world_bounds.end.x)
	camera.limit_bottom = int(world_bounds.end.y)
	$Player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed($Player.health)

func _on_player_health_changed(health: int) -> void:
	health_display.health = health
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
	var radius: float = enemy_template.get_node("CollisionShape2D").shape.radius
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
		var enemy = enemy_template.duplicate()
		enemy.get_node("AnimatedSprite2D").sprite_frames = ENEMY_VISUALS.pick_random()
		enemy.position = to_local(spawn_position)
		add_child(enemy)
		return

func end_game(message: String) -> void:
	if game_ended:
		return
	game_ended = true
	$PauseMenu.set_paused(false)
	survived_label.text = message
	survived_label.show()
	$HUD/RestartButton.show()
	set_process(false)
	$Player.set_physics_process(false)
	$Player.velocity = Vector2.ZERO
	$Player.stop_footsteps()
	$Player/Sword.cancel_attack()
	$Player/Gun.stop_combat()
	$Player/HealSound.stop()
	$Player/PickupSound.stop()
	for bullet in get_tree().get_nodes_in_group("bullets"):
		bullet.spent = true
		bullet.queue_free()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.velocity = Vector2.ZERO

func _on_restart_button_hovered() -> void:
	$UISound.stream = HOVER_SOUNDS[audio_rng.randi_range(0, HOVER_SOUNDS.size() - 1)]
	$UISound.play()

func _exit_tree() -> void:
	if is_instance_valid(enemy_template):
		enemy_template.free()

func play_ui_click() -> void:
	$UISound.stream = CLICK_SOUNDS[audio_rng.randi_range(0, CLICK_SOUNDS.size() - 1)]
	$UISound.play()

func _on_restart_button_pressed() -> void:
	$PauseMenu.set_paused(false)
	# Let the short click finish across the immediate scene reload.
	var sound: AudioStreamPlayer = $UISound
	sound.stream = CLICK_SOUNDS[audio_rng.randi_range(0, CLICK_SOUNDS.size() - 1)]
	sound.reparent(get_tree().root)
	sound.finished.connect(sound.queue_free)
	sound.play()
	get_tree().reload_current_scene()
