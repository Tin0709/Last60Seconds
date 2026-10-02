extends Node2D

const TEXTURE = preload("res://assets/Pixel Crawler/Weapons/Wood/Wood.png")
const REGION = Rect2(32, 16, 16, 32)
const SLICE_SHEETS = [
	preload("res://assets/Pixel Crawler/Entities/Characters/Body_A/Animations/Slice_Base/Slice_Side-Sheet.png"),
	preload("res://assets/Pixel Crawler/Entities/Characters/Body_A/Animations/Slice_Base/Slice_Up-Sheet.png"),
	preload("res://assets/Pixel Crawler/Entities/Characters/Body_A/Animations/Slice_Base/Slice_Down-Sheet.png"),
]
static var slices: SpriteFrames
var attacking: bool = false
var blade: Sprite2D
var slash: AnimatedSprite2D

func _ready() -> void:
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
	add_child(blade)
	slash = AnimatedSprite2D.new()
	slash.sprite_frames = slices
	slash.position = Vector2(0, -28)
	slash.scale = Vector2(2, 2)
	slash.visible = false
	add_child(slash)
	slash.animation_finished.connect(_finish_attack)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face(Vector2.RIGHT)

func face(direction: Vector2) -> void:
	if attacking:
		return
	blade.position = Vector2(direction.x * 14, -8)
	blade.rotation = direction.angle() + PI / 2.0
	blade.z_index = -1 if direction == Vector2.UP else 0

func attack(direction: Vector2) -> void:
	face(direction)
	attacking = true
	slash.visible = true
	slash.flip_h = direction == Vector2.LEFT
	slash.play(&"up" if direction == Vector2.UP else (&"down" if direction == Vector2.DOWN else &"side"))
	var resting_rotation = blade.rotation
	blade.rotation -= 0.8
	create_tween().tween_property(blade, "rotation", resting_rotation + 0.8, 0.28)

func _finish_attack() -> void:
	attacking = false
	slash.visible = false
