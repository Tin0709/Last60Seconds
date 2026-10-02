extends Node2D

var time_remaining: float = 60.0
var game_ended: bool = false

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

func end_game(message: String) -> void:
	if game_ended:
		return
	game_ended = true
	survived_label.text = message
	survived_label.show()
	set_process(false)
	$Player.set_physics_process(false)
	$Enemy.set_physics_process(false)
	$Player.velocity = Vector2.ZERO
	$Enemy.velocity = Vector2.ZERO
