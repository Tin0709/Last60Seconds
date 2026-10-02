extends Node2D

const TEXTURE = preload("res://assets/Pixel Crawler/Weapons/Wood/Wood.png")
const REGION = Rect2(32, 16, 16, 32)
const DustVFX = preload("res://dust_vfx.gd")
const HIT_SOUNDS = [
	preload("res://assets/Sword Combat Sound Effects Pack FREE VERSION/Main Sounds/Sword Collisions/Base Wood/WEAPSwrd_BaseWood_HoveAud_SwordCombat_03.wav"),
	preload("res://assets/Sword Combat Sound Effects Pack FREE VERSION/Main Sounds/Sword Collisions/Base Wood/WEAPSwrd_BaseWood_HoveAud_SwordCombat_06.wav"),
]
const SWING_SOUNDS = [
	preload("res://assets/Sword Combat Sound Effects Pack FREE VERSION/Whooshes/WHSH_Whoosh_HoveAud_SwordCombat_07.wav"),
	preload("res://assets/Sword Combat Sound Effects Pack FREE VERSION/Whooshes/WHSH_Whoosh_HoveAud_SwordCombat_26.wav"),
]
const DEATH_SOUNDS = [
	preload("res://assets/audio/combat/impactSoft_medium_000.ogg"),
	preload("res://assets/audio/combat/impactSoft_medium_001.ogg"),
	preload("res://assets/audio/combat/impactSoft_medium_002.ogg"),
	preload("res://assets/audio/combat/impactSoft_medium_003.ogg"),
	preload("res://assets/audio/combat/impactSoft_medium_004.ogg"),
]
const SLICE_SHEETS = [
	preload("res://assets/Pixel Crawler/Entities/Characters/Body_A/Animations/Slice_Base/Slice_Side-Sheet.png"),
	preload("res://assets/Pixel Crawler/Entities/Characters/Body_A/Animations/Slice_Base/Slice_Up-Sheet.png"),
	preload("res://assets/Pixel Crawler/Entities/Characters/Body_A/Animations/Slice_Base/Slice_Down-Sheet.png"),
]
static var slices: SpriteFrames
var attacking: bool = false
var blade: Sprite2D
var slash: AnimatedSprite2D
var attack_direction: Vector2 = Vector2.RIGHT
var hit_enemies: Dictionary = {}
var impact_sound: AudioStreamPlayer
var swing_sound: AudioStreamPlayer
var swing_tween: Tween
var audio_rng = RandomNumberGenerator.new()
var feedback_played: bool = false
var death_feedback_played: bool = false

func _ready() -> void:
	audio_rng.randomize()
	impact_sound = AudioStreamPlayer.new()
	impact_sound.max_polyphony = 1
	add_child(impact_sound)
	swing_sound = AudioStreamPlayer.new()
	swing_sound.volume_db = -15.0
	swing_sound.max_polyphony = 1
	add_child(swing_sound)
	if slices == null:
		slices = SpriteFrames.new()
		for direction in range(3):
			# Keep the pale Slice arc, excluding the differently dressed base character.
			var source: Image = SLICE_SHEETS[direction].get_image()
			var image = Image.create(source.get_width(), 64, false, Image.FORMAT_RGBA8)
			for frame in range(8):
				var pixels = 0
				for x in range(frame * 64, (frame + 1) * 64):
					for y in range(64):
						var color = source.get_pixel(x, y)
						if color.a > 0.0 and minf(color.r, minf(color.g, color.b)) > 0.75 and absf(color.r - color.g) < 0.04 and absf(color.g - color.b) < 0.04:
							image.set_pixel(x, y, color)
							pixels += 1
				# Empty windup/recovery frames can contain tiny light hand/weapon pixels.
				if pixels < 20:
					image.fill_rect(Rect2i(frame * 64, 0, 64, 64), Color.TRANSPARENT)
			var texture = ImageTexture.create_from_image(image)
			var animation = [&"side", &"up", &"down"][direction]
			slices.add_animation(animation)
			slices.set_animation_loop(animation, false)
			slices.set_animation_speed(animation, 8.0 / 0.28)
			for frame in range(8):
				var atlas = AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(frame * 64, 0, 64, 64)
				slices.add_frame(animation, atlas)
	blade = Sprite2D.new()
	blade.texture = TEXTURE
	blade.region_enabled = true
	blade.region_rect = REGION
	blade.scale = Vector2(2, 2)
	blade.offset = Vector2(0, -12)
	add_child(blade)
	slash = AnimatedSprite2D.new()
	slash.sprite_frames = slices
	slash.position = Vector2(0, -28)
	slash.scale = Vector2(2, 2)
	slash.visible = false
	add_child(slash)
	slash.animation_finished.connect(_finish_attack)
	slash.frame_changed.connect(_check_hits)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face(Vector2.RIGHT)

