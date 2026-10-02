extends Area2D

const Sword = preload("res://sword.gd")
const WeaponData = preload("res://weapon_data.gd")
@export var weapon: StringName = &"sword"
var collected: bool = false
var pickup_delay: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sprite = Sprite2D.new()
	var firearm = weapon != &"sword"
	var settings: Dictionary = WeaponData.GUNS[weapon] if firearm else {}
	sprite.texture = settings.texture if firearm else Sword.TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(sprite.texture.get_image().get_used_rect()) if firearm else Sword.REGION
	sprite.scale = Vector2.ONE * settings.scale if firearm else Vector2(2, 2)
	sprite.position.y = -14 if firearm else -18
	sprite.rotation = -PI / 4.0
	add_child(sprite)
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16.0
	collision.shape = circle
	add_child(collision)
	body_entered.connect(_collect)
	add_to_group("weapon_pickups")

func _physics_process(delta: float) -> void:
	if pickup_delay <= 0.0:
		return
	pickup_delay = maxf(pickup_delay - delta, 0.0)
	if pickup_delay == 0.0:
		for body in get_overlapping_bodies():
			_collect(body)

func _collect(body: Node2D) -> void:
	if collected or pickup_delay > 0.0 or not body.is_in_group("player") or not body.is_physics_processing() or not body.can_process():
		return
	collected = true
	body.equip_weapon(weapon)
	body.get_node("PickupSound").play()
	queue_free()
