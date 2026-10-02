extends Node2D

const FLOORS = preload("res://assets/Pixel Crawler/Environment/Tilesets/Floors_Tiles.png")
const TREES = preload("res://assets/Pixel Crawler/Environment/Props/Static/Trees/Model_01/Size_03.png")
const FIRS = preload("res://assets/Pixel Crawler/Environment/Props/Static/Trees/Model_02/Size_03.png")
const ROCKS = preload("res://assets/Pixel Crawler/Environment/Props/Static/Rocks.png")
const VEGETATION = preload("res://assets/Pixel Crawler/Environment/Props/Static/Vegetation.png")
const BerryPickup = preload("res://berry_pickup.gd")

var solid_positions: Array[Vector2] = []
var clearing: Rect2
var paths: Array[PackedVector2Array] = []
var path_widths: Array[float] = [24.0, 16.0, 12.0]
var canopy_rects: Array[Rect2] = []
var bush_rects: Array[Rect2] = []
var detail_positions: Array[Vector2] = []
var visible_regions: Dictionary = {}
var foreground_sprites: Array[Sprite2D] = []

@onready var player: Node2D = get_parent().get_node("Player")

func _ready() -> void:
	var bounds: Rect2 = get_parent().world_bounds
	var rng = RandomNumberGenerator.new()
	rng.seed = 60
	clearing = Rect2(bounds.position + bounds.size * Vector2(0.20, 0.22), bounds.size * Vector2(0.60, 0.52))
	build_ground(bounds)

	# Leave the starting area and the middle of the map open.
	var clusters: Array[Vector2] = [
		Vector2(0.09, 0.32), Vector2(0.12, 0.57), Vector2(0.10, 0.84),
		Vector2(0.28, 0.86), Vector2(0.48, 0.90), Vector2(0.72, 0.85),
		Vector2(0.90, 0.87), Vector2(0.88, 0.64), Vector2(0.92, 0.35),
		Vector2(0.87, 0.13), Vector2(0.64, 0.14), Vector2(0.36, 0.13),
	]
	for cluster in clusters:
		var center = bounds.position + bounds.size * cluster
		for index in range(rng.randi_range(7, 11)):
			var point = center + Vector2(rng.randf_range(-190, 190), rng.randf_range(-125, 125))
			if can_place_solid(point, bounds):
				var fir = rng.randf() < 0.35
				var texture = FIRS if fir else TREES
				var region = Rect2(0, 0, 48, 80) if fir else Rect2(0, 0, 48, 96)
				if rng.randf() < 0.25:
					region.position.x = 48
				add_prop($Obstacles, texture, region, point, 13.0, rng.randf() < 0.5)
				solid_positions.append(point)
				for detail in range(3):
					var offset = Vector2(rng.randf_range(-65, 65), rng.randf_range(-20, 45))
					if not is_on_path(point + offset):
						add_prop($Decorations, VEGETATION, Rect2(112, 160, 16, 32), point + offset)

	var rock_regions: Array[Rect2] = [Rect2(0, 16, 32, 48), Rect2(96, 16, 32, 48), Rect2(32, 16, 32, 32), Rect2(128, 16, 32, 32)]
	for index in range(40):
		var point = bounds.position + Vector2(rng.randf_range(120, bounds.size.x - 120), rng.randf_range(200, bounds.size.y - 120))
		if can_place_solid(point, bounds):
			var region = rock_regions[rng.randi_range(0, rock_regions.size() - 1)]
			add_prop($Obstacles, ROCKS, region, point, 18.0, rng.randf() < 0.5)
			solid_positions.append(point)
			for detail in range(3):
				var nearby = point + Vector2(rng.randf_range(-42, 42), rng.randf_range(12, 40))
				if not is_on_path(nearby):
					add_prop($Decorations, ROCKS, Rect2(128 + detail * 16, 64, 16, 16), nearby)

	var details: Array[Rect2] = [Rect2(80, 176, 16, 16), Rect2(64, 144, 16, 16), Rect2(112, 160, 16, 32), Rect2(192, 160, 16, 32), Rect2(208, 160, 16, 32), Rect2(224, 176, 16, 16)]
	for index in range(300):
		var point = bounds.position + Vector2(rng.randf_range(80, bounds.size.x - 80), rng.randf_range(80, bounds.size.y - 80))
		# Keep the path clear and use fewer, shorter details in the center.
		if is_on_path(point):
			continue
		var central = clearing.has_point(point)
		if central and index % 4 != 0:
			continue
		match index % 5:
			0:
				add_prop($Decorations, ROCKS, Rect2(64, 32, 16, 16), point)
			1:
				if not central:
					add_prop($Decorations, VEGETATION, Rect2(rng.randi_range(0, 1) * 48, rng.randi_range(0, 2) * 32, 48, 32), point)
			_:
				var region = details[rng.randi_range(0, 1 if central else details.size() - 1)]
				# Small loose patches read more naturally than evenly scattered flowers.
				for detail in range(1 if central else rng.randi_range(2, 4)):
					var nearby = point + Vector2(rng.randf_range(-24, 24), rng.randf_range(-18, 18))
					if not is_on_path(nearby):
						add_prop($Decorations, VEGETATION, region, nearby)

	# A jittered carpet fills the gaps between the loose patches.
	rng.seed = 601
	var vegetation_bounds = bounds.grow(-48.0)
	for x in range(ceili(vegetation_bounds.size.x / 64.0)):
		for y in range(ceili(vegetation_bounds.size.y / 64.0)):
			var point = vegetation_bounds.position + Vector2(x * 64.0, y * 64.0) + Vector2(rng.randf_range(0, 64), rng.randf_range(0, 64))
			var central = clearing.has_point(point)
			if rng.randf() > (0.28 if central else 0.90):
				continue
			if not vegetation_bounds.has_point(point) or is_on_path(point):
				continue
			for detail in range(1 if central else rng.randi_range(1, 2)):
				var nearby = point + Vector2(rng.randf_range(-18, 18), rng.randf_range(-14, 14))
				if not vegetation_bounds.has_point(nearby) or is_on_path(nearby):
					continue
				var short_plant = central or clearing.has_point(nearby)
				var region = details[rng.randi_range(0, 1 if short_plant else details.size() - 1)]
				add_prop($Decorations, VEGETATION, region, nearby, 0.0, rng.randf() < 0.5)
			# Occasional bushes break up the low cover outside the gameplay clearing.
			if not central and rng.randf() < 0.08:
				var region = Rect2(rng.randi_range(0, 1) * 48, rng.randi_range(0, 2) * 32, 48, 32)
				add_prop($Decorations, VEGETATION, region, point, 0.0, rng.randf() < 0.5)
	scatter_berries(bounds)

