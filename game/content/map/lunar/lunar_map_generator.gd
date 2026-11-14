class_name LunarMapGenerator
extends RefCounted
## Deterministic procedural generator for lunar surface maps.
##
## The generator is pure: it takes a [LunarMapConfig], never touches scenes,
## nodes, autoloads, the global RNG or the clock, and returns a fully populated
## [LunarMap]. Every random stream derives from the configured seed, so the same
## configuration and seed always produce the same map.
##
## Pipeline: sanitize -> base elevation -> craters -> ridges -> rocks -> landing
## zone -> final classification -> walkability -> connectivity repair -> points
## of interest -> reachability.

const BASE_NOISE_FREQUENCY: float = 0.035
const BASE_MARE_THRESHOLD: float = 0.48

const CRATER_FLOOR_DEPTH: float = 0.22
const CRATER_RIM_HEIGHT: float = 0.10
const CRATER_RIM_MULTIPLIER: float = 1.15
const CRATER_EJECTA_HEIGHT: float = 0.05

const RIDGE_MIN_STEPS: int = 6
const RIDGE_MAX_STEPS: int = 18
const RIDGE_MAX_TURN: float = 0.4

const CONNECTIVITY_PASSES: int = 3
const POI_RELAX_ROUNDS: int = 3
const POI_RELAX_FACTOR: float = 0.75
const POI_MIN_ATTEMPTS: int = 1000
const POI_MAX_SAMPLED_CANDIDATES: int = 10000

const SEED_SALT_CRATERS: int = 0x1F123BB5
const SEED_SALT_RIDGES: int = 0x2A9F1C3D
const SEED_SALT_ROCKS: int = 0x3C6EF372
const SEED_SALT_POIS: int = 0x4B7A70E9

const TERRAIN_MARE: int = LunarMap.Terrain.MARE
const TERRAIN_HIGHLAND: int = LunarMap.Terrain.HIGHLAND
const TERRAIN_CRATER_FLOOR: int = LunarMap.Terrain.CRATER_FLOOR
const TERRAIN_CRATER_RIM: int = LunarMap.Terrain.CRATER_RIM
const TERRAIN_EJECTA: int = LunarMap.Terrain.EJECTA
const TERRAIN_RIDGE: int = LunarMap.Terrain.RIDGE
const TERRAIN_ROCK: int = LunarMap.Terrain.ROCK
const TERRAIN_LANDING_PAD: int = LunarMap.Terrain.LANDING_PAD

const BEST_DISTANCE_UNSET: int = 0x3FFFFFFF


## Builds a complete lunar map from [param config].
##
## A null configuration means [code]LunarMapConfig.new()[/code]. Invalid values
## are clamped and reported in [member LunarMap.warnings]; generation never
## aborts because of a bad configuration.
static func generate(config: LunarMapConfig) -> LunarMap:
	var map: LunarMap = LunarMap.new()
	var effective: LunarMapConfig = _sanitize_config(config, map.warnings)

	var tile_count: int = effective.width * effective.height
	map.width = effective.width
	map.height = effective.height
	map.tile_size = effective.tile_size
	map.seed = effective.seed

	map.terrain.resize(tile_count)
	map.elevation.resize(tile_count)
	map.walkable.resize(tile_count)
	map.reachable.resize(tile_count)
	map.walkable.fill(0)
	map.reachable.fill(0)

	_setup_landing_center(effective, map)
	_build_base_elevation(map)

	var floor_mask: PackedByteArray = _new_mask(tile_count)
	var rim_mask: PackedByteArray = _new_mask(tile_count)
	var ejecta_mask: PackedByteArray = _new_mask(tile_count)
	_place_craters(effective, map, floor_mask, rim_mask, ejecta_mask)
	_place_ridges(effective, map)
	_place_rocks(effective, map)
	_flatten_landing_zone(effective, map)
	_classify_terrain(map, floor_mask, rim_mask, ejecta_mask)
	_compute_walkable(map)

	var component: PackedInt32Array = PackedInt32Array()
	component.resize(tile_count)
	var component_count: int = _label_components(map, component)
	if component_count > 1:
		component_count = _connect_components(map, component, component_count)

	var spawn_component: int = -1
	var spawn_index: int = map.get_index(map.spawn_tile)
	if spawn_index >= 0:
		spawn_component = component[spawn_index]
	_place_pois(effective, map, component, spawn_component)
	_compute_reachable(map)

	return map


