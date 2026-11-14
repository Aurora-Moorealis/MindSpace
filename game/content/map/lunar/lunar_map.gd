class_name LunarMap
extends RefCounted
## Plain data model for a procedurally generated lunar map.
##
## Holds the grid dimensions, the per-tile terrain and elevation arrays, the
## gameplay flags (walkability and reachability) and the spawn, point of
## interest and landing zone anchors. It performs no generation and has no
## dependencies outside the engine, so it can be built and tested in isolation.

## Terrain kinds stored as bytes (0..7) inside [member terrain].
## [constant INVALID] is never stored; it marks queries outside the grid.
enum Terrain {
	MARE,
	HIGHLAND,
	CRATER_FLOOR,
	CRATER_RIM,
	EJECTA,
	RIDGE,
	ROCK,
	LANDING_PAD,
	INVALID = -1,
}

## Map size in tiles.
var width: int = 0
var height: int = 0
## Size of a single tile in world pixels.
var tile_size: int = 32
## Seed used to generate the map, kept for reproducibility.
var seed: int = 0
## Terrain byte per tile (row-major, [method get_index] order).
var terrain: PackedByteArray = PackedByteArray()
## Elevation per tile, in the same row-major order as [member terrain].
var elevation: PackedFloat32Array = PackedFloat32Array()
## Walkability flag per tile: 1 when traversable, 0 otherwise.
var walkable: PackedByteArray = PackedByteArray()
## Reachability flag per tile from the spawn: 1 when reachable, 0 otherwise.
var reachable: PackedByteArray = PackedByteArray()
## Tile where the player spawns.
var spawn_tile: Vector2i = Vector2i.ZERO
## Tiles that hold a point of interest.
var poi_tiles: Array[Vector2i] = []
## Center of the landing zone.
var landing_zone_center: Vector2i = Vector2i.ZERO
## Non-fatal issues reported by the generator.
var warnings: Array[String] = []


## Returns the row-major index of [param tile], or -1 when it is outside the grid.
func get_index(tile: Vector2i) -> int:
	if not is_inside(tile):
		return -1
	return tile.y * width + tile.x


## Returns whether [param tile] is inside the grid bounds.
func is_inside(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < width and tile.y >= 0 and tile.y < height


## Returns the terrain of [param tile], or [constant Terrain.INVALID] outside the grid.
func get_terrain(tile: Vector2i) -> Terrain:
	if not is_inside(tile):
		return Terrain.INVALID
	var index: int = get_index(tile)
	var value: int = terrain[index]
	return value as Terrain


## Sets the terrain byte of [param tile]. Does not update [member walkable].
##
## Tiles outside the grid are ignored. [constant Terrain.INVALID] and any value
## outside the [constant Terrain.MARE] .. [constant Terrain.LANDING_PAD] range
## are ignored too, so an invalid byte is never stored in [member terrain].
func set_terrain(tile: Vector2i, value: Terrain) -> void:
	if not is_inside(tile):
		return
	var terrain_value: int = int(value)
	if terrain_value < int(Terrain.MARE) or terrain_value > int(Terrain.LANDING_PAD):
		return
	var index: int = get_index(tile)
	terrain[index] = terrain_value


## Returns whether [param tile] can be traversed.
func is_walkable(tile: Vector2i) -> bool:
	if not is_inside(tile):
		return false
	return walkable[get_index(tile)] == 1


## Returns whether [param tile] is reachable from the spawn.
func is_reachable(tile: Vector2i) -> bool:
	if not is_inside(tile):
		return false
	return reachable[get_index(tile)] == 1


## Converts a tile coordinate to the world position of its top-left corner.
func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * tile_size, tile.y * tile_size)


## Converts a world position to the tile that contains it.
func world_to_tile(world: Vector2) -> Vector2i:
	var tile_x: int = floori(world.x / float(tile_size))
	var tile_y: int = floori(world.y / float(tile_size))
	return Vector2i(tile_x, tile_y)


## Returns the map size in world pixels.
func get_world_size() -> Vector2i:
	return Vector2i(width * tile_size, height * tile_size)


## Returns a copy of the point of interest tiles.
func get_poi_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = poi_tiles.duplicate()
	return result


## Returns the spawn tile.
func get_spawn_tile() -> Vector2i:
	return spawn_tile
