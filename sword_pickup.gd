extends Area2D

const Sword = preload("res://sword.gd")
const Gun = preload("res://gun.gd")
@export var weapon: StringName = &"sword"
var collected: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sprite = Sprite2D.new()
	sprite.texture = Gun.TEXTURE if weapon == &"gun" else Sword.TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Gun.TEXTURE.get_image().get_used_rect()) if weapon == &"gun" else Sword.REGION
	sprite.scale = Vector2.ONE if weapon == &"gun" else Vector2(2, 2)
	sprite.position.y = -14 if weapon == &"gun" else -18
	sprite.rotation = -PI / 4.0
	add_child(sprite)
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16.0
	collision.shape = circle
	add_child(collision)
	body_entered.connect(_collect)

func _collect(body: Node2D) -> void:
	if collected or not body.is_in_group("player") or not body.is_physics_processing():
		return
	collected = true
	body.equip_weapon(weapon)
	queue_free()
