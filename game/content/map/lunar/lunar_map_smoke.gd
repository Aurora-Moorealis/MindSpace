extends SceneTree
## Headless smoke test for the procedural lunar map generator.
##
## Builds several maps in memory and checks the observable contract of the
## module: configuration sanitization, determinism, terrain features, landing
## zone, connectivity, points of interest, coordinate conversions, custom map
## sizes, hostile maximums and the maximum map size. It needs no scene, node,
## autoload or asset.
##
## Run with:
##   godot --headless --path game --script res://content/map/lunar/lunar_map_smoke.gd
##
## Exits with code 0 when every check passes and 1 otherwise.

const ConfigScript: GDScript = preload("res://content/map/lunar/lunar_map_config.gd")
const MapScript: GDScript = preload("res://content/map/lunar/lunar_map.gd")
const GeneratorScript: GDScript = preload("res://content/map/lunar/lunar_map_generator.gd")

const TERRAIN_MARE: int = 0
const TERRAIN_HIGHLAND: int = 1
const TERRAIN_CRATER_FLOOR: int = 2
const TERRAIN_CRATER_RIM: int = 3
const TERRAIN_EJECTA: int = 4
const TERRAIN_RIDGE: int = 5
const TERRAIN_ROCK: int = 6
const TERRAIN_LANDING_PAD: int = 7
const TERRAIN_INVALID: int = -1
const TERRAIN_COUNT: int = 8

const MIN_MAP_SIZE: int = 16
const MAX_MAP_SIZE: int = 256
const MIN_TILE_SIZE: int = 8
const MAX_TILE_SIZE: int = 64
const LARGE_MAP_TARGET_MS: float = 2000.0
const HOSTILE_MAP_TARGET_MS: float = 5000.0
const DISTANCE_EPSILON: float = 0.0001
const FLAT_ELEVATION_EPSILON: float = 0.00001

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_check_defaults_and_clamps()
	_check_determinism()
	_check_seed_variation()
	_check_default_features()
	_check_disabled_features()
	_check_landing_zone()
	_check_connectivity()
	_check_points_of_interest()
	_check_coordinate_conversions()
	_check_custom_size()
	_check_hostile_maxima()
	_check_large_map()
	_check_small_map()
	_check_sanitization()

	print("lunar_map_smoke: %d checks, %d failure(s)" % [_checks, _failures])
	if _failures == 0:
		print("lunar_map_smoke: PASSED")
		quit(0)
	else:
		printerr("lunar_map_smoke: FAILED")
		quit(1)


# ---------------------------------------------------------------------------
# Check 1: default configuration and sanitization of invalid values
# ---------------------------------------------------------------------------


func _check_defaults_and_clamps() -> void:
	var defaults: LunarMapConfig = _new_config()
	_check(defaults.width == 64, "default config width is 64")
	_check(defaults.height == 64, "default config height is 64")
	_check(defaults.tile_size == 32, "default config tile size is 32")
	_check(defaults.seed == 1, "default config seed is 1")
	_check(defaults.poi_count == 3, "default config poi_count is 3")
	_check(defaults.validate().is_empty(), "default config validates without errors")

	var map: LunarMap = _generate(defaults)
	_check(map.width == 64 and map.height == 64, "default map is 64x64 tiles")
	_check(map.tile_size == 32, "default map uses 32 px tiles")
	_check(map.seed == defaults.seed, "map keeps the requested seed")
	_check(map.get_script() == MapScript, "generator returns the preloaded LunarMap script")
	_check(map.warnings.is_empty(), "default map needs no warnings")
	_check_map_invariants(map, "default")

	var broken: LunarMapConfig = _new_config()
	broken.width = 1
	broken.height = 9999
	broken.tile_size = 0
	broken.crater_density = -0.5
	broken.rock_density = -1.0
	broken.ridge_density = -0.25
	broken.min_crater_radius = 12.0
	broken.max_crater_radius = 3.0
	broken.poi_count = 9
	broken.poi_min_distance = -10.0
	broken.poi_min_separation = -8.0
	broken.landing_zone_radius = 0
	_check(broken.validate().size() >= 10, "invalid config reports every problem")

	var broken_map: LunarMap = _generate(broken)
	_check(
		broken_map.width == MIN_MAP_SIZE and broken_map.height == MAX_MAP_SIZE,
		"map size clamps to 16x256 tiles"
	)
	_check(broken_map.tile_size == MIN_TILE_SIZE, "tile size clamps to 8 px")
	_check(not broken_map.warnings.is_empty(), "invalid config produces warnings")
	_check(_has_warning_containing(broken_map, "width"), "warnings mention the width clamp")
	_check(_has_warning_containing(broken_map, "height"), "warnings mention the height clamp")
	_check(_has_warning_containing(broken_map, "tile_size"), "warnings mention the tile size clamp")
	_check(_has_warning_containing(broken_map, "poi_count"), "warnings mention the poi_count clamp")
	_check_map_invariants(broken_map, "clamped config")

	var zero_poi_config: LunarMapConfig = _new_config()
	zero_poi_config.poi_count = 0
	var zero_poi_map: LunarMap = _generate(zero_poi_config)
	_check(not zero_poi_map.poi_tiles.is_empty(), "poi_count 0 clamps to a usable count")
	_check(_has_warning_containing(zero_poi_map, "poi_count"), "poi_count 0 produces a warning")
	_check(_pois_are_valid(zero_poi_map), "poi_count 0 still places valid POIs")
	_check_map_invariants(zero_poi_map, "poi_count 0")


