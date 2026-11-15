class_name LunarMapTileMapper
extends RefCounted
## Pure translation from [LunarMap] cells to TileSet atlas coordinates.
##
## Each static query reads one cell of the map and returns the atlas coordinate
## for a single layer: ground, base or props. The mapper has no knowledge of
## [TileMapLayer], scenes, autoloads, assets or the clock, and it never touches
## the global RNG, so it can be exercised headless.
##
## Cells with no tile in a layer return [constant NO_ATLAS]. Ground always has a
## tile for a cell inside the grid, including unknown terrain values.
##
## Variants are selected with a stable integer hash of the map seed, the cell
## coordinates and a salt per variant group. The same map and cell therefore
## always resolve to the same atlas coordinate.

## Returned when a layer has no tile for the requested cell.
const NO_ATLAS: Vector2i = Vector2i(-1, -1)
## Source id used by every layer of the generated map.
const SOURCE_ID: int = 0
## Alternative tile id used by every layer of the generated map.
const ALTERNATIVE_TILE: int = 0

## Terrain values mirrored from [enum LunarMap.Terrain] for cheap comparisons.
const TERRAIN_MARE: int = LunarMap.Terrain.MARE
const TERRAIN_HIGHLAND: int = LunarMap.Terrain.HIGHLAND
const TERRAIN_CRATER_FLOOR: int = LunarMap.Terrain.CRATER_FLOOR
const TERRAIN_CRATER_RIM: int = LunarMap.Terrain.CRATER_RIM
const TERRAIN_EJECTA: int = LunarMap.Terrain.EJECTA
const TERRAIN_RIDGE: int = LunarMap.Terrain.RIDGE
const TERRAIN_ROCK: int = LunarMap.Terrain.ROCK
const TERRAIN_LANDING_PAD: int = LunarMap.Terrain.LANDING_PAD

## Salts that keep the variant streams of each group independent.
const SALT_GROUND: int = 0x51A7C0DE
const SALT_BASE: int = 0x5B2E9F13
const SALT_RIDGE_PROPS: int = 0x6C3D4A21
const SALT_ROCK_PROPS: int = 0x7D4E5B32


## Returns the ground atlas coordinate for [param tile], or [constant NO_ATLAS]
## when the tile is outside the map. Interior cells always get a valid
## coordinate, even when their terrain value is unknown.
static func ground_atlas(map: LunarMap, tile: Vector2i) -> Vector2i:
	if not _has_tile(map, tile):
		return NO_ATLAS

	match _terrain_at(map, tile):
		TERRAIN_MARE:
			match _variant_index(map, tile, SALT_GROUND, 3):
				0:
					return Vector2i(0, 0)
				1:
					return Vector2i(1, 0)
				_:
					return Vector2i(2, 0)
		TERRAIN_HIGHLAND:
			match _variant_index(map, tile, SALT_GROUND, 3):
				0:
					return Vector2i(2, 0)
				1:
					return Vector2i(3, 0)
				_:
					return Vector2i(0, 1)
		TERRAIN_CRATER_FLOOR:
			match _variant_index(map, tile, SALT_GROUND, 2):
				0:
					return Vector2i(3, 1)
				_:
					return Vector2i(2, 1)
		TERRAIN_CRATER_RIM:
			# A rim band of churned rubble: the plain regolith variants used
			# before vanished into the surrounding mare and the crater bowl
			# had no readable outline.
			return Vector2i(3, 1)
		TERRAIN_EJECTA:
			match _variant_index(map, tile, SALT_GROUND, 2):
				0:
					return Vector2i(2, 0)
				_:
					return Vector2i(3, 0)
		TERRAIN_RIDGE:
			return Vector2i(3, 1)
		TERRAIN_ROCK:
			return Vector2i(2, 1)
		TERRAIN_LANDING_PAD:
			# The ground under the platform is painted too, so the layer never
			# has holes even where the base layer covers it.
			return Vector2i(2, 1)
		_:
			return Vector2i(0, 0)


## Returns the base atlas coordinate for [param tile], or [constant NO_ATLAS].
## Only landing pad cells have a base tile: a plate variant inside and the
## industrial grate on the edge.
static func base_atlas(map: LunarMap, tile: Vector2i) -> Vector2i:
	if not _has_tile(map, tile):
		return NO_ATLAS
	if _terrain_at(map, tile) != TERRAIN_LANDING_PAD:
		return NO_ATLAS
	if _is_landing_pad_edge(map, tile):
		return Vector2i(3, 3)
	match _variant_index(map, tile, SALT_BASE, 2):
		0:
			return Vector2i(0, 0)
		_:
			return Vector2i(1, 0)


## Returns the props atlas coordinate for [param tile], or [constant NO_ATLAS].
## Only rock and ridge cells have a prop, and only rock tiles are returned:
## the mineral row of the props atlas is never used.
static func prop_atlas(map: LunarMap, tile: Vector2i) -> Vector2i:
	if not _has_tile(map, tile):
		return NO_ATLAS

	match _terrain_at(map, tile):
		TERRAIN_RIDGE:
			match _variant_index(map, tile, SALT_RIDGE_PROPS, 3):
				0:
					return Vector2i(0, 0)
				1:
					return Vector2i(1, 0)
				_:
					return Vector2i(0, 1)
		TERRAIN_ROCK:
			match _variant_index(map, tile, SALT_ROCK_PROPS, 3):
				0:
					return Vector2i(2, 0)
				1:
					return Vector2i(3, 0)
				_:
					return Vector2i(4, 0)
		_:
			return NO_ATLAS


## Returns whether [param map] exists and [param tile] is inside its grid.
static func _has_tile(map: LunarMap, tile: Vector2i) -> bool:
	return map != null and map.is_inside(tile)


## Returns the raw terrain byte of [param tile], or [code]LunarMap.Terrain.INVALID[/code]
## when the map has no stored value for it.
static func _terrain_at(map: LunarMap, tile: Vector2i) -> int:
	var index: int = map.get_index(tile)
	if index < 0 or index >= map.terrain.size():
		return int(LunarMap.Terrain.INVALID)
	return map.terrain[index]


## Returns whether [param tile] touches a non landing pad cell or the map edge.
static func _is_landing_pad_edge(map: LunarMap, tile: Vector2i) -> bool:
	for offset_y: int in range(-1, 2):
		for offset_x: int in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			var neighbor: Vector2i = tile + Vector2i(offset_x, offset_y)
			if not map.is_inside(neighbor):
				return true
			if _terrain_at(map, neighbor) != TERRAIN_LANDING_PAD:
				return true
	return false


## Returns an index in [0, count) derived from seed, cell and salt.
static func _variant_index(map: LunarMap, tile: Vector2i, salt: int, count: int) -> int:
	return _hash_cell(map.seed, tile, salt) % count


## Returns a stable, non-negative hash of seed, cell and salt.
##
## The mix is a fixed sequence of XOR-shifts and multiplications, with no RNG
## state and no clock: the same inputs always produce the same value, and the
## final mask keeps the modulo operand non-negative.
static func _hash_cell(seed_value: int, tile: Vector2i, salt: int) -> int:
	var value: int = seed_value
	value ^= tile.x * 0x9E3779B1
	value ^= tile.y * 0x85EBCA77
	value ^= salt * 0xC2B2AE3D
	value = (value ^ (value >> 15)) * 0x2C1B3C6D
	value = (value ^ (value >> 12)) * 0x297A2D39
	value ^= value >> 15
	return value & 0x7FFFFFFF
