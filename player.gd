extends CharacterBody2D

signal health_changed(health: int)

const FOOTSTEP_SOUNDS = [preload("res://assets/audio/footsteps/footstep_grass_004.ogg")]
const STEP_DISTANCE: float = 72.0
const WeaponPickup = preload("res://sword_pickup.gd")
const WEAPON_INTERACTION_RANGE: float = 64.0

const DAMAGE_SOUNDS = [
	preload("res://assets/audio/combat/impactPunch_heavy_000.ogg"),
	preload("res://assets/audio/combat/impactPunch_heavy_001.ogg"),
	preload("res://assets/audio/combat/impactPunch_heavy_002.ogg"),
	preload("res://assets/audio/combat/impactPunch_heavy_003.ogg"),
	preload("res://assets/audio/combat/impactPunch_heavy_004.ogg"),
]

@export var speed: float = 300.0
@export var player_radius: float = 20.0

var health: int = 5
var world_bounds: Rect2
var damage_cooldown: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_time_remaining: float = 0.0
var audio_rng = RandomNumberGenerator.new()
var footstep_rng = RandomNumberGenerator.new()
var footstep_distance: float = STEP_DISTANCE
var last_footstep: int = -1
var has_sword: bool = false
var equipped_weapon: StringName = &""
var facing_direction: Vector2 = Vector2.RIGHT
var attack_cooldown: float = 0.0
var nearby_weapon: Area2D
@onready var weapon_prompt: Label = get_parent().get_node("HUD/WeaponPrompt")

func _ready() -> void:
	audio_rng.randomize()
	footstep_rng.randomize()

func _physics_process(delta):
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	damage_cooldown = maxf(damage_cooldown - delta, 0.0)
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)
	if direction != Vector2.ZERO:
		if absf(direction.x) >= absf(direction.y):
			facing_direction = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
		else:
			facing_direction = Vector2.DOWN if direction.y > 0.0 else Vector2.UP
	if equipped_weapon == &"sword":
		$Sword.face(facing_direction)
	elif equipped_weapon != &"" and direction != Vector2.ZERO:
		$Gun.face(facing_direction)
	if equipped_weapon != &"" and attack_cooldown == 0.0:
		if equipped_weapon == &"sword":
			if Input.is_action_just_pressed("attack"):
				attack_cooldown = 0.4
				$Sword.attack(facing_direction)
		else:
			if Input.is_action_pressed("attack"):
				attack_cooldown = $Gun.settings.interval
				$Gun.fire(facing_direction)

	velocity = direction * speed
	if knockback_time_remaining > 0.0:
		velocity = knockback_direction * 400.0
		knockback_time_remaining = maxf(knockback_time_remaining - delta, 0.0)
	var previous_position = global_position
	move_and_slide()

	keep_inside_world()
	_update_weapon_interaction()
	var distance = global_position.distance_to(previous_position)
	if direction == Vector2.ZERO or distance < 0.1 or knockback_time_remaining > 0.0:
		stop_footsteps()
	else:
		footstep_distance += distance
		if footstep_distance >= STEP_DISTANCE:
			footstep_distance = fmod(footstep_distance, STEP_DISTANCE)
			var index = footstep_rng.randi_range(0, FOOTSTEP_SOUNDS.size() - 1)
			if FOOTSTEP_SOUNDS.size() > 1 and index == last_footstep:
				index = (index + footstep_rng.randi_range(1, FOOTSTEP_SOUNDS.size() - 1)) % FOOTSTEP_SOUNDS.size()
			last_footstep = index
			$FootstepSound.stream = FOOTSTEP_SOUNDS[index]
			$FootstepSound.pitch_scale = footstep_rng.randf_range(0.94, 1.06)
			$FootstepSound.play()
			$Effects.play_step_dust()

func _update_weapon_interaction() -> void:
	if not is_physics_processing() or not can_process():
		clear_weapon_prompt()
		return
	var nearest: Area2D = null
	var nearest_distance = WEAPON_INTERACTION_RANGE * WEAPON_INTERACTION_RANGE
	# Retain the current choice on equal distances so adjacent pickups do not flicker.
	if _valid_weapon(nearby_weapon):
		var distance = global_position.distance_squared_to(nearby_weapon.global_position)
		if distance <= nearest_distance:
			nearest = nearby_weapon
			nearest_distance = distance
	for pickup in get_tree().get_nodes_in_group("weapon_pickups"):
		if not _valid_weapon(pickup):
			continue
		var distance = global_position.distance_squared_to(pickup.global_position)
		if distance <= WEAPON_INTERACTION_RANGE * WEAPON_INTERACTION_RANGE and (nearest == null or distance < nearest_distance - 0.01):
			nearest = pickup
			nearest_distance = distance
	nearby_weapon = nearest
	weapon_prompt.visible = nearest != null
	if nearest != null:
		weapon_prompt.text = "Press E to pickup %s" % WeaponPickup.WEAPON_NAMES[nearest.weapon]
		if Input.is_action_just_pressed("interact"):
			nearest.collect(self)
			clear_weapon_prompt()

func _valid_weapon(pickup: Area2D) -> bool:
	return is_instance_valid(pickup) and not pickup.is_queued_for_deletion() and not pickup.collected and pickup.pickup_delay <= 0.0

func clear_weapon_prompt() -> void:
	nearby_weapon = null
	weapon_prompt.hide()

func stop_footsteps() -> void:
	$FootstepSound.stop()
	footstep_distance = STEP_DISTANCE

func equip_sword() -> void:
	equip_weapon(&"sword")

func equip_weapon(weapon: StringName) -> void:
	if equipped_weapon != &"":
		_drop_weapon(equipped_weapon)
	$Sword.cancel_attack()
	$Gun.stop_combat()
	equipped_weapon = weapon
	attack_cooldown = 0.0
	has_sword = weapon == &"sword"
	$Sword.visible = has_sword
	$Gun.visible = weapon != &"sword"
	if not has_sword:
		$Gun.set_weapon(weapon)

func _drop_weapon(weapon: StringName) -> void:
	var drop_point = global_position
	var fallback = global_position
	var found = false
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [get_rid()]
	for distance in [56.0, 88.0, 120.0, 160.0]:
		for index in range(8):
			var offset = Vector2.from_angle(facing_direction.angle() + PI + index * TAU / 8.0) * distance
			var point = global_position + offset
			if not world_bounds.grow(-24.0).has_point(point):
				continue
			fallback = point
			query.transform = Transform2D(0.0, point)
			if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
				drop_point = point
				found = true
				break
		if found:
			break
	if not found:
		drop_point = fallback
	var dropped = WeaponPickup.new()
	dropped.weapon = weapon
	dropped.pickup_delay = 0.35
	dropped.position = get_parent().to_local(drop_point.round())
	dropped.add_to_group("dropped_weapons")
	get_parent().add_child.call_deferred(dropped)

func heal_one_heart() -> bool:
	if not is_physics_processing() or not can_process() or health <= 0 or health >= 5:
		return false
	health = mini(health + 1, 5)
	$HealSound.play()
	health_changed.emit(health)
	return true


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
	$Effects.play_damage_burst()
	$DamageSound.stream = DAMAGE_SOUNDS[audio_rng.randi_range(0, DAMAGE_SOUNDS.size() - 1)]
	$DamageSound.play()
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
