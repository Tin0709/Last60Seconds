extends CanvasLayer

@onready var game: Node2D = get_parent()
@onready var overlay: Control = $Overlay

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Overlay/Center/Panel.add_theme_stylebox_override("panel", preload("res://ui_theme.tres").get_stylebox("normal", "Label"))
	$Overlay/Center/Panel/Buttons/Resume.pressed.connect(_resume)
	$Overlay/Center/Panel/Buttons/Restart.pressed.connect(game._on_restart_button_pressed)
	for button in [$Overlay/Center/Panel/Buttons/Resume, $Overlay/Center/Panel/Buttons/Restart]:
		button.mouse_entered.connect(game._on_restart_button_hovered)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo() and not game.game_ended:
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()

func set_paused(paused: bool) -> void:
	if paused and game.game_ended:
		return
	get_tree().paused = paused
	overlay.visible = paused

func _resume() -> void:
	game.play_ui_click()
	set_paused(false)