# ---------------------------------------------------------------------------
# Check 2: determinism with the same configuration and seed
# ---------------------------------------------------------------------------


func _check_determinism() -> void:
	var config: LunarMapConfig = _new_config()
	var first: LunarMap = _generate(config)
	var second: LunarMap = _generate(config)

	_check(first.terrain == second.terrain, "same seed produces identical terrain")
	_check(_elevations_approx_equal(first, second), "same seed produces equal elevation")
	_check(first.walkable == second.walkable, "same seed produces identical walkability")
	_check(first.reachable == second.reachable, "same seed produces identical reachability")
	_check(first.spawn_tile == second.spawn_tile, "same seed produces the same spawn")
	_check(first.poi_tiles == second.poi_tiles, "same seed produces the same POIs")
	_check(
		first.landing_zone_center == second.landing_zone_center,
		"same seed produces the same landing zone center"
	)
	_check(first.warnings == second.warnings, "same seed produces the same warnings")


# ---------------------------------------------------------------------------
# Check 3: different seeds produce different maps
# ---------------------------------------------------------------------------


func _check_seed_variation() -> void:
	var first_config: LunarMapConfig = _new_config()
	first_config.seed = 1
	var second_config: LunarMapConfig = _new_config()
	second_config.seed = 2

	var first: LunarMap = _generate(first_config)
	var second: LunarMap = _generate(second_config)
	_check(
		first.terrain != second.terrain or first.poi_tiles != second.poi_tiles,
		"seeds 1 and 2 produce at least one different tile or POI"
	)
	_check_map_invariants(second, "seed 2")


# ---------------------------------------------------------------------------
# Check 4: every terrain feature appears with the default configuration
# ---------------------------------------------------------------------------


func _check_default_features() -> void:
	var config: LunarMapConfig = _new_config()
	config.seed = 1
	var map: LunarMap = _generate(config)
	var counts: PackedInt32Array = _terrain_counts(map)

	_check(map.terrain.size() == map.width * map.height, "terrain array covers the whole grid")
	_check(_terrain_values_are_valid(map), "every terrain byte is a known terrain kind")
	_check(counts[TERRAIN_MARE] > 0, "default map contains MARE")
	_check(counts[TERRAIN_HIGHLAND] > 0, "default map contains HIGHLAND")
	_check(counts[TERRAIN_CRATER_FLOOR] > 0, "default map contains CRATER_FLOOR")
	_check(counts[TERRAIN_CRATER_RIM] > 0, "default map contains CRATER_RIM")
	_check(counts[TERRAIN_EJECTA] > 0, "default map contains EJECTA")
	_check(counts[TERRAIN_RIDGE] > 0, "default map contains RIDGE")
	_check(counts[TERRAIN_ROCK] > 0, "default map contains ROCK")
	_check(counts[TERRAIN_LANDING_PAD] > 0, "default map contains LANDING_PAD")
	_check(_walkable_flags_are_valid(map), "ROCK and RIDGE are the only blocked terrains")


# ---------------------------------------------------------------------------
# Check 5: disabling a feature through its density
# ---------------------------------------------------------------------------