func scatter_berries(bounds: Rect2) -> void:
	var berry_rng = RandomNumberGenerator.new()
	berry_rng.seed = 604
	# Loose spacing across the map, without altering the environment's random stream.
	for x in range(6):
		for y in range(3):
			for attempt in range(8):
				var point = bounds.position + (Vector2(x, y) + Vector2(berry_rng.randf_range(0.2, 0.8), berry_rng.randf_range(0.2, 0.8))) * bounds.size / Vector2(6, 3)
				if not bounds.grow(-80).has_point(point):
					continue
				var crowded = false
				for cover in canopy_rects:
					if cover.grow(24).has_point(point):
						crowded = true
						break
				if not crowded:
					for detail in detail_positions:
						if point.distance_squared_to(detail) < 28.0 * 28.0:
							crowded = true
							break
				if crowded:
					continue
				var berry = BerryPickup.new()
				berry.position = point.round()
				berry.add_to_group("berries")
				add_child(berry)
				break

func _process(delta: float) -> void:
	# Match the player's visible head/body, rather than the collision circle at its feet.
	var player_rect = Rect2(player.global_position + Vector2(-14, -42), Vector2(28, 44))
	for sprite in foreground_sprites:
		var prop = sprite.get_parent() as Node2D
		var cover = prop.get_global_transform() * prop.get_meta("visible_rect")
		var obscured = player.global_position.y < prop.global_position.y and cover.intersects(player_rect)
		sprite.modulate.a = move_toward(sprite.modulate.a, 0.68 if obscured else 1.0, delta * 2.5)

func visible_prop_rect(texture: Texture2D, region: Rect2) -> Rect2:
	var key = texture.resource_path + str(region)
	if not visible_regions.has(key):
		var pixels = texture.get_image().get_region(Rect2i(region)).get_used_rect()
		visible_regions[key] = Rect2(Vector2(pixels.position) * 2.0 - Vector2(region.size.x, region.size.y * 2.0), Vector2(pixels.size) * 2.0)
	return visible_regions[key]

func place_bush(point: Vector2, local_rect: Rect2) -> Vector2:
	var bounds: Rect2 = get_parent().world_bounds
	# Search near the original patch without changing the seeded solid placement.
	for attempt in range(33):
		var candidate = point
		if attempt > 0:
			var ring = ceili(attempt / 8.0)
			candidate += Vector2.from_angle((attempt - 1) * TAU / 8.0) * ring * 48.0
		var footprint = Rect2(candidate + local_rect.position, local_rect.size)
		if not bounds.grow(-24.0).encloses(footprint) or clearing.intersects(footprint):
			continue
		if is_on_path(candidate) or is_on_path(candidate + Vector2(local_rect.position.x, -16)) or is_on_path(candidate + Vector2(local_rect.end.x, -16)):
			continue
		var crowded = false
		for occupied in canopy_rects:
			if footprint.grow(10.0).intersects(occupied):
				crowded = true
				break
		if not crowded:
			canopy_rects.append(footprint)
			bush_rects.append(footprint)
			return candidate
	return Vector2.INF

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
	for x in range(160, int(bounds.size.x) - 159, 24):
		main_path.append(bounds.position + Vector2(x, bounds.size.y * 0.43 + sin(x * 0.003) * 110.0 + cos(x * 0.006) * 30.0))
	paths.append(main_path)
	for branch_index in range(2):
		var junction = main_path[int(main_path.size() * (0.62 if branch_index == 0 else 0.30))]
		var end_y = bounds.end.y - 180.0 if branch_index == 0 else bounds.position.y + 180.0
		var branch = PackedVector2Array()
		for step in range(49):
			var progress = step / 48.0
			branch.append(Vector2(junction.x + sin(progress * PI) * 140.0 + sin(progress * TAU) * 35.0, lerpf(junction.y, end_y, progress)))
		paths.append(branch)
	# Draw all borders first so junctions merge without seams across the dirt.
	for border in [true, false]:
		for index in range(paths.size()):
			var local_points = PackedVector2Array()
			for point in paths[index]:
				local_points.append((point - bounds.position) / 2.0)
			add_path(local_points, path_widths[index], dirt_texture, border)

