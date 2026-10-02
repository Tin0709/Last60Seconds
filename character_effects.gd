extends Node2D

const DustVFX = preload("res://dust_vfx.gd")

const SPAWN_SOUNDS = [
	preload("res://assets/audio/combat/impactSoft_medium_000.ogg"),
	preload("res://assets/audio/combat/impactSoft_medium_001.ogg"),
	preload("res://assets/audio/combat/impactSoft_medium_002.ogg"),
	preload("res://assets/audio/combat/impactSoft_medium_003.ogg"),
	preload("res://assets/audio/combat/impactSoft_medium_004.ogg"),
]

@export var emerge_on_spawn: bool = false

var particles: Array[Dictionary] = []
var step_time: float = 0.0
var step_side: float = 1.0
var rng = RandomNumberGenerator.new()
var vfx_rng = RandomNumberGenerator.new()
var step_burst_count: int = 0
var rise: Tween

@onready var body: CharacterBody2D = get_parent()
@onready var sprite: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")

func _ready() -> void:
	rng.randomize()
	vfx_rng.randomize()
	if emerge_on_spawn:
		# Only the artwork rises; the body remains active at its spawn position.
		sprite.scale.y = 0.1
		sprite.position.y = 14.0 - 13.0 * sprite.scale.y
		rise = create_tween().set_parallel(true)
		rise.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		rise.tween_property(sprite, "scale:y", 2.0, 0.4)
		rise.tween_property(sprite, "position:y", -12.0, 0.4)
		DustVFX.play(body.get_parent(), DustVFX.Kind.SPAWN, body.global_position, 0.5, 0.75)
		if vfx_rng.randi_range(0, 4) == 0:
			DustVFX.play(body.get_parent(), DustVFX.Kind.STRONG_SPAWN, body.global_position, 0.5, 0.45)
		step_time = 0.4
		var audio_rng = RandomNumberGenerator.new()
		audio_rng.randomize()
		var sound: AudioStreamPlayer2D = body.get_node("SpawnSound")
		sound.stream = SPAWN_SOUNDS[audio_rng.randi_range(0, SPAWN_SOUNDS.size() - 1)]
		sound.play()

func stop_emergence() -> void:
	if rise != null and rise.is_valid():
		rise.kill()

func play_step_dust() -> void:
	step_burst_count += 1
	if step_burst_count % 2 == 1:
		var puff = DustVFX.play(body.get_parent(), DustVFX.Kind.STEP, body.global_position, 0.25, 0.4)
		puff.flip_h = body.get_real_velocity().x > 0.0

func play_damage_burst() -> void:
	# The hit burst also marks the start of knockback, without extra collision spam.
	DustVFX.play(body.get_parent(), DustVFX.Kind.HIT, body.global_position, 0.5)

func _process(delta: float) -> void:
	step_time = maxf(step_time - delta, 0.0)
	if body.is_physics_processing() and body.get_real_velocity().length_squared() > 400.0:
		if step_time == 0.0:
			step_time = 0.24
			step_side *= -1.0
			add_particle(Vector2(step_side * 6, 14),
				-body.get_real_velocity().normalized() * 12.0 + Vector2(0, -6),
				0.3, 4.0, Color(0.65, 0.58, 0.43, 0.35), 0.0)
	for index in range(particles.size() - 1, -1, -1):
		var particle = particles[index]
		particle.life -= delta
		if particle.life <= 0.0:
			particles.remove_at(index)
			continue
		particle.velocity.y += particle.gravity * delta
		particle.position += particle.velocity * delta
	queue_redraw()

func add_particle(offset: Vector2, velocity: Vector2, lifetime: float,
		pixel_size: float, color: Color, gravity: float) -> void:
	# World positions keep dust behind the feet instead of dragging it along.
	particles.append({
		"position": global_position + offset,
		"velocity": velocity,
		"life": lifetime,
		"duration": lifetime,
		"size": pixel_size,
		"color": color,
		"gravity": gravity,
	})

func _draw() -> void:
	# Three hard-edged strips form a small, stepped pixel shadow.
	var shade = Color(0.07, 0.10, 0.06, 0.30)
	draw_rect(Rect2(-10, 10, 20, 2), shade)
	draw_rect(Rect2(-14, 12, 28, 4), shade)
	draw_rect(Rect2(-10, 16, 20, 2), shade)
	for particle in particles:
		var color: Color = particle.color
		color.a *= particle.life / particle.duration
		var point = (to_local(particle.position) / 2.0).round() * 2.0
		draw_rect(Rect2(point, Vector2.ONE * particle.size), color)