func _check_disabled_features() -> void:
	var no_rocks_config: LunarMapConfig = _new_config()
	no_rocks_config.rock_density = 0.0
	var no_rocks_map: LunarMap = _generate(no_rocks_config)
	_check(_terrain_counts(no_rocks_map)[TERRAIN_ROCK] == 0, "rock_density 0 removes every ROCK tile")
	_check_map_invariants(no_rocks_map, "no rocks")

	var no_craters_config: LunarMapConfig = _new_config()
	no_craters_config.crater_density = 0.0
	var no_craters_map: LunarMap = _generate(no_craters_config)
	var counts: PackedInt32Array = _terrain_counts(no_craters_map)
	_check(counts[TERRAIN_CRATER_FLOOR] == 0, "crater_density 0 removes every CRATER_FLOOR tile")
	_check(counts[TERRAIN_CRATER_RIM] == 0, "crater_density 0 removes every CRATER_RIM tile")
	_check(counts[TERRAIN_EJECTA] == 0, "crater_density 0 removes every EJECTA tile")
	_check_map_invariants(no_craters_map, "no craters")

	var no_ridges_config: LunarMapConfig = _new_config()
	no_ridges_config.ridge_density = 0.0
	var no_ridges_map: LunarMap = _generate(no_ridges_config)
	_check(_terrain_counts(no_ridges_map)[TERRAIN_RIDGE] == 0, "ridge_density 0 removes every RIDGE tile")
	_check_map_invariants(no_ridges_map, "no ridges")


# ---------------------------------------------------------------------------
# Check 6: landing zone and spawn
# ---------------------------------------------------------------------------


func _check_landing_zone() -> void:
	var config: LunarMapConfig = _new_config()
	var map: LunarMap = _generate(config)
	var radius: int = _effective_landing_radius(config, map)

	_check(
		map.landing_zone_center == Vector2i(map.width / 2, map.height / 2),
		"landing zone centers automatically on the map"
	)
	_check(map.spawn_tile == map.landing_zone_center, "spawn sits on the landing zone center")
	_check(map.is_inside(map.spawn_tile), "spawn is inside the grid")
	_check(map.is_walkable(map.spawn_tile), "spawn is walkable")
	_check(map.get_terrain(map.spawn_tile) == TERRAIN_LANDING_PAD, "spawn sits on LANDING_PAD")
	_check(_landing_zone_fits_inside(map, radius), "landing zone fits inside the map")
	_check(_landing_zone_is_clean(map, radius), "landing zone has no ROCK or RIDGE tiles")
	_check(_landing_zone_is_flat(map), "every LANDING_PAD tile shares one elevation")
	_check(
		not _has_warning_containing(map, "landing_zone_center"),
		"automatic landing zone needs no center adjustment"
	)

	var border_config: LunarMapConfig = _new_config()
	border_config.landing_zone_center = Vector2i(0, 0)
	var border_map: LunarMap = _generate(border_config)
	var border_radius: int = _effective_landing_radius(border_config, border_map)
	_check(
		border_map.landing_zone_center == Vector2i(border_radius, border_radius),
		"border center snaps to the nearest valid position"
	)
	_check(
		_has_warning_containing(border_map, "landing_zone_center adjusted"),
		"border center adjustment is reported"
	)
	_check(_landing_zone_fits_inside(border_map, border_radius), "adjusted border zone fits inside")
	_check(_landing_zone_is_clean(border_map, border_radius), "adjusted border zone is clean")
	_check(_landing_zone_is_flat(border_map), "adjusted border zone is flat")
	_check(border_map.is_walkable(border_map.spawn_tile), "adjusted border spawn is walkable")

	var far_config: LunarMapConfig = _new_config()
	far_config.landing_zone_center = Vector2i(1000, 1000)
	var far_map: LunarMap = _generate(far_config)
	var far_radius: int = _effective_landing_radius(far_config, far_map)
	_check(
		far_map.landing_zone_center
		== Vector2i(far_map.width - 1 - far_radius, far_map.height - 1 - far_radius),
		"out-of-bounds center snaps to the opposite edge"
	)
	_check(_landing_zone_fits_inside(far_map, far_radius), "out-of-bounds adjusted zone fits inside")


# ---------------------------------------------------------------------------
# Check 7: every walkable tile is reachable from the spawn
# ---------------------------------------------------------------------------