# ---------------------------------------------------------------------------
# Configuration sanitization
# ---------------------------------------------------------------------------


static func _sanitize_config(config: LunarMapConfig, warnings: Array[String]) -> LunarMapConfig:
	var sanitized: LunarMapConfig = null
	if config == null:
		sanitized = LunarMapConfig.new()
	else:
		var duplicate: Resource = config.duplicate()
		sanitized = duplicate as LunarMapConfig
		if sanitized == null:
			sanitized = LunarMapConfig.new()
			warnings.append("configuration could not be duplicated; default values are used")

	for message: String in sanitized.validate():
		warnings.append(message)

	sanitized.width = _clamp_int(
		sanitized.width,
		LunarMapConfig.MIN_MAP_SIZE,
		LunarMapConfig.MAX_MAP_SIZE,
		"width",
		warnings
	)
	sanitized.height = _clamp_int(
		sanitized.height,
		LunarMapConfig.MIN_MAP_SIZE,
		LunarMapConfig.MAX_MAP_SIZE,
		"height",
		warnings
	)
	sanitized.tile_size = _clamp_int(
		sanitized.tile_size,
		LunarMapConfig.MIN_TILE_SIZE,
		LunarMapConfig.MAX_TILE_SIZE,
		"tile_size",
		warnings
	)
	sanitized.crater_density = _clamp_float_range(
		sanitized.crater_density,
		LunarMapConfig.CRATER_DENSITY_MIN,
		LunarMapConfig.CRATER_DENSITY_MAX,
		"crater_density",
		warnings
	)
	sanitized.rock_density = _clamp_float_range(
		sanitized.rock_density,
		LunarMapConfig.ROCK_DENSITY_MIN,
		LunarMapConfig.ROCK_DENSITY_MAX,
		"rock_density",
		warnings
	)
	sanitized.ridge_density = _clamp_float_range(
		sanitized.ridge_density,
		LunarMapConfig.RIDGE_DENSITY_MIN,
		LunarMapConfig.RIDGE_DENSITY_MAX,
		"ridge_density",
		warnings
	)
	sanitized.min_crater_radius = _clamp_float_range(
		sanitized.min_crater_radius,
		LunarMapConfig.MIN_CRATER_RADIUS_MIN,
		LunarMapConfig.MIN_CRATER_RADIUS_MAX,
		"min_crater_radius",
		warnings
	)
	# The lower bound is the already sanitized minimum radius, so the pair stays
	# ordered even when the requested range was inverted.
	sanitized.max_crater_radius = _clamp_float_range(
		sanitized.max_crater_radius,
		sanitized.min_crater_radius,
		LunarMapConfig.MAX_CRATER_RADIUS_MAX,
		"max_crater_radius",
		warnings
	)
	sanitized.ejecta_radius_multiplier = _clamp_float_range(
		sanitized.ejecta_radius_multiplier,
		LunarMapConfig.EJECTA_RADIUS_MULTIPLIER_MIN,
		LunarMapConfig.EJECTA_RADIUS_MULTIPLIER_MAX,
		"ejecta_radius_multiplier",
		warnings
	)
	var max_landing_radius: int = mini(sanitized.width, sanitized.height) / 4
	sanitized.landing_zone_radius = _clamp_int(
		sanitized.landing_zone_radius,
		1,
		max_landing_radius,
		"landing_zone_radius",
		warnings
	)
	sanitized.poi_count = _clamp_int(
		sanitized.poi_count, 1, LunarMapConfig.MAX_POI_COUNT, "poi_count", warnings
	)
	sanitized.poi_min_distance = _clamp_float_range(
		sanitized.poi_min_distance,
		LunarMapConfig.POI_DISTANCE_MIN,
		LunarMapConfig.POI_DISTANCE_MAX,
		"poi_min_distance",
		warnings
	)
	sanitized.poi_min_separation = _clamp_float_range(
		sanitized.poi_min_separation,
		LunarMapConfig.POI_DISTANCE_MIN,
		LunarMapConfig.POI_DISTANCE_MAX,
		"poi_min_separation",
		warnings
	)

	return sanitized


