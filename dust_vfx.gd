extends RefCounted

enum Kind { STEP, SPAWN, STRONG_SPAWN, HIT }

const SHEETS = [
	preload("res://assets/vfx/smoke_dust/VFX1/sprite-sheet.png"),
	preload("res://assets/vfx/smoke_dust/VFX2/sprite-sheet.png"),
	preload("res://assets/vfx/smoke_dust/VFX3/sprite-sheet.png"),
	preload("res://assets/vfx/smoke_dust/VFX4/sprite-sheet.png"),
]
const DURATIONS = [0.28, 0.4, 0.45, 0.3]
const OFFSETS = [Vector2(0, -40), Vector2(0, -14), Vector2(0, -48), Vector2(0, -36)]
static var animations: Dictionary = {}

static func play(parent: Node2D, kind: Kind, point: Vector2, size: float, opacity: float = 1.0) -> AnimatedSprite2D:
	if not animations.has(kind):
		var frames = SpriteFrames.new()
		var sheet: Texture2D = SHEETS[kind]
		var count = int(sheet.get_width() / 128.0)
		frames.set_animation_loop(&"default", false)
		frames.set_animation_speed(&"default", count / DURATIONS[kind])
		for index in range(count):
			var frame = AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(index * 128, 0, 128, 128)
			frames.add_frame(&"default", frame)
		animations[kind] = frames
	var effect = AnimatedSprite2D.new()
	effect.sprite_frames = animations[kind]
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.scale = Vector2.ONE * size
	effect.offset = OFFSETS[kind]
	effect.modulate = Color(0.85, 0.82, 0.70, opacity) if kind != Kind.HIT else Color.WHITE
	effect.z_index = -1 if kind == Kind.STEP else 0
	# A fixed world position and foot-level sort origin keep bursts in the environment.
	effect.position = parent.to_local(point.round())
	# Spawn effects can be requested while the scene is still entering the tree.
	parent.add_child.call_deferred(effect)
	effect.animation_finished.connect(effect.queue_free)
	effect.play.call_deferred()
	return effect