func _check_connectivity() -> void:
	for seed_value: int in range(1, 4):
		var config: LunarMapConfig = _new_config()
		config.seed = seed_value
		var map: LunarMap = _generate(config)
		_check(_connectivity_matches(map), "seed %d keeps every walkable tile reachable" % [seed_value])
		_check(map.is_reachable(map.spawn_tile), "seed %d marks the spawn as reachable" % [seed_value])


# ---------------------------------------------------------------------------
# Check 8: points of interest
# ---------------------------------------------------------------------------


func _check_points_of_interest() -> void:
	var config: LunarMapConfig = _new_config()
	var map: LunarMap = _generate(config)
	_check(map.poi_tiles.size() == 3, "default map places exactly 3 POIs")
	_check(_pois_are_valid(map), "default POIs are inside, walkable, reachable, off the pad and distinct")
	_check(
		_pois_respect_distance(map, config.poi_min_distance),
		"default POIs respect the minimum spawn distance"
	)
	_check(
		_pois_respect_separation(map, config.poi_min_separation),
		"default POIs respect the minimum separation"
	)
	_check(map.warnings.is_empty(), "default POIs need no relaxation warning")

	var five_config: LunarMapConfig = _new_config()
	five_config.poi_count = 5
	var five_map: LunarMap = _generate(five_config)
	_check(five_map.poi_tiles.size() <= 5, "poi_count 5 never places more than 5 POIs")
	_check(_pois_are_valid(five_map), "poi_count 5 produces only valid POIs")
	_check(
		five_map.poi_tiles.size() == five_config.poi_count
		or _has_warning_containing(five_map, "point of interest"),
		"poi_count 5 reports the placed count when it cannot reach the target"
	)


# ---------------------------------------------------------------------------
# Check 9: tile and world coordinate conversions
# ---------------------------------------------------------------------------


func _check_coordinate_conversions() -> void:
	var config: LunarMapConfig = _new_config()
	var map: LunarMap = _generate(config)
	var poi_count_before: int = map.poi_tiles.size()

	_check(map.tile_size == 32, "conversion fixture uses 32 px tiles")
	_check(map.tile_to_world(Vector2i(3, 4)) == Vector2(96.0, 128.0), "tile_to_world(3, 4) is (96, 128)")
	_check(map.world_to_tile(Vector2(96.0, 128.0)) == Vector2i(3, 4), "world_to_tile is the inverse")
	_check(
		map.world_to_tile(map.tile_to_world(Vector2i(0, 0)) + Vector2(16.0, 16.0)) == Vector2i(0, 0),
		"tile center maps back to its tile"
	)
	_check(
		map.world_to_tile(map.tile_to_world(Vector2i(map.width - 1, map.height - 1)) + Vector2(16.0, 16.0))
		== Vector2i(map.width - 1, map.height - 1),
		"the last tile center maps back to its tile"
	)
	_check(
		map.get_world_size() == Vector2i(map.width * map.tile_size, map.height * map.tile_size),
		"world size is width*tile by height*tile"
	)

	_check(map.get_index(Vector2i(-1, 0)) == -1, "get_index rejects negative x")
	_check(map.get_index(Vector2i(0, -1)) == -1, "get_index rejects negative y")
	_check(map.get_index(Vector2i(map.width, 0)) == -1, "get_index rejects x beyond the grid")
	_check(map.get_index(Vector2i(0, map.height)) == -1, "get_index rejects y beyond the grid")
	_check(not map.is_inside(Vector2i(-1, 0)), "is_inside rejects negative tiles")
	_check(
		not map.is_inside(Vector2i(map.width, map.height)),
		"is_inside rejects tiles beyond the grid"
	)
	_check(
		map.get_terrain(Vector2i(-1, 0)) == TERRAIN_INVALID,
		"get_terrain returns INVALID outside the grid"
	)
	_check(not map.is_walkable(Vector2i(-1, 0)), "is_walkable returns false outside the grid")
	_check(
		not map.is_reachable(Vector2i(map.width, map.height)),
		"is_reachable returns false outside the grid"
	)
	_check(map.world_to_tile(Vector2(-32.0, -32.0)) == Vector2i(-1, -1), "negative world positions are safe")

	var terrain_snapshot: PackedByteArray = map.terrain.duplicate()
	var walkable_snapshot: PackedByteArray = map.walkable.duplicate()
	map.set_terrain(Vector2i(-1, 0), TERRAIN_MARE)
	map.set_terrain(Vector2i(map.width, map.height), TERRAIN_ROCK)
	_check(
		map.terrain == terrain_snapshot and map.walkable == walkable_snapshot,
		"set_terrain outside the grid leaves terrain and walkable untouched"
	)

	map.set_terrain(Vector2i(1, 1), LunarMap.Terrain.INVALID)
	_check(
		map.terrain == terrain_snapshot and map.walkable == walkable_snapshot,
		"set_terrain ignores Terrain.INVALID"
	)

	map.set_terrain(Vector2i(1, 1), 99)
	_check(
		map.terrain == terrain_snapshot and map.walkable == walkable_snapshot,
		"set_terrain ignores values outside the terrain enum"
	)

	var original_value: int = map.terrain[map.get_index(Vector2i(2, 2))]
	map.set_terrain(Vector2i(2, 2), TERRAIN_ROCK)
	_check(
		map.get_terrain(Vector2i(2, 2)) == TERRAIN_ROCK,
		"set_terrain still writes valid terrain values"
	)
	map.set_terrain(Vector2i(2, 2), original_value)

	var poi_copy: Array[Vector2i] = map.get_poi_tiles()
	poi_copy.clear()
	_check(map.poi_tiles.size() == poi_count_before, "get_poi_tiles returns a copy")