static func _clamp_int(
	value: int, minimum: int, maximum: int, field: String, warnings: Array[String]
) -> int:
	var clamped: int = clampi(value, minimum, maximum)
	if clamped != value:
		warnings.append(
			"%s clamped from %d to %d (valid range [%d, %d])"
			% [field, value, clamped, minimum, maximum]
		)
	return clamped


static func _clamp_float_range(
	value: float, minimum: float, maximum: float, field: String, warnings: Array[String]
) -> float:
	if not is_finite(value):
		warnings.append("%s is not finite and was reset to %s" % [field, str(minimum)])
		return minimum
	var clamped: float = clampf(value, minimum, maximum)
	if clamped != value:
		warnings.append(
			"%s clamped from %s to %s (valid range [%s, %s])"
			% [field, str(value), str(clamped), str(minimum), str(maximum)]
		)
	return clamped


# ---------------------------------------------------------------------------
# Base elevation and early landing center
# ---------------------------------------------------------------------------


static func _setup_landing_center(config: LunarMapConfig, map: LunarMap) -> void:
	var radius: int = config.landing_zone_radius
	var requested: Vector2i = config.landing_zone_center
	if requested.x == -1 and requested.y == -1:
		requested = Vector2i(config.width / 2, config.height / 2)

	var clamped_center: Vector2i = Vector2i(
		clampi(requested.x, radius, config.width - 1 - radius),
		clampi(requested.y, radius, config.height - 1 - radius)
	)
	if clamped_center != requested:
		map.warnings.append(
			"landing_zone_center adjusted from (%d, %d) to (%d, %d) to keep the zone inside the map"
			% [requested.x, requested.y, clamped_center.x, clamped_center.y]
		)
	map.landing_zone_center = clamped_center


