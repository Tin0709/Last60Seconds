extends Node2D

const FLOORS = preload("res://assets/Pixel Crawler/Environment/Tilesets/Floors_Tiles.png")
const TREES = preload("res://assets/Pixel Crawler/Environment/Props/Static/Trees/Model_01/Size_03.png")
const ROCKS = preload("res://assets/Pixel Crawler/Environment/Props/Static/Rocks.png")
const VEGETATION = preload("res://assets/Pixel Crawler/Environment/Props/Static/Vegetation.png")

var solid_positions: Array[Vector2] = []

func _ready() -> void:
	var bounds: Rect2 = get_parent().world_bounds
	var rng = RandomNumberGenerator.new()
	rng.seed = 60
	build_ground(bounds)

	# Leave the starting area and the middle of the map open.
	var clusters: Array[Vector2] = [
		Vector2(180, 650), Vector2(200, 1150), Vector2(620, 1420),
		Vector2(1250, 1400), Vector2(1870, 1420), Vector2(2180, 1050),
		Vector2(2190, 440), Vector2(1770, 180), Vector2(1050, 150),
	]
	for center in clusters:
		for index in range(5):
			var point = center + Vector2(rng.randf_range(-120, 120), rng.randf_range(-90, 90))
			if can_place_solid(point, bounds):
				add_prop($Obstacles, TREES, Rect2(0, 0, 48, 96), point, 13.0)
				solid_positions.append(point)

	for index in range(16):
		var point = Vector2(rng.randf_range(120, 2280), rng.randf_range(180, 1480))
		if can_place_solid(point, bounds):
			add_prop($Obstacles, ROCKS, Rect2(96, 16, 32, 32), point, 18.0)
			solid_positions.append(point)

	for index in range(65):
		var point = Vector2(rng.randf_range(80, 2320), rng.randf_range(80, 1520))
		# Sparse small details, with no collision.
		match index % 3:
			0:
				add_prop($Decorations, ROCKS, Rect2(64, 32, 16, 16), point)
			1:
				add_prop($Decorations, VEGETATION, Rect2(0, 0, 32, 32), point)
			2:
				add_prop($Decorations, VEGETATION, Rect2(80, 176, 16, 16), point)

func build_ground(bounds: Rect2) -> void:
	var atlas = TileSetAtlasSource.new()
	atlas.texture = FLOORS
	atlas.texture_region_size = Vector2i(16, 16)
	var grass = Vector2i(2, 11)
	var dirt = Vector2i(12, 11)
	atlas.create_tile(grass)
	atlas.create_tile(dirt)
	var tiles = TileSet.new()
	tiles.tile_size = Vector2i(16, 16)
	tiles.add_source(atlas, 0)
	$Ground.tile_set = tiles
	$Ground.position = bounds.position
	$Ground.scale = Vector2(2, 2)
	for x in range(ceili(bounds.size.x / 32.0)):
		for y in range(ceili(bounds.size.y / 32.0)):
			var path_y = 20 + roundi(sin(float(x) * 0.07) * 4.0)
			var on_path = x >= 8 and x <= 65 and absi(y - path_y) <= 1
			$Ground.set_cell(Vector2i(x, y), 0, dirt if on_path else grass)

func can_place_solid(point: Vector2, bounds: Rect2) -> bool:
	if not bounds.grow(-100).has_point(point):
		return false
	if Rect2(320, 240, 1600, 960).has_point(point):
		return false
	if point.distance_to(get_parent().get_node("Player").position) < 180.0:
		return false
	if point.distance_to(get_parent().get_node("Enemy").position) < 120.0:
		return false
	for existing in solid_positions:
		if point.distance_to(existing) < 80.0:
			return false
	return true

func add_prop(layer: Node2D, texture: Texture2D, region: Rect2, point: Vector2, radius: float = 0.0) -> void:
	var prop: Node2D = StaticBody2D.new() if radius > 0.0 else Node2D.new()
	prop.position = point
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = Vector2(2, 2)
	sprite.position.y = -region.size.y
	prop.add_child(sprite)
	if radius > 0.0:
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = radius
		collision.shape = shape
		collision.position.y = -radius
		prop.add_child(collision)
	layer.add_child(prop)