# ---------------------------------------------------------------------------
# Check 10: custom map and tile size
# ---------------------------------------------------------------------------


func _check_custom_size() -> void:
	var config: LunarMapConfig = _new_config()
	config.width = 120
	config.height = 80
	config.tile_size = 16

	var map: LunarMap = _generate(config)
	_check(map.width == 120, "120x80 map keeps the requested width")
	_check(map.height == 80, "120x80 map keeps the requested height")
	_check(map.tile_size == 16, "120x80 map keeps the requested tile size")
	_check(
		map.get_world_size() == Vector2i(1920, 1280),
		"120x80 at 16 px tiles is 1920x1280 world pixels"
	)
	_check_map_invariants(map, "120x80")


# ---------------------------------------------------------------------------
# Check 11: hostile maximums are clamped instead of stalling generation
# ---------------------------------------------------------------------------


func _check_hostile_maxima() -> void:
	var config: LunarMapConfig = _new_config()
	config.width = 120
	config.height = 80
	config.crater_density = 1000000.0
	config.rock_density = 1000000.0
	config.ridge_density = 1000000.0
	config.poi_min_distance = 1000000.0

	var start_usec: int = Time.get_ticks_usec()
	var map: LunarMap = _generate(config)
	var elapsed_ms: float = float(Time.get_ticks_usec() - start_usec) / 1000.0
	print("hostile maxima generation time: %.1f ms" % [elapsed_ms])

	_check(map.width == 120 and map.height == 80, "hostile maxima keep usable dimensions")
	_check(not map.warnings.is_empty(), "hostile maxima are reported as warnings")
	_check(_has_warning_containing(map, "crater_density"), "hostile crater_density is reported")
	_check(_has_warning_containing(map, "rock_density"), "hostile rock_density is reported")
	_check(_has_warning_containing(map, "ridge_density"), "hostile ridge_density is reported")
	_check(_has_warning_containing(map, "poi_min_distance"), "hostile poi_min_distance is reported")
	_check(_connectivity_matches(map), "hostile maxima map stays fully connected")
	_check_map_invariants(map, "hostile maxima")

	if elapsed_ms > HOSTILE_MAP_TARGET_MS:
		print(
			"WARNING: hostile maxima generation took %.1f ms, above the %.0f ms reference target"
			% [elapsed_ms, HOSTILE_MAP_TARGET_MS]
		)


# ---------------------------------------------------------------------------
# Check 12: maximum map size
# ---------------------------------------------------------------------------


