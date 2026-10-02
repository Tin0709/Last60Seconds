extends CharacterBody2D

signal health_changed(health: int)

@export var speed: float = 300.0
@export var player_radius: float = 20.0

var health: int = 5
var world_bounds: Rect2
var damage_cooldown: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_time_remaining: float = 0.0

func _physics_process(delta):
	damage_cooldown = maxf(damage_cooldown - delta, 0.0)
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = direction * speed
	if knockback_time_remaining > 0.0:
		velocity = knockback_direction * 400.0
		knockback_time_remaining = maxf(knockback_time_remaining - delta, 0.0)
	move_and_slide()

	keep_inside_world()


func take_damage(enemy_position: Vector2) -> bool:
	if damage_cooldown > 0.0 or health <= 0:
		return false
	health -= 1
	damage_cooldown = 1.0
	knockback_direction = enemy_position.direction_to(global_position)
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.RIGHT
	knockback_time_remaining = 0.12
	show_hit_feedback()
	health_changed.emit(health)
	return true


func show_hit_feedback() -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	sprite.modulate = Color(1.0, 0.35, 0.35)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)

	var feedback = Label.new()
	feedback.text = "-1 heart"
	feedback.theme = preload("res://ui_theme.tres")
	feedback.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	feedback.add_theme_font_size_override("font_size", 18)
	feedback.add_theme_color_override("font_color", Color("ffb6a3"))
	feedback.add_theme_color_override("font_outline_color", Color("171e16"))
	feedback.add_theme_constant_override("outline_size", 4)
	feedback.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.z_index = 10
	get_parent().add_child(feedback)
	feedback.global_position = global_position + Vector2(-feedback.get_minimum_size().x / 2.0, -64)
	var tween = feedback.create_tween().set_parallel(true)
	tween.tween_property(feedback, "position:y", feedback.position.y - 30.0, 0.65)
	tween.tween_property(feedback, "modulate:a", 0.0, 0.35).set_delay(0.3)
	tween.chain().tween_callback(feedback.queue_free)


func keep_inside_world():

	global_position.x = clampf(
		global_position.x,
		world_bounds.position.x + player_radius,
		world_bounds.end.x - player_radius
	)

	global_position.y = clampf(
		global_position.y,
		world_bounds.position.y + player_radius,
		world_bounds.end.y - player_radius
	)
