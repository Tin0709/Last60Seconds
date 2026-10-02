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
				for detail in range(3):
					var offset = Vector2(rng.randf_range(-65, 65), rng.randf_range(-20, 45))
					add_prop($Decorations, VEGETATION, Rect2(112, 160, 16, 32), point + offset)

	for index in range(16):
		var point = Vector2(rng.randf_range(120, 2280), rng.randf_range(180, 1480))
		if can_place_solid(point, bounds):
			add_prop($Obstacles, ROCKS, Rect2(96, 16, 32, 32), point, 18.0)
			solid_positions.append(point)

	for index in range(120):
		var point = Vector2(rng.randf_range(80, 2320), rng.randf_range(80, 1520))
		# Keep the path clear and use fewer, shorter details in the center.
		if is_on_path(point):
			continue
		var central = Rect2(320, 240, 1600, 960).has_point(point)
		if central and index % 3 != 0:
			continue
		match index % 5:
			0:
				add_prop($Decorations, ROCKS, Rect2(64, 32, 16, 16), point)
			1:
				add_prop($Decorations, VEGETATION, Rect2(0, 32, 32, 32), point)
			2:
				add_prop($Decorations, VEGETATION, Rect2(80, 176, 16, 16), point)
			3:
				add_prop($Decorations, VEGETATION, Rect2(192, 160, 16, 32), point)
			4:
				add_prop($Decorations, VEGETATION, Rect2(208, 160, 16, 32), point)

func build_ground(bounds: Rect2) -> void:
	var atlas = TileSetAtlasSource.new()
	atlas.texture = FLOORS
	atlas.texture_region_size = Vector2i(16, 16)
	var grass_tiles: Array[Vector2i] = [Vector2i(1, 11), Vector2i(2, 11)]
	for grass in grass_tiles:
		atlas.create_tile(grass)
		atlas.create_alternative_tile(grass, 1)
		atlas.get_tile_data(grass, 1).modulate = Color(0.98, 0.99, 0.97)
		atlas.create_alternative_tile(grass, 2)
		atlas.get_tile_data(grass, 2).modulate = Color(1.02, 1.01, 0.99)
	var tiles = TileSet.new()
	tiles.tile_size = Vector2i(16, 16)
	tiles.add_source(atlas, 0)
	$Ground.tile_set = tiles
	$Ground.position = bounds.position
	$Ground.scale = Vector2(2, 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = 246
	for x in range(ceili(bounds.size.x / 32.0)):
		for y in range(ceili(bounds.size.y / 32.0)):
			var shade = sin(x * 0.19 + sin(y * 0.12)) + cos(y * 0.24 - x * 0.06)
			var variation = 1 if shade < -0.8 else (2 if shade > 0.9 else 0)
			$Ground.set_cell(Vector2i(x, y), 0, grass_tiles[rng.randi_range(0, grass_tiles.size() - 1)], variation)
	# Textured polygons give the path finer edges than a whole 32-pixel cell.
	var dirt_image = FLOORS.get_image().get_region(Rect2i(192, 176, 16, 16))
	var dirt_texture = ImageTexture.create_from_image(dirt_image)
	var main_path = PackedVector2Array()
	for x in range(220, 2101, 64):
		main_path.append(Vector2(x, path_height(x)).round() / 2.0)
	add_path(main_path, 23.0, dirt_texture)
	var branch = PackedVector2Array()
	for y in range(690, 1201, 48):
		branch.append(Vector2(1450 + sin(y * 0.007) * 55, y).round() / 2.0)
	add_path(branch, 15.0, dirt_texture)

func path_height(x: float) -> float:
	return 650.0 + sin(x * 0.005) * 75.0 + cos(x * 0.002) * 35.0

func is_on_path(point: Vector2) -> bool:
	return (point.x > 200 and point.x < 2120 and absf(point.y - path_height(point.x)) < 65.0) or (point.y > 650 and point.y < 1220 and absf(point.x - (1450 + sin(point.y * 0.007) * 55)) < 45.0)

func add_path(points: PackedVector2Array, width: float, texture: Texture2D) -> void:
	for border in [true, false]:
		var polygon = Polygon2D.new()
		var outline = PackedVector2Array()
		for side in [1.0, -1.0]:
			for step in range(points.size()):
				var index = step if side > 0 else points.size() - 1 - step
				var previous = points[maxi(index - 1, 0)]
				var following = points[mini(index + 1, points.size() - 1)]
				var normal = (following - previous).normalized().orthogonal()
				var half_width = width + sin(index * 1.7) * 2.0 + (2.0 if border else 0.0)
				if index == 0 or index == points.size() - 1:
					half_width *= 0.35
				outline.append((points[index] + normal * half_width * side).round())
		polygon.polygon = outline
		polygon.texture = texture
		polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		polygon.color = Color(0.75, 0.79, 0.65) if border else Color(1, 1, 1)
		$Ground.add_child(polygon)

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
	# Ground-level pixel silhouettes stay below characters and carry no collision.
	if radius > 0.0 or region.size.x >= 32:
		var shadow = Polygon2D.new()
		var shadow_size = Vector2(45, 17) if texture == TREES else Vector2(25, 10)
		var outline = PackedVector2Array()
		for step in range(12):
			var angle = TAU * step / 12.0
			outline.append((Vector2(cos(angle), sin(angle)) * shadow_size).round())
		shadow.polygon = outline
		shadow.position = point + Vector2(12, -4)
		shadow.color = Color(0.07, 0.12, 0.05, 0.20)
		$Decorations.add_child(shadow)
	layer.add_child(prop)