func _check_large_map() -> void:
	var config: LunarMapConfig = _new_config()
	config.width = 256
	config.height = 256

	var start_usec: int = Time.get_ticks_usec()
	var map: LunarMap = _generate(config)
	var elapsed_ms: float = float(Time.get_ticks_usec() - start_usec) / 1000.0
	print("256x256 generation time: %.1f ms" % [elapsed_ms])

	_check(map.width == 256 and map.height == 256, "256x256 map keeps the requested size")
	_check(map.terrain.size() == 256 * 256, "256x256 terrain covers every tile")
	_check(map.elevation.size() == 256 * 256, "256x256 elevation covers every tile")
	_check(_terrain_values_are_valid(map), "256x256 terrain only contains known kinds")
	_check(_elevation_is_valid(map), "256x256 elevation stays finite and normalized")
	_check(_walkable_flags_are_valid(map), "256x256 walkability matches the terrain")
	_check(_connectivity_matches(map), "256x256 map is fully connected from the spawn")
	_check(map.is_walkable(map.spawn_tile), "256x256 spawn is walkable")
	_check(_pois_are_valid(map), "256x256 POIs are valid")

	if elapsed_ms > LARGE_MAP_TARGET_MS:
		print(
			"WARNING: 256x256 generation took %.1f ms, above the %.0f ms reference target"
			% [elapsed_ms, LARGE_MAP_TARGET_MS]
		)


# ---------------------------------------------------------------------------
# Check 13: small map with points of interest
# ---------------------------------------------------------------------------


func _check_small_map() -> void:
	var config: LunarMapConfig = _new_config()
	config.width = 16
	config.height = 16
	var map: LunarMap = _generate(config)
	_check(map.width == 16 and map.height == 16, "16x16 map keeps the requested size")
	_check(map.poi_tiles.size() == 3, "16x16 default map places 3 POIs")
	_check(_pois_are_valid(map), "16x16 default POIs are valid")
	if not _has_warning_containing(map, "relaxed"):
		_check(
			_pois_respect_distance(map, config.poi_min_distance)
			and _pois_respect_separation(map, config.poi_min_separation),
			"16x16 default POIs meet the full constraints when no warning is emitted"
		)

	config.poi_min_distance = 13.0
	var tight_map: LunarMap = _generate(config)
	_check(tight_map.poi_tiles.size() == 3, "16x16 tight map still places 3 POIs")
	_check(_pois_are_valid(tight_map), "16x16 tight POIs are valid")
	_check(
		_has_warning_containing(tight_map, "relaxed"),
		"16x16 tight constraints emit a relaxation warning"
	)


# ---------------------------------------------------------------------------
# Check 14: sanitization of hostile configurations
# ---------------------------------------------------------------------------


func _check_sanitization() -> void:
	var negative: LunarMapConfig = _new_config()
	negative.width = -100
	negative.height = 0
	negative.tile_size = -5
	_check_sanitized_config(negative, "negative sizes")

	var oversized: LunarMapConfig = _new_config()
	oversized.width = 9999
	oversized.height = 512
	oversized.tile_size = 200
	_check_sanitized_config(oversized, "oversized map")

	var non_finite_densities: LunarMapConfig = _new_config()
	non_finite_densities.crater_density = NAN
	non_finite_densities.rock_density = INF
	non_finite_densities.ridge_density = -INF
	_check_sanitized_config(non_finite_densities, "non-finite densities")

	var non_finite_radii: LunarMapConfig = _new_config()
	non_finite_radii.min_crater_radius = NAN
	non_finite_radii.max_crater_radius = INF
	non_finite_radii.ejecta_radius_multiplier = INF
	non_finite_radii.poi_min_distance = NAN
	non_finite_radii.poi_min_separation = INF
	_check_sanitized_config(non_finite_radii, "non-finite radii")

	var inverted_radii: LunarMapConfig = _new_config()
	inverted_radii.min_crater_radius = 20.0
	inverted_radii.max_crater_radius = 2.0
	inverted_radii.ejecta_radius_multiplier = 0.1
	_check_sanitized_config(inverted_radii, "inverted radii")

	var extreme_center: LunarMapConfig = _new_config()
	extreme_center.landing_zone_center = Vector2i(-9999, 9999)
	extreme_center.landing_zone_radius = 999
	_check_sanitized_config(extreme_center, "extreme landing center")

	var negative_pois: LunarMapConfig = _new_config()
	negative_pois.poi_count = -3
	negative_pois.poi_min_distance = -1.0
	negative_pois.poi_min_separation = -1.0
	_check_sanitized_config(negative_pois, "negative POI values")

	var null_map: LunarMap = GeneratorScript.call("generate", null) as LunarMap
	_check(null_map != null, "null config still produces a map")
	if null_map != null:
		_check_map_invariants(null_map, "null config")
		_check(
			null_map.width == 64 and null_map.height == 64,
			"null config falls back to the default size"
		)


