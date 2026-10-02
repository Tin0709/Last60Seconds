extends Node2D

const TEXTURE = preload("res://assets/FreePixelGunPack/Guns/47.png")
const SHOT = preload("res://assets/Snake's Authentic Gun Sounds/Isolated/5.56/WAV/556 Single Isolated WAV.wav")
const HIT_SOUNDS = [
	preload("res://assets/audio/combat/impactPunch_heavy_000.ogg"),
	preload("res://assets/audio/combat/impactPunch_heavy_001.ogg"),
]
const DEATH_SOUND = preload("res://assets/audio/combat/impactSoft_medium_000.ogg")
const Bullet = preload("res://bullet.gd")
const DustVFX = preload("res://dust_vfx.gd")
const WeaponData = preload("res://weapon_data.gd")

var sprite: Sprite2D
var muzzle: Polygon2D
var shot_sound: AudioStreamPlayer
var hit_sound: AudioStreamPlayer
var audio_rng = RandomNumberGenerator.new()
var flash_time: float = 0.0
var weapon_type: StringName = &"gun"
var settings: Dictionary
var feedback_time: float = 0.0
var recent_death_feedback: bool = false

func _ready() -> void:
	audio_rng.randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite = Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(TEXTURE.get_image().get_used_rect())
	sprite.scale = Vector2.ONE
	sprite.offset = Vector2(16, 0)
	add_child(sprite)
	muzzle = Polygon2D.new()
	muzzle.polygon = PackedVector2Array([Vector2(0, 0), Vector2(6, -6), Vector2(5, -2), Vector2(14, 0), Vector2(5, 2), Vector2(6, 6)])
	muzzle.color = Color("ffe6a0")
	muzzle.position = Vector2(sprite.offset.x + sprite.region_rect.size.x / 2.0 + 2, 0)
	muzzle.visible = false
	sprite.add_child(muzzle)
	shot_sound = AudioStreamPlayer.new()
	shot_sound.stream = SHOT
	shot_sound.volume_db = -18.0
	shot_sound.max_polyphony = 1
	add_child(shot_sound)
	hit_sound = AudioStreamPlayer.new()
	hit_sound.max_polyphony = 1
	add_child(hit_sound)
	set_weapon(weapon_type)
	face(Vector2.RIGHT)

func set_weapon(kind: StringName) -> void:
	weapon_type = kind
	settings = WeaponData.GUNS[kind]
	sprite.texture = settings.texture
	sprite.region_rect = Rect2(sprite.texture.get_image().get_used_rect())
	sprite.scale = Vector2.ONE * settings.scale
	sprite.offset.x = sprite.region_rect.size.x * 0.22
	muzzle.position.x = sprite.offset.x + sprite.region_rect.size.x / 2.0 + 2
	shot_sound.stream = settings.sound
	shot_sound.volume_db = settings.volume

func face(direction: Vector2) -> void:
	if flash_time > 0.0:
		return
	sprite.position = Vector2(0, -12)
	sprite.rotation = direction.angle()
	sprite.flip_v = direction.x < 0.0
	sprite.z_index = -1 if direction.y < -0.5 else 0

func nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy.is_inside_tree() or enemy.dead or enemy.health <= 0:
			continue
		var distance = global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func fire(direction: Vector2) -> void:
	if not visible or not get_parent().is_physics_processing() or not can_process():
		return
	# Select once per shot; the bullet keeps its direction instead of tracking/jittering.
	var target = nearest_enemy()
	var origin = global_position + Vector2(0, -12)
	if target != null and not origin.is_equal_approx(target.global_position):
		direction = origin.direction_to(target.global_position)
	flash_time = 0.0
	face(direction)
	var start = muzzle.global_position
	if target != null:
		# A nearby enemy can be closer than the enlarged barrel: do not spawn past it.
		var distance = origin.distance_to(target.global_position)
		start = origin + direction * minf(origin.distance_to(muzzle.global_position), distance * 0.5)
	# A larger barrel must not spawn bullets on the far side of a nearby solid.
	var query = PhysicsRayQueryParameters2D.create(origin, start, 1, [get_parent().get_rid()])
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		start = origin
	for index in range(settings.count):
		var bullet = Bullet.new()
		var spread = 0.0 if settings.count == 1 else lerpf(-settings.spread / 2.0, settings.spread / 2.0, index / float(settings.count - 1))
		bullet.direction = direction.rotated(deg_to_rad(spread))
		bullet.speed = settings.speed
		bullet.explosive = settings.explosive
		bullet.shooter = get_parent()
		bullet.gun = self
		bullet.bounds = get_parent().world_bounds
		get_parent().get_parent().add_child(bullet)
		bullet.global_position = start
	if shot_sound.stream != null:
		shot_sound.pitch_scale = settings.pitch * audio_rng.randf_range(0.98, 1.02)
		shot_sound.play()
	muzzle.visible = true
	flash_time = 0.05

func _process(delta: float) -> void:
	flash_time = maxf(flash_time - delta, 0.0)
	feedback_time = maxf(feedback_time - delta, 0.0)
	if feedback_time == 0.0:
		recent_death_feedback = false
	muzzle.visible = flash_time > 0.0

func play_hit_feedback(point: Vector2, killed: bool) -> void:
	if feedback_time > 0.0 and not (killed and not recent_death_feedback):
		return
	feedback_time = 0.06
	recent_death_feedback = recent_death_feedback or killed
	DustVFX.play(get_parent().get_parent(), DustVFX.Kind.SPAWN if killed else DustVFX.Kind.HIT,
		point, 0.35 if killed else 0.25, 0.55 if killed else 0.75)
	hit_sound.stream = DEATH_SOUND if killed else HIT_SOUNDS[audio_rng.randi_range(0, HIT_SOUNDS.size() - 1)]
	hit_sound.volume_db = -14.0 if killed else -18.0
	hit_sound.pitch_scale = 0.82 if killed else 1.0
	hit_sound.play()

func stop_combat() -> void:
	shot_sound.stop()
	hit_sound.stop()
	flash_time = 0.0
	muzzle.visible = false