func is_on_path(point: Vector2) -> bool:
	for index in range(paths.size()):
		for segment in range(paths[index].size() - 1):
			var nearest = Geometry2D.get_closest_point_to_segment(point, paths[index][segment], paths[index][segment + 1])
			if point.distance_to(nearest) < path_widths[index] * 2.0 + 26.0:
				return true
	return false

func add_path(points: PackedVector2Array, width: float, texture: Texture2D, border: bool) -> void:
	var polygon = Polygon2D.new()
	var outline = PackedVector2Array()
	for side in [1.0, -1.0]:
		for step in range(points.size()):
			var index = step if side > 0 else points.size() - 1 - step
			var previous = points[maxi(index - 1, 0)]
			var following = points[mini(index + 1, points.size() - 1)]
			var normal = (following - previous).normalized().orthogonal()
			var half_width = width + sin(index * 0.32) * 3.0 + sin(index * 0.83) * 1.0 + (2.0 if border else 0.0)
			var tip_distance = mini(index, points.size() - 1 - index)
			half_width *= lerpf(0.18, 1.0, minf(tip_distance / 4.0, 1.0))
			outline.append((points[index] + normal * half_width * side).round())
	polygon.polygon = outline
	polygon.texture = texture
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	polygon.color = Color(0.75, 0.79, 0.65) if border else Color(1, 1, 1)
	$Ground.add_child(polygon)

func can_place_solid(point: Vector2, bounds: Rect2) -> bool:
	if not bounds.grow(-100).has_point(point):
		return false
	if point.y < bounds.position.y + 208.0:
		return false
	if clearing.has_point(point) or is_on_path(point):
		return false
	if point.distance_to(get_parent().get_node("Player").position) < 180.0:
		return false
	if point.distance_to(get_parent().get_node("Enemy").position) < 120.0:
		return false
	for existing in solid_positions:
		if point.distance_to(existing) < 80.0:
			return false
	return true

func add_prop(layer: Node2D, texture: Texture2D, region: Rect2, point: Vector2, radius: float = 0.0, mirrored: bool = false) -> void:
	var local_rect = visible_prop_rect(texture, region)
	if mirrored:
		local_rect.position.x = -local_rect.end.x
	var large_bush = texture == VEGETATION and region.size.x >= 32
	if radius > 0.0:
		canopy_rects.append(Rect2(point + local_rect.position, local_rect.size))
	elif large_bush:
		point = place_bush(point, local_rect)
		if point == Vector2.INF:
			return
	else:
		# Retain plenty of low cover, but avoid piles of identical tiny plants.
		for existing in detail_positions:
			if point.distance_squared_to(existing) < 18.0 * 18.0:
				return
		for bush in bush_rects:
			if bush.has_point(point):
				return
		detail_positions.append(point)
	# Upright plants share the characters' foot-based depth; low details stay on the ground.
	if large_bush or region.size.y >= 32:
		layer = $Obstacles
	var prop: Node2D = StaticBody2D.new() if radius > 0.0 else Node2D.new()
	prop.position = point
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.flip_h = mirrored
	sprite.scale = Vector2(2, 2)
	sprite.position.y = -region.size.y
	prop.add_child(sprite)
	if large_bush or (radius > 0.0 and region.size.y >= 48):
		prop.set_meta("visible_rect", local_rect)
		foreground_sprites.append(sprite)
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
		var shadow_size = Vector2(45, 17) if texture == TREES or texture == FIRS else Vector2(25, 10)
		var outline = PackedVector2Array()
		for step in range(12):
			var angle = TAU * step / 12.0
			outline.append((Vector2(cos(angle), sin(angle)) * shadow_size).round())
		shadow.polygon = outline
		shadow.position = point + Vector2(12, -4)
		shadow.color = Color(0.07, 0.12, 0.05, 0.20)
		$Decorations.add_child(shadow)
	layer.add_child(prop)
