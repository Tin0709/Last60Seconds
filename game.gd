extends Node2D

var time_remaining: float = 60.0

@onready var time_label: Label = $HUD/TimeLabel
@onready var survived_label: Label = $HUD/SurvivedLabel

func _process(delta: float) -> void:
	time_remaining = maxf(time_remaining - delta, 0.0)
	time_label.text = "Time: %d" % ceili(time_remaining)

	if time_remaining == 0.0:
		survived_label.show()
		set_process(false)
