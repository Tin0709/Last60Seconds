extends Area2D

const FRUIT = preload("res://assets/Pixel Crawler/Environment/Props/Static/Farm.png")
const DustVFX = preload("res://dust_vfx.gd")
var collected: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sprite = Sprite2D.new()
	sprite.texture = FRUIT
	sprite.region_enabled = true
	sprite.region_rect = Rect2(128, 48, 16, 16)
	sprite.scale = Vector2(2, 2)
	sprite.position.y = -8
	add_child(sprite)
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 14.0
	collision.shape = circle
	add_child(collision)

func _draw() -> void:
	# A soft ground marker keeps the pink fruit readable between small plants.
	draw_circle(Vector2(0, -3), 14, Color(0.86, 0.90, 0.57, 0.20))
	draw_arc(Vector2(0, -3), 14, 0, TAU, 16, Color(0.91, 0.94, 0.68, 0.45), 1.0)

func _physics_process(_delta: float) -> void:
	if collected:
		return
	# Retry while touching: a full-health player can use it after taking damage.
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.heal_one_heart():
			collected = true
			var burst = DustVFX.play(get_parent(), DustVFX.Kind.HIT, body.global_position, 0.25, 0.65)
			burst.modulate = Color(0.65, 1.0, 0.65, 0.65)
			queue_free()
			return
