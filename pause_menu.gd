extends CanvasLayer

@onready var game: Node2D = get_parent()
@onready var overlay: Control = $Overlay

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Overlay/Center/Panel.add_theme_stylebox_override("panel", preload("res://ui_theme.tres").get_stylebox("normal", "Label"))
	$Overlay/Center/Panel/Buttons/Resume.pressed.connect(_resume)
	$Overlay/Center/Panel/Buttons/Restart.pressed.connect(game._on_restart_button_pressed)
	$Overlay/Center/Panel/Buttons/ModeSelect.pressed.connect(game.return_to_mode_select)
	for button in [$Overlay/Center/Panel/Buttons/Resume, $Overlay/Center/Panel/Buttons/Restart, $Overlay/Center/Panel/Buttons/ModeSelect]:
		button.mouse_entered.connect(game._on_restart_button_hovered)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo() and game.run_active and not game.game_ended:
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()

func set_paused(paused: bool) -> void:
	if paused and (game.game_ended or not game.run_active):
		return
	get_tree().paused = paused
	overlay.visible = paused
	if paused:
		game.get_node("Player").clear_weapon_prompt()

func _resume() -> void:
	game.play_ui_click()
	set_paused(false)
