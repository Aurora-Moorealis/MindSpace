class_name LunarMapConfig
extends Resource

## Tunable parameters for the procedural lunar map generator.
##
## The generator never aborts on an invalid configuration: it sanitizes its
## values and reports them through [method validate]. This resource only holds
## the requested values, so it is safe to share between runs.

const MIN_MAP_SIZE: int = 16
const MAX_MAP_SIZE: int = 256
const MIN_TILE_SIZE: int = 8
const MAX_TILE_SIZE: int = 64
const MAX_POI_COUNT: int = 8

## Valid ranges for the numeric fields, kept in sync with their @export_range
## annotations so validation and sanitization agree.
const CRATER_DENSITY_MIN: float = 0.0
const CRATER_DENSITY_MAX: float = 0.05
const MIN_CRATER_RADIUS_MIN: float = 1.0
const MIN_CRATER_RADIUS_MAX: float = 16.0
const MAX_CRATER_RADIUS_MIN: float = 1.0
const MAX_CRATER_RADIUS_MAX: float = 32.0
const EJECTA_RADIUS_MULTIPLIER_MIN: float = 1.0
const EJECTA_RADIUS_MULTIPLIER_MAX: float = 3.0
const ROCK_DENSITY_MIN: float = 0.0
const ROCK_DENSITY_MAX: float = 0.1
const RIDGE_DENSITY_MIN: float = 0.0
const RIDGE_DENSITY_MAX: float = 0.01
const POI_DISTANCE_MIN: float = 0.0
const POI_DISTANCE_MAX: float = 64.0

## Map width in tiles.
@export_range(16, 256, 1) var width: int = 64
## Map height in tiles.
@export_range(16, 256, 1) var height: int = 48
## Edge of each square tile in pixels.
@export_range(8, 64, 1) var tile_size: int = 32
## Seed for every random stream. Same seed and config produce the same map.
@export var seed: int = 1
## Expected number of craters per tile.
@export_range(0.0, 0.05, 0.0001) var crater_density: float = 0.004
## Minimum crater radius in tiles.
@export_range(1.0, 16.0, 0.5) var min_crater_radius: float = 2.0
## Maximum crater radius in tiles.
@export_range(1.0, 32.0, 0.5) var max_crater_radius: float = 8.0
## Ejecta radius as a multiple of the crater radius.
@export_range(1.0, 3.0, 0.05) var ejecta_radius_multiplier: float = 1.5
## Expected number of rock cells per tile.
@export_range(0.0, 0.1, 0.001) var rock_density: float = 0.015
## Expected number of ridge cells per tile.
@export_range(0.0, 0.01, 0.0001) var ridge_density: float = 0.0008
## Landing zone radius in tiles.
@export_range(1, 16, 1) var landing_zone_radius: int = 4
## Landing zone center in tiles. (-1, -1) means automatic centering.
@export var landing_zone_center: Vector2i = Vector2i(-1, -1)
## Number of points of interest to place.
@export_range(1, 8, 1) var poi_count: int = 3
## Minimum distance from the spawn to a point of interest, in tiles.
@export_range(0.0, 64.0, 0.5) var poi_min_distance: float = 10.0
## Minimum separation between points of interest, in tiles.
@export_range(0.0, 64.0, 0.5) var poi_min_separation: float = 8.0


## Returns a list of human-readable messages for every invalid value.
## An empty list means the configuration is usable as-is.
## This method never mutates the resource.
func validate() -> Array[String]:
	var errors: Array[String] = []

	if width < MIN_MAP_SIZE or width > MAX_MAP_SIZE:
		errors.append("width must be in [%d, %d], got %d" % [MIN_MAP_SIZE, MAX_MAP_SIZE, width])
	if height < MIN_MAP_SIZE or height > MAX_MAP_SIZE:
		errors.append("height must be in [%d, %d], got %d" % [MIN_MAP_SIZE, MAX_MAP_SIZE, height])
	if tile_size < MIN_TILE_SIZE or tile_size > MAX_TILE_SIZE:
		errors.append("tile_size must be in [%d, %d], got %d" % [MIN_TILE_SIZE, MAX_TILE_SIZE, tile_size])
	if crater_density < CRATER_DENSITY_MIN or crater_density > CRATER_DENSITY_MAX:
		errors.append(
			"crater_density must be in [%s, %s], got %s"
			% [CRATER_DENSITY_MIN, CRATER_DENSITY_MAX, crater_density]
		)
	if rock_density < ROCK_DENSITY_MIN or rock_density > ROCK_DENSITY_MAX:
		errors.append(
			"rock_density must be in [%s, %s], got %s"
			% [ROCK_DENSITY_MIN, ROCK_DENSITY_MAX, rock_density]
		)
	if ridge_density < RIDGE_DENSITY_MIN or ridge_density > RIDGE_DENSITY_MAX:
		errors.append(
			"ridge_density must be in [%s, %s], got %s"
			% [RIDGE_DENSITY_MIN, RIDGE_DENSITY_MAX, ridge_density]
		)
	if min_crater_radius < MIN_CRATER_RADIUS_MIN or min_crater_radius > MIN_CRATER_RADIUS_MAX:
		errors.append(
			"min_crater_radius must be in [%s, %s], got %s"
			% [MIN_CRATER_RADIUS_MIN, MIN_CRATER_RADIUS_MAX, min_crater_radius]
		)
	if max_crater_radius < MAX_CRATER_RADIUS_MIN or max_crater_radius > MAX_CRATER_RADIUS_MAX:
		errors.append(
			"max_crater_radius must be in [%s, %s], got %s"
			% [MAX_CRATER_RADIUS_MIN, MAX_CRATER_RADIUS_MAX, max_crater_radius]
		)
	if min_crater_radius > max_crater_radius:
		errors.append(
			"min_crater_radius (%s) must not be greater than max_crater_radius (%s)"
			% [min_crater_radius, max_crater_radius]
		)
	if (
		ejecta_radius_multiplier < EJECTA_RADIUS_MULTIPLIER_MIN
		or ejecta_radius_multiplier > EJECTA_RADIUS_MULTIPLIER_MAX
	):
		errors.append(
			"ejecta_radius_multiplier must be in [%s, %s], got %s"
			% [EJECTA_RADIUS_MULTIPLIER_MIN, EJECTA_RADIUS_MULTIPLIER_MAX, ejecta_radius_multiplier]
		)
	if landing_zone_radius <= 0:
		errors.append("landing_zone_radius must be greater than 0, got %d" % landing_zone_radius)
	var max_landing_radius: int = mini(width, height) / 4
	if landing_zone_radius > max_landing_radius:
		errors.append(
			"landing_zone_radius must be <= %d for a %dx%d map, got %d"
			% [max_landing_radius, width, height, landing_zone_radius]
		)
	if poi_count < 1 or poi_count > MAX_POI_COUNT:
		errors.append("poi_count must be in [1, %d], got %d" % [MAX_POI_COUNT, poi_count])
	if poi_min_distance < POI_DISTANCE_MIN or poi_min_distance > POI_DISTANCE_MAX:
		errors.append(
			"poi_min_distance must be in [%s, %s], got %s"
			% [POI_DISTANCE_MIN, POI_DISTANCE_MAX, poi_min_distance]
		)
	if poi_min_separation < POI_DISTANCE_MIN or poi_min_separation > POI_DISTANCE_MAX:
		errors.append(
			"poi_min_separation must be in [%s, %s], got %s"
			% [POI_DISTANCE_MIN, POI_DISTANCE_MAX, poi_min_separation]
		)

	return errors
