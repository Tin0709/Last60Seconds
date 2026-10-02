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

var sprite: Sprite2D
var muzzle: Polygon2D
var shot_sound: AudioStreamPlayer
var hit_sound: AudioStreamPlayer
var audio_rng = RandomNumberGenerator.new()
var flash_time: float = 0.0

func _ready() -> void:
	audio_rng.randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite = Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(TEXTURE.get_image().get_used_rect())
	sprite.scale = Vector2(0.5, 0.5)
	add_child(sprite)
	muzzle = Polygon2D.new()
	muzzle.polygon = PackedVector2Array([Vector2(0, 0), Vector2(6, -6), Vector2(5, -2), Vector2(14, 0), Vector2(5, 2), Vector2(6, 6)])
	muzzle.color = Color("ffe6a0")
	muzzle.position = Vector2(sprite.region_rect.size.x / 2.0 + 2, -2)
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
	face(Vector2.RIGHT)

func face(direction: Vector2) -> void:
	sprite.position = Vector2(direction.x * 10, -12)
	sprite.rotation = direction.angle()
	sprite.flip_v = direction == Vector2.LEFT
	sprite.z_index = -1 if direction == Vector2.UP else 0

func fire(direction: Vector2) -> void:
	if not visible or not get_parent().is_physics_processing():
		return
	face(direction)
	var bullet = Bullet.new()
	bullet.direction = direction
	bullet.shooter = get_parent()
	bullet.gun = self
	bullet.bounds = get_parent().world_bounds
	get_parent().get_parent().add_child(bullet)
	bullet.global_position = sprite.global_position + direction * (sprite.region_rect.size.x * 0.25 + 4)
	shot_sound.play()
	muzzle.visible = true
	flash_time = 0.05

func _process(delta: float) -> void:
	flash_time = maxf(flash_time - delta, 0.0)
	muzzle.visible = flash_time > 0.0

func play_hit_feedback(point: Vector2, killed: bool) -> void:
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