func face(direction: Vector2) -> void:
	if attacking:
		return
	blade.position = Vector2(direction.x * 16, -8 + direction.y * 8)
	blade.rotation = direction.angle() + PI / 2.0
	blade.z_index = -1 if direction == Vector2.UP else 0

func attack(direction: Vector2) -> void:
	if not visible or not get_parent().is_physics_processing():
		return
	face(direction)
	attack_direction = direction
	hit_enemies.clear()
	feedback_played = false
	death_feedback_played = false
	attacking = true
	swing_sound.stream = SWING_SOUNDS[audio_rng.randi_range(0, SWING_SOUNDS.size() - 1)]
	swing_sound.pitch_scale = audio_rng.randf_range(0.95, 1.05)
	swing_sound.play()
	slash.visible = true
	slash.flip_h = direction == Vector2.LEFT
	slash.play(&"up" if direction == Vector2.UP else (&"down" if direction == Vector2.DOWN else &"side"))
	var resting_rotation = blade.rotation
	blade.rotation -= 0.8
	swing_tween = create_tween()
	swing_tween.tween_property(blade, "rotation", resting_rotation + 0.8, 0.28)

func _physics_process(_delta: float) -> void:
	_check_hits()

func _check_hits() -> void:
	# Frame 3 contains the visible Slice arc; windup and recovery cannot hit.
	if not attacking or not visible or slash.frame != 3 or not get_parent().is_physics_processing():
		return
	var hit = false
	var killed = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var id = enemy.get_instance_id()
		if hit_enemies.has(id):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length_squared() <= 72.0 * 72.0 and (offset == Vector2.ZERO or offset.normalized().dot(attack_direction) >= 0.5):
			if enemy.take_sword_hit():
				hit_enemies[id] = true
				hit = true
				killed = killed or enemy.dead
				# Keep crowd hits readable without filling the screen with bursts.
				if hit_enemies.size() <= 3:
					DustVFX.play(get_parent().get_parent(), DustVFX.Kind.SPAWN if enemy.dead else DustVFX.Kind.HIT,
						enemy.global_position, 0.35 if enemy.dead else 0.25, 0.55 if enemy.dead else 0.75)
	if hit and (not feedback_played or (killed and not death_feedback_played)):
		# One voice per swing; a later kill can replace the hit with a distinct thud.
		var sounds = DEATH_SOUNDS if killed else HIT_SOUNDS
		impact_sound.stream = sounds[audio_rng.randi_range(0, sounds.size() - 1)]
		impact_sound.volume_db = -12.0 if killed else -10.0
		impact_sound.pitch_scale = audio_rng.randf_range(0.78, 0.86) if killed else audio_rng.randf_range(0.95, 1.05)
		impact_sound.play()
		feedback_played = true
		death_feedback_played = death_feedback_played or killed

func _finish_attack() -> void:
	attacking = false
	slash.visible = false

func cancel_attack() -> void:
	if swing_tween != null and swing_tween.is_valid():
		swing_tween.kill()
	attacking = false
	slash.stop()
	slash.visible = false
	impact_sound.stop()
	swing_sound.stop()