func _check_sanitized_config(config: LunarMapConfig, label: String) -> void:
	var map: LunarMap = _generate(config)
	_check(not map.warnings.is_empty(), label + ": invalid values are reported as warnings")
	_check_map_invariants(map, label)


# ---------------------------------------------------------------------------
# Shared invariants
# ---------------------------------------------------------------------------


func _check_map_invariants(map: LunarMap, label: String) -> void:
	if map == null:
		_checks += 1
		_failures += 1
		printerr("[FAIL] ", label, ": map is null")
		return

	var expected_cells: int = map.width * map.height
	_check(
		map.width >= MIN_MAP_SIZE
		and map.width <= MAX_MAP_SIZE
		and map.height >= MIN_MAP_SIZE
		and map.height <= MAX_MAP_SIZE
		and map.tile_size >= MIN_TILE_SIZE
		and map.tile_size <= MAX_TILE_SIZE,
		label + ": dimensions and tile size are inside their ranges"
	)
	_check(
		map.terrain.size() == expected_cells
		and map.elevation.size() == expected_cells
		and map.walkable.size() == expected_cells
		and map.reachable.size() == expected_cells,
		label + ": every grid array covers the whole map"
	)
	_check(_terrain_values_are_valid(map), label + ": terrain bytes are valid")
	_check(_elevation_is_valid(map), label + ": elevation is finite and in [0, 1]")
	_check(_walkable_flags_are_valid(map), label + ": walkability matches the terrain")
	_check(
		map.is_inside(map.spawn_tile)
		and map.is_walkable(map.spawn_tile)
		and map.get_terrain(map.spawn_tile) == TERRAIN_LANDING_PAD,
		label + ": spawn is inside, walkable and on the landing pad"
	)
	_check(_connectivity_matches(map), label + ": every walkable tile is reachable from the spawn")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _new_config() -> LunarMapConfig:
	var config: LunarMapConfig = ConfigScript.new() as LunarMapConfig
	return config


func _generate(config: LunarMapConfig) -> LunarMap:
	var map: LunarMap = GeneratorScript.generate(config) as LunarMap
	return map


func _terrain_counts(map: LunarMap) -> PackedInt32Array:
	var counts: PackedInt32Array = PackedInt32Array()
	counts.resize(TERRAIN_COUNT)
	counts.fill(0)
	for index: int in range(map.terrain.size()):
		var value: int = map.terrain[index]
		if value >= 0 and value < TERRAIN_COUNT:
			counts[value] += 1
	return counts


func _terrain_values_are_valid(map: LunarMap) -> bool:
	for index: int in range(map.terrain.size()):
		var value: int = map.terrain[index]
		if value < 0 or value >= TERRAIN_COUNT:
			return false
	return true


func _elevation_is_valid(map: LunarMap) -> bool:
	for index: int in range(map.elevation.size()):
		var value: float = map.elevation[index]
		if not is_finite(value) or value < 0.0 or value > 1.0:
			return false
	return true


func _elevations_approx_equal(first: LunarMap, second: LunarMap) -> bool:
	if first.elevation.size() != second.elevation.size():
		return false
	for index: int in range(first.elevation.size()):
		if not is_equal_approx(first.elevation[index], second.elevation[index]):
			return false
	return true


func _walkable_flags_are_valid(map: LunarMap) -> bool:
	for index: int in range(map.terrain.size()):
		var terrain_value: int = map.terrain[index]
		var blocked: bool = terrain_value == TERRAIN_ROCK or terrain_value == TERRAIN_RIDGE
		var expected: int = 0 if blocked else 1
		if map.walkable[index] != expected:
			return false
	return true


func _bfs_from_spawn(map: LunarMap) -> PackedByteArray:
	var width: int = map.width
	var height: int = map.height
	var visited: PackedByteArray = PackedByteArray()
	visited.resize(width * height)
	visited.fill(0)

	var spawn_index: int = map.get_index(map.spawn_tile)
	if spawn_index < 0 or map.walkable[spawn_index] != 1:
		return visited

	var queue: PackedInt32Array = PackedInt32Array()
	queue.resize(width * height)
	queue[0] = spawn_index
	visited[spawn_index] = 1
	var head: int = 0
	var tail: int = 1

	while head < tail:
		var index: int = queue[head]
		head += 1
		var x: int = index % width
		var y: int = index / width
		if x > 0:
			var left: int = index - 1
			if map.walkable[left] == 1 and visited[left] == 0:
				visited[left] = 1
				queue[tail] = left
				tail += 1
		if x + 1 < width:
			var right: int = index + 1
			if map.walkable[right] == 1 and visited[right] == 0:
				visited[right] = 1
				queue[tail] = right
				tail += 1
		if y > 0:
			var up: int = index - width
			if map.walkable[up] == 1 and visited[up] == 0:
				visited[up] = 1
				queue[tail] = up
				tail += 1
		if y + 1 < height:
			var down: int = index + width
			if map.walkable[down] == 1 and visited[down] == 0:
				visited[down] = 1
				queue[tail] = down
				tail += 1

	return visited


