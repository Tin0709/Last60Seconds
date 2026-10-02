extends RefCounted

const DustVFX = preload("res://dust_vfx.gd")
const BLAST_RADIUS: float = 80.0

static func detonate(parent: Node2D, point: Vector2, gun: Node2D) -> void:
	var ring = DustVFX.play(parent, DustVFX.Kind.SPAWN, point, 1.25, 0.8)
	ring.modulate = Color(1.0, 0.75, 0.35, 0.8)
	ring.add_to_group("explosions")
	var plume = DustVFX.play(parent, DustVFX.Kind.STRONG_SPAWN, point, 0.75, 0.7)
	plume.modulate = Color(1.0, 0.55, 0.25, 0.7)
	plume.add_to_group("explosions")
	var damaged = false
	var killed = false
	# Apply the blast once, rather than using a persistent overlapping damage area.
	for enemy in parent.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.dead:
			if point.distance_squared_to(enemy.global_position) <= BLAST_RADIUS * BLAST_RADIUS and enemy.take_hit():
				damaged = true
				killed = killed or enemy.dead
	if damaged and is_instance_valid(gun):
		gun.play_hit_feedback(point, killed)