static func _build_base_elevation(map: LunarMap) -> void:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = map.seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.frequency = BASE_NOISE_FREQUENCY
	noise.fractal_gain = 0.5

	var width: int = map.width
	for index: int in range(map.width * map.height):
		var x: int = index % width
		var y: int = index / width
		var elevation_value: float = clampf(
			(noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5, 0.0, 1.0
		)
		map.elevation[index] = elevation_value
		if elevation_value < BASE_MARE_THRESHOLD:
			map.terrain[index] = TERRAIN_MARE
		else:
			map.terrain[index] = TERRAIN_HIGHLAND


# ---------------------------------------------------------------------------
# Craters
# ---------------------------------------------------------------------------


static func _place_craters(
	config: LunarMapConfig,
	map: LunarMap,
	floor_mask: PackedByteArray,
	rim_mask: PackedByteArray,
	ejecta_mask: PackedByteArray
) -> void:
	var count: int = maxi(0, roundi(float(config.width * config.height) * config.crater_density))
	if count == 0:
		return

	var rng: RandomNumberGenerator = _make_rng(config.seed, SEED_SALT_CRATERS)
	var landing_center: Vector2 = Vector2(map.landing_zone_center)
	var exclusion: float = float(config.landing_zone_radius) + 2.0
	var exclusion_squared: float = exclusion * exclusion

	for _crater_index: int in range(count):
		var center: Vector2 = Vector2(
			rng.randf_range(0.0, float(config.width - 1)),
			rng.randf_range(0.0, float(config.height - 1))
		)
		if center.distance_squared_to(landing_center) < exclusion_squared:
			continue
		var radius: float = rng.randf_range(
			config.min_crater_radius, config.max_crater_radius
		)
		_carve_crater(
			map,
			floor_mask,
			rim_mask,
			ejecta_mask,
			center,
			radius,
			config.ejecta_radius_multiplier
		)


static func _carve_crater(
	map: LunarMap,
	floor_mask: PackedByteArray,
	rim_mask: PackedByteArray,
	ejecta_mask: PackedByteArray,
	center: Vector2,
	radius: float,
	ejecta_multiplier: float
) -> void:
	if radius <= 0.0:
		return

	var rim_radius: float = radius * CRATER_RIM_MULTIPLIER
	var ejecta_radius: float = maxf(rim_radius, radius * ejecta_multiplier)
	var outer_radius: float = maxf(rim_radius, ejecta_radius)
	var min_x: int = maxi(0, floori(center.x - outer_radius))
	var max_x: int = mini(map.width - 1, ceili(center.x + outer_radius))
	var min_y: int = maxi(0, floori(center.y - outer_radius))
	var max_y: int = mini(map.height - 1, ceili(center.y + outer_radius))
	var rim_span: float = maxf(rim_radius - radius, 0.001)
	var ejecta_span: float = maxf(ejecta_radius - rim_radius, 0.001)

	for y: int in range(min_y, max_y + 1):
		for x: int in range(min_x, max_x + 1):
			var offset: Vector2 = Vector2(float(x), float(y)) - center
			var distance: float = offset.length()
			if distance > outer_radius:
				continue
			var index: int = y * map.width + x
			if distance <= radius:
				var normalized: float = distance / radius
				var depth: float = CRATER_FLOOR_DEPTH * (1.0 - normalized * normalized)
				map.elevation[index] = clampf(map.elevation[index] - depth, 0.0, 1.0)
				floor_mask[index] = 1
			elif distance <= rim_radius:
				var rim_factor: float = 1.0 - (distance - radius) / rim_span
				map.elevation[index] = clampf(
					map.elevation[index] + CRATER_RIM_HEIGHT * rim_factor, 0.0, 1.0
				)
				rim_mask[index] = 1
			elif distance <= ejecta_radius:
				var ejecta_factor: float = 1.0 - (distance - rim_radius) / ejecta_span
				map.elevation[index] = clampf(
					map.elevation[index] + CRATER_EJECTA_HEIGHT * ejecta_factor, 0.0, 1.0
				)
				ejecta_mask[index] = 1


# ---------------------------------------------------------------------------
# Ridges
# ---------------------------------------------------------------------------


static func _place_ridges(config: LunarMapConfig, map: LunarMap) -> void:
	var count: int = maxi(0, roundi(float(config.width * config.height) * config.ridge_density))
	if count == 0:
		return

	var rng: RandomNumberGenerator = _make_rng(config.seed, SEED_SALT_RIDGES)
	for _ridge_index: int in range(count):
		var position: Vector2 = Vector2(
			rng.randf_range(0.0, float(config.width - 1)),
			rng.randf_range(0.0, float(config.height - 1))
		)
		var angle: float = rng.randf_range(0.0, TAU)
		var steps: int = rng.randi_range(RIDGE_MIN_STEPS, RIDGE_MAX_STEPS)
		var previous: Vector2i = Vector2i(floori(position.x), floori(position.y))
		_mark_ridge_tile(map, previous)

		for _step: int in range(1, steps):
			angle += rng.randf_range(-RIDGE_MAX_TURN, RIDGE_MAX_TURN)
			position += Vector2(cos(angle), sin(angle))
			if (
				position.x < 0.0
				or position.x > float(config.width - 1)
				or position.y < 0.0
				or position.y > float(config.height - 1)
			):
				break
			var next_tile: Vector2i = Vector2i(floori(position.x), floori(position.y))
			if next_tile == previous:
				continue
			_rasterize_ridge_line(map, previous, next_tile)
			previous = next_tile


## Marks [param tile] as a ridge. Ridges are placed before the landing zone is
## flattened, so no LANDING_PAD tile can exist here yet; the later flatten pass
## overwrites the zone anyway.
static func _mark_ridge_tile(map: LunarMap, tile: Vector2i) -> void:
	var index: int = map.get_index(tile)
	if index < 0:
		return
	map.terrain[index] = TERRAIN_RIDGE


static func _rasterize_ridge_line(map: LunarMap, from_tile: Vector2i, to_tile: Vector2i) -> void:
	var tiles: Array[Vector2i] = _bresenham_tiles(from_tile, to_tile)
	for tile: Vector2i in tiles:
		_mark_ridge_tile(map, tile)


# ---------------------------------------------------------------------------
# Rocks
# ---------------------------------------------------------------------------


static func _place_rocks(config: LunarMapConfig, map: LunarMap) -> void:
	var count: int = maxi(0, roundi(float(config.width * config.height) * config.rock_density))
	if count == 0:
		return

	var rng: RandomNumberGenerator = _make_rng(config.seed, SEED_SALT_ROCKS)
	var attempts_limit: int = maxi(100, count * 20)
	var attempts: int = 0
	var placed: int = 0
	var landing_center: Vector2i = map.landing_zone_center
	var landing_radius_squared: int = config.landing_zone_radius * config.landing_zone_radius
	var tile_count: int = config.width * config.height

	while placed < count and attempts < attempts_limit:
		attempts += 1
		var index: int = rng.randi_range(0, tile_count - 1)
		var terrain_value: int = map.terrain[index]
		if terrain_value == TERRAIN_ROCK or terrain_value == TERRAIN_RIDGE:
			continue
		var x: int = index % config.width
		var y: int = index / config.width
		var offset_x: int = x - landing_center.x
		var offset_y: int = y - landing_center.y
		if offset_x * offset_x + offset_y * offset_y <= landing_radius_squared:
			continue
		map.terrain[index] = TERRAIN_ROCK
		placed += 1

	if placed < count:
		map.warnings.append(
			"placed %d of %d rocks; the map has too few free tiles" % [placed, count]
		)


# ---------------------------------------------------------------------------
# Landing zone, classification and walkability
# ---------------------------------------------------------------------------


static func _flatten_landing_zone(config: LunarMapConfig, map: LunarMap) -> void:
	var center: Vector2i = map.landing_zone_center
	var radius: int = config.landing_zone_radius
	var radius_squared: int = radius * radius
	var min_x: int = maxi(0, center.x - radius)
	var max_x: int = mini(map.width - 1, center.x + radius)
	var min_y: int = maxi(0, center.y - radius)
	var max_y: int = mini(map.height - 1, center.y + radius)

	var elevation_sum: float = 0.0
	var samples: int = 0
	for y: int in range(min_y, max_y + 1):
		for x: int in range(min_x, max_x + 1):
			var offset_x: int = x - center.x
			var offset_y: int = y - center.y
			if offset_x * offset_x + offset_y * offset_y > radius_squared:
				continue
			elevation_sum += map.elevation[y * map.width + x]
			samples += 1

	var mean_elevation: float = 0.5
	if samples > 0:
		mean_elevation = clampf(elevation_sum / float(samples), 0.0, 1.0)

	for y: int in range(min_y, max_y + 1):
		for x: int in range(min_x, max_x + 1):
			var offset_x: int = x - center.x
			var offset_y: int = y - center.y
			if offset_x * offset_x + offset_y * offset_y > radius_squared:
				continue
			var index: int = y * map.width + x
			map.terrain[index] = TERRAIN_LANDING_PAD
			map.elevation[index] = mean_elevation
			map.walkable[index] = 1

	map.spawn_tile = center


static func _classify_terrain(
	map: LunarMap,
	floor_mask: PackedByteArray,
	rim_mask: PackedByteArray,
	ejecta_mask: PackedByteArray
) -> void:
	for index: int in range(map.width * map.height):
		var terrain_value: int = map.terrain[index]
		if (
			terrain_value == TERRAIN_LANDING_PAD
			or terrain_value == TERRAIN_ROCK
			or terrain_value == TERRAIN_RIDGE
		):
			continue
		if floor_mask[index] == 1:
			map.terrain[index] = TERRAIN_CRATER_FLOOR
		elif rim_mask[index] == 1:
			map.terrain[index] = TERRAIN_CRATER_RIM
		elif ejecta_mask[index] == 1:
			map.terrain[index] = TERRAIN_EJECTA
		elif map.elevation[index] < BASE_MARE_THRESHOLD:
			map.terrain[index] = TERRAIN_MARE
		else:
			map.terrain[index] = TERRAIN_HIGHLAND


static func _compute_walkable(map: LunarMap) -> void:
	for index: int in range(map.width * map.height):
		var terrain_value: int = map.terrain[index]
		if terrain_value == TERRAIN_ROCK or terrain_value == TERRAIN_RIDGE:
			map.walkable[index] = 0
		else:
			map.walkable[index] = 1


# ---------------------------------------------------------------------------
# Connectivity
# ---------------------------------------------------------------------------


## Labels every walkable tile with a component id and returns the count.
## [param component] is resized and filled with -1 for non-walkable tiles.
static func _label_components(map: LunarMap, component: PackedInt32Array) -> int:
	var tile_count: int = map.width * map.height
	component.resize(tile_count)
	component.fill(-1)

	var queue: PackedInt32Array = PackedInt32Array()
	queue.resize(tile_count)
	var width: int = map.width
	var height: int = map.height
	var next_component: int = 0

	for start: int in range(tile_count):
		if map.walkable[start] != 1 or component[start] != -1:
			continue
		var head: int = 0
		var tail: int = 0
		queue[tail] = start
		tail += 1
		component[start] = next_component

		while head < tail:
			var index: int = queue[head]
			head += 1
			var x: int = index % width
			var y: int = index / width
			if x > 0:
				var left: int = index - 1
				if map.walkable[left] == 1 and component[left] == -1:
					component[left] = next_component
					queue[tail] = left
					tail += 1
			if x + 1 < width:
				var right: int = index + 1
				if map.walkable[right] == 1 and component[right] == -1:
					component[right] = next_component
					queue[tail] = right
					tail += 1
			if y > 0:
				var up: int = index - width
				if map.walkable[up] == 1 and component[up] == -1:
					component[up] = next_component
					queue[tail] = up
					tail += 1
			if y + 1 < height:
				var down: int = index + width
				if map.walkable[down] == 1 and component[down] == -1:
					component[down] = next_component
					queue[tail] = down
					tail += 1
		next_component += 1

	return next_component


## Carves corridors until the walkable grid has a single component.
## Returns the component count after at most [constant CONNECTIVITY_PASSES] passes.
static func _connect_components(
	map: LunarMap, component: PackedInt32Array, component_count: int
) -> int:
	var current_count: int = component_count
	var passes: int = 0
	while current_count > 1 and passes < CONNECTIVITY_PASSES:
		if not _repair_isolated_components(map, component, current_count):
			break
		current_count = _label_components(map, component)
		passes += 1

	if current_count > 1:
		map.warnings.append(
			"map still has %d disconnected walkable regions after %d connectivity passes"
			% [current_count, passes]
		)
	return current_count


## Builds a multi-source BFS from the spawn component over every grid tile and
## carves one corridor from each isolated component to its nearest main tile.
static func _repair_isolated_components(
	map: LunarMap, component: PackedInt32Array, component_count: int
) -> bool:
	var spawn_index: int = map.get_index(map.spawn_tile)
	if spawn_index < 0 or map.walkable[spawn_index] != 1:
		return false
	var spawn_component: int = component[spawn_index]
	if spawn_component < 0:
		return false

	var tile_count: int = map.width * map.height
	var distance: PackedInt32Array = PackedInt32Array()
	distance.resize(tile_count)
	distance.fill(-1)
	var nearest: PackedInt32Array = PackedInt32Array()
	nearest.resize(tile_count)
	nearest.fill(-1)
	var queue: PackedInt32Array = PackedInt32Array()
	queue.resize(tile_count)
	var width: int = map.width
	var height: int = map.height
	var head: int = 0
	var tail: int = 0

	for index: int in range(tile_count):
		if component[index] == spawn_component:
			distance[index] = 0
			nearest[index] = index
			queue[tail] = index
			tail += 1

	while head < tail:
		var index: int = queue[head]
		head += 1
		var next_distance: int = distance[index] + 1
		var source: int = nearest[index]
		var x: int = index % width
		var y: int = index / width
		if x > 0:
			var left: int = index - 1
			if distance[left] == -1:
				distance[left] = next_distance
				nearest[left] = source
				queue[tail] = left
				tail += 1
		if x + 1 < width:
			var right: int = index + 1
			if distance[right] == -1:
				distance[right] = next_distance
				nearest[right] = source
				queue[tail] = right
				tail += 1
		if y > 0:
			var up: int = index - width
			if distance[up] == -1:
				distance[up] = next_distance
				nearest[up] = source
				queue[tail] = up
				tail += 1
		if y + 1 < height:
			var down: int = index + width
			if distance[down] == -1:
				distance[down] = next_distance
				nearest[down] = source
				queue[tail] = down
				tail += 1

	var best_distance: PackedInt32Array = PackedInt32Array()
	best_distance.resize(component_count)
	best_distance.fill(BEST_DISTANCE_UNSET)
	var best_index: PackedInt32Array = PackedInt32Array()
	best_index.resize(component_count)
	best_index.fill(-1)

	for index: int in range(tile_count):
		var component_id: int = component[index]
		if component_id < 0 or component_id == spawn_component:
			continue
		var tile_distance: int = distance[index]
		if tile_distance < 0:
			continue
		if tile_distance < best_distance[component_id]:
			best_distance[component_id] = tile_distance
			best_index[component_id] = index

	var repaired: bool = false
	for component_id: int in range(component_count):
		if component_id == spawn_component:
			continue
		var isolated_index: int = best_index[component_id]
		if isolated_index < 0:
			continue
		var target_index: int = nearest[isolated_index]
		if target_index < 0:
			continue
		var from_tile: Vector2i = Vector2i(isolated_index % width, isolated_index / width)
		var to_tile: Vector2i = Vector2i(target_index % width, target_index / width)
		_carve_corridor(map, from_tile, to_tile)
		repaired = true

	return repaired


## Carves a 4-connected corridor along a Bresenham line.
## Diagonal Bresenham steps also carve one orthogonal corner tile so the result
## stays connected with 4-neighbour walkability.
static func _carve_corridor(map: LunarMap, from_tile: Vector2i, to_tile: Vector2i) -> void:
	var tiles: Array[Vector2i] = _bresenham_tiles(from_tile, to_tile)
	if tiles.is_empty():
		return

	var previous: Vector2i = tiles[0]
	_make_corridor_tile(map, previous)
	for offset: int in range(1, tiles.size()):
		var current: Vector2i = tiles[offset]
		if current.x != previous.x and current.y != previous.y:
			_make_corridor_tile(map, Vector2i(current.x, previous.y))
		_make_corridor_tile(map, current)
		previous = current


static func _make_corridor_tile(map: LunarMap, tile: Vector2i) -> void:
	var index: int = map.get_index(tile)
	if index < 0:
		return
	var terrain_value: int = map.terrain[index]
	if terrain_value == TERRAIN_ROCK or terrain_value == TERRAIN_RIDGE:
		if map.elevation[index] < BASE_MARE_THRESHOLD:
			map.terrain[index] = TERRAIN_MARE
		else:
			map.terrain[index] = TERRAIN_HIGHLAND
	map.walkable[index] = 1


# ---------------------------------------------------------------------------
# Points of interest and reachability
# ---------------------------------------------------------------------------


static func _place_pois(
	config: LunarMapConfig,
	map: LunarMap,
	component: PackedInt32Array,
	spawn_component: int
) -> void:
	var candidates: Array[int] = []
	var spawn_index: int = map.get_index(map.spawn_tile)
	for index: int in range(map.width * map.height):
		if map.walkable[index] != 1:
			continue
		if component[index] != spawn_component:
			continue
		if index == spawn_index:
			continue
		if map.terrain[index] == TERRAIN_LANDING_PAD:
			continue
		candidates.append(index)

	if candidates.is_empty():
		map.warnings.append("no valid point of interest candidates were found")
		return

	var rng: RandomNumberGenerator = _make_rng(config.seed, SEED_SALT_POIS)
	var selected: Array[Vector2i] = []
	var target: int = config.poi_count
	var used_relaxation: bool = false

	for round_index: int in range(POI_RELAX_ROUNDS):
		if selected.size() >= target:
			break
		if round_index > 0:
			used_relaxation = true

		var separation_factor: float = 1.0
		var distance_factor: float = 1.0
		if round_index >= 1:
			separation_factor = POI_RELAX_FACTOR
		if round_index >= 2:
			distance_factor = POI_RELAX_FACTOR
		var separation_squared: float = pow(
			config.poi_min_separation * separation_factor, 2.0
		)
		var min_distance_squared: float = pow(
			config.poi_min_distance * distance_factor, 2.0
		)
		var attempts: int = maxi(
			POI_MIN_ATTEMPTS, mini(candidates.size(), POI_MAX_SAMPLED_CANDIDATES) * 2
		)

		for _attempt: int in range(attempts):
			if selected.size() >= target:
				break
			var candidate_index: int = candidates[rng.randi_range(0, candidates.size() - 1)]
			var tile: Vector2i = Vector2i(
				candidate_index % map.width, candidate_index / map.width
			)
			if selected.has(tile):
				continue
			if _tile_distance_squared(tile, map.spawn_tile) < min_distance_squared:
				continue
			if _has_close_poi(tile, selected, separation_squared):
				continue
			selected.append(tile)

	if selected.size() < target:
		used_relaxation = true
		var sorted_candidates: Array[int] = candidates.duplicate()
		sorted_candidates.sort_custom(
			_compare_candidate_distance_desc.bind(map.spawn_tile, map.width)
		)
		for candidate_index: int in sorted_candidates:
			if selected.size() >= target:
				break
			var tile: Vector2i = Vector2i(
				candidate_index % map.width, candidate_index / map.width
			)
			if selected.has(tile):
				continue
			selected.append(tile)

	if selected.size() < target:
		map.warnings.append(
			"only %d of %d points of interest could be placed; not enough valid candidates"
			% [selected.size(), target]
		)
	elif used_relaxation:
		map.warnings.append(
			"point of interest constraints were relaxed; placed %d of %d"
			% [selected.size(), target]
		)

	map.poi_tiles = selected


static func _has_close_poi(
	tile: Vector2i, selected: Array[Vector2i], separation_squared: float
) -> bool:
	for other: Vector2i in selected:
		if _tile_distance_squared(tile, other) < separation_squared:
			return true
	return false


static func _compare_candidate_distance_desc(
	a: int, b: int, spawn: Vector2i, width: int
) -> bool:
	var tile_a: Vector2i = Vector2i(a % width, a / width)
	var tile_b: Vector2i = Vector2i(b % width, b / width)
	var distance_a: float = _tile_distance_squared(tile_a, spawn)
	var distance_b: float = _tile_distance_squared(tile_b, spawn)
	if distance_a == distance_b:
		return a < b
	return distance_a > distance_b


static func _tile_distance_squared(a: Vector2i, b: Vector2i) -> float:
	var offset_x: float = float(a.x - b.x)
	var offset_y: float = float(a.y - b.y)
	return offset_x * offset_x + offset_y * offset_y


static func _compute_reachable(map: LunarMap) -> void:
	map.reachable.fill(0)
	var spawn_index: int = map.get_index(map.spawn_tile)
	if spawn_index < 0 or map.walkable[spawn_index] != 1:
		map.warnings.append("spawn tile is outside the map or not walkable")
		return

	var queue: PackedInt32Array = PackedInt32Array()
	queue.resize(map.width * map.height)
	var width: int = map.width
	var height: int = map.height
	var head: int = 0
	var tail: int = 1
	queue[0] = spawn_index
	map.reachable[spawn_index] = 1

	while head < tail:
		var index: int = queue[head]
		head += 1
		var x: int = index % width
		var y: int = index / width
		if x > 0:
			var left: int = index - 1
			if map.walkable[left] == 1 and map.reachable[left] == 0:
				map.reachable[left] = 1
				queue[tail] = left
				tail += 1
		if x + 1 < width:
			var right: int = index + 1
			if map.walkable[right] == 1 and map.reachable[right] == 0:
				map.reachable[right] = 1
				queue[tail] = right
				tail += 1
		if y > 0:
			var up: int = index - width
			if map.walkable[up] == 1 and map.reachable[up] == 0:
				map.reachable[up] = 1
				queue[tail] = up
				tail += 1
		if y + 1 < height:
			var down: int = index + width
			if map.walkable[down] == 1 and map.reachable[down] == 0:
				map.reachable[down] = 1
				queue[tail] = down
				tail += 1


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------


static func _new_mask(tile_count: int) -> PackedByteArray:
	var mask: PackedByteArray = PackedByteArray()
	mask.resize(tile_count)
	mask.fill(0)
	return mask


static func _make_rng(base_seed: int, salt: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _derive_seed(base_seed, salt)
	return rng


## Mixes the configured seed with a stage salt. Mixing keeps the stages
## independent, so changing one density does not shift the other features.
static func _derive_seed(base_seed: int, salt: int) -> int:
	var value: int = base_seed + salt * 0x9E3779B1
	value = value ^ (value >> 33)
	value = value * 0xFF51AFD7
	value = value ^ (value >> 29)
	return value


## Returns every tile of the line from [param from_tile] to [param to_tile],
## endpoints included. Standard integer Bresenham.
static func _bresenham_tiles(from_tile: Vector2i, to_tile: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var x: int = from_tile.x
	var y: int = from_tile.y
	var delta_x: int = absi(to_tile.x - x)
	var step_x: int = 1 if x < to_tile.x else -1
	var delta_y: int = -absi(to_tile.y - y)
	var step_y: int = 1 if y < to_tile.y else -1
	var error: int = delta_x + delta_y

	while true:
		tiles.append(Vector2i(x, y))
		if x == to_tile.x and y == to_tile.y:
			break
		var doubled_error: int = 2 * error
		if doubled_error >= delta_y:
			error += delta_y
			x += step_x
		if doubled_error <= delta_x:
			error += delta_x
			y += step_y

	return tiles