func _connectivity_matches(map: LunarMap) -> bool:
	var visited: PackedByteArray = _bfs_from_spawn(map)
	for index: int in range(map.width * map.height):
		var expected: int = 1 if visited[index] == 1 else 0
		if int(map.reachable[index]) != expected:
			return false
		if map.walkable[index] == 1 and visited[index] != 1:
			return false
	return true


func _effective_landing_radius(config: LunarMapConfig, map: LunarMap) -> int:
	var maximum: int = mini(map.width, map.height) / 4
	return clampi(config.landing_zone_radius, 1, maximum)


func _landing_zone_fits_inside(map: LunarMap, radius: int) -> bool:
	var center: Vector2i = map.landing_zone_center
	return (
		center.x - radius >= 0
		and center.y - radius >= 0
		and center.x + radius < map.width
		and center.y + radius < map.height
	)


func _landing_zone_is_clean(map: LunarMap, radius: int) -> bool:
	var center: Vector2i = map.landing_zone_center
	for y: int in range(center.y - radius, center.y + radius + 1):
		for x: int in range(center.x - radius, center.x + radius + 1):
			var offset_x: int = x - center.x
			var offset_y: int = y - center.y
			if offset_x * offset_x + offset_y * offset_y > radius * radius:
				continue
			var tile: Vector2i = Vector2i(x, y)
			if not map.is_inside(tile):
				return false
			var terrain_value: int = map.get_terrain(tile)
			if terrain_value == TERRAIN_ROCK or terrain_value == TERRAIN_RIDGE:
				return false
			if terrain_value != TERRAIN_LANDING_PAD:
				return false
			if not map.is_walkable(tile):
				return false
	return true


## Every LANDING_PAD tile must share the same elevation: the flattener averages
## the zone once and writes that value to the whole circle.
func _landing_zone_is_flat(map: LunarMap) -> bool:
	var reference: float = 0.0
	var has_reference: bool = false
	for index: int in range(map.terrain.size()):
		if map.terrain[index] != TERRAIN_LANDING_PAD:
			continue
		var elevation_value: float = map.elevation[index]
		if not has_reference:
			reference = elevation_value
			has_reference = true
			continue
		if absf(elevation_value - reference) > FLAT_ELEVATION_EPSILON:
			return false
	return has_reference


func _pois_are_valid(map: LunarMap) -> bool:
	var seen: Array[Vector2i] = []
	for tile: Vector2i in map.poi_tiles:
		if not map.is_inside(tile):
			return false
		if not map.is_walkable(tile):
			return false
		if not map.is_reachable(tile):
			return false
		if tile == map.spawn_tile:
			return false
		if map.get_terrain(tile) == TERRAIN_LANDING_PAD:
			return false
		if seen.has(tile):
			return false
		seen.append(tile)
	return true


func _pois_respect_distance(map: LunarMap, minimum: float) -> bool:
	for tile: Vector2i in map.poi_tiles:
		var offset: Vector2 = Vector2(tile - map.spawn_tile)
		if offset.length_squared() + DISTANCE_EPSILON < minimum * minimum:
			return false
	return true


func _pois_respect_separation(map: LunarMap, minimum: float) -> bool:
	for first: int in range(map.poi_tiles.size()):
		for second: int in range(first + 1, map.poi_tiles.size()):
			var offset: Vector2 = Vector2(map.poi_tiles[first] - map.poi_tiles[second])
			if offset.length_squared() + DISTANCE_EPSILON < minimum * minimum:
				return false
	return true


func _has_warning_containing(map: LunarMap, needle: String) -> bool:
	for message: String in map.warnings:
		if message.contains(needle):
			return true
	return false


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("[PASS] ", label)
	else:
		_failures += 1
		printerr("[FAIL] ", label)
