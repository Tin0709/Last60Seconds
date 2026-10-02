extends Node2D

var direction: Vector2 = Vector2.RIGHT
var shooter: CharacterBody2D
var gun: Node2D
var bounds: Rect2
var spent: bool = false

func _ready() -> void:
	add_to_group("bullets")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rotation = direction.angle()

func _draw() -> void:
	draw_rect(Rect2(-4, -1, 8, 2), Color("ffe6a0"))

func _physics_process(delta: float) -> void:
	if spent:
		return
	if not is_instance_valid(shooter) or not shooter.is_physics_processing():
		queue_free()
		return
	var end = global_position + direction * 900.0 * delta
	# Sweep the whole step so fast bullets cannot tunnel through enemies or trees.
	var query = PhysicsRayQueryParameters2D.create(global_position, end, 1, [shooter.get_rid()])
	query.hit_from_inside = true
	var hit = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		spent = true
		global_position = hit.position
		var body: Node2D = hit.collider
		if body.is_in_group("enemies") and body.take_hit():
			gun.play_hit_feedback(body.global_position, body.dead)
		queue_free()
		return
	global_position = end
	if not bounds.has_point(global_position):
		queue_free()
