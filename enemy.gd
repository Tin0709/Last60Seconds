extends CharacterBody2D

const DEATH_SHEETS = {
	"res://enemy_frames.tres": preload("res://assets/Pixel Crawler/Entities/Mobs/Orc Crew/Orc - Rogue/Death/Death-Sheet.png"),
	"res://orc_warrior_frames.tres": preload("res://assets/Pixel Crawler/Entities/Mobs/Orc Crew/Orc - Warrior/Death/Death-Sheet.png"),
	"res://skeleton_warrior_frames.tres": preload("res://assets/Pixel Crawler/Entities/Mobs/Skeleton Crew/Skeleton - Mage/Death/Death-Sheet.png"),
}

@export var speed: float = 120.0

var health: float = 5.0
var dead: bool = false
var recoil_direction: Vector2 = Vector2.ZERO
var recoil_time_remaining: float = 0.0

@onready var player: Node2D = (
	get_tree().get_first_node_in_group("player") as Node2D
)

func _physics_process(delta):
	if dead or player == null:
		return
	if recoil_time_remaining > 0.0:
		recoil_time_remaining = maxf(recoil_time_remaining - delta, 0.0)
		velocity = recoil_direction * 220.0
		move_and_slide()
		return

	var direction = global_position.direction_to(
		player.global_position
	)

	velocity = direction * speed

	move_and_slide()

	# Deep overlaps can be recovered without a reported slide collision.
	var contact_radius: float = player.player_radius + $CollisionShape2D.shape.radius
	var touching_player = global_position.distance_squared_to(player.global_position) < contact_radius * contact_radius
	for index in range(get_slide_collision_count()):
		if get_slide_collision(index).get_collider() == player:
			touching_player = true
			break
	if touching_player and player.take_damage(global_position) and is_physics_processing():
		# Recoil only on an accepted hit, including a safe fallback for overlap.
		recoil_direction = -player.knockback_direction
		recoil_time_remaining = 0.3
		velocity = recoil_direction * 220.0
		move_and_collide(recoil_direction * 12.0)

func take_sword_hit(damage: float = -1.0) -> bool:
	return take_hit(damage)

func take_hit(damage: float = -1.0) -> bool:
	var game = get_parent()
	if dead or health <= 0.0 or not game.run_active or game.game_ended or not can_process():
		return false
	var actual_damage = minf(health, game.weapon_damage if damage < 0.0 else damage)
	if actual_damage <= 0.0:
		return false
	health = maxf(health - actual_damage, 0.0)
	game.record_damage(actual_damage)
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	sprite.modulate = Color(1.0, 0.55, 0.4)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.16)
	var feedback = Label.new()
	feedback.text = "-%s ♥" % String.num(actual_damage, 2).trim_suffix(".0")
	feedback.theme = preload("res://ui_theme.tres")
	feedback.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	feedback.add_theme_font_size_override("font_size", 18)
	feedback.add_theme_color_override("font_color", Color("ffddd1"))
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
	if health == 0:
		_die()
	return true

func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	$CollisionShape2D.set_deferred("disabled", true)
	remove_from_group("enemies")
	$Effects.stop_emergence()
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	sprite.set_process(false)
	var sheet: Texture2D = DEATH_SHEETS.get(sprite.sprite_frames.resource_path)
	if sheet == null:
		queue_free()
		return
	var frames = SpriteFrames.new()
	frames.set_animation_loop(&"default", false)
	frames.set_animation_speed(&"default", 10.0)
	var frame_size = Vector2(sheet.get_width() / 6.0, sheet.get_height())
	for index in range(6):
		var frame = AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(Vector2(index * frame_size.x, 0), frame_size)
		frames.add_frame(&"default", frame)
	sprite.sprite_frames = frames
	sprite.scale = Vector2(2, 2)
	sprite.position.y = 20.0 - frame_size.y
	sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)
	sprite.play(&"default")
