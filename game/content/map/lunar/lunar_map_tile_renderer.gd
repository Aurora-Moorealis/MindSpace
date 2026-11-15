class_name LunarMapTileRenderer
extends RefCounted
## Paints a generated [LunarMap] onto the three tile layers of the world.
##
## The renderer is a thin bridge between the map data and [TileMapLayer]: it
## validates the layers, clears their previous contents and writes one cell per
## grid tile through [LunarMapTileMapper]. It creates no nodes, adds no
## collision, never touches the TileSets and reads no autoloads, so the caller
## owns the layers and their assets.
##
## Painting is idempotent: every atlas coordinate comes from the pure mapper, so
## the same map always produces exactly the same cells, and clearing first means
## repainting a smaller map over a bigger one leaves no stale cells behind.


## Replaces the contents of [param ground], [param base] and [param props] with
## the representation of [param map].
##
## [param ground] receives a tile for every cell of the grid. [param base] only
## receives the landing pad platform, and [param props] only receives the solid
## rocks and ridges; the terrain is checked again here, independently of the
## mapper, so a walkable cell can never receive a prop.
##
## A null layer is warned about and nothing is painted. A null map only cleans
## the three layers.
static func paint(
	map: LunarMap, ground: TileMapLayer, base: TileMapLayer, props: TileMapLayer
) -> void:
	if ground == null or base == null or props == null:
		if ground == null:
			push_warning("LunarMapTileRenderer.paint: the ground layer is null; nothing is painted.")
		if base == null:
			push_warning("LunarMapTileRenderer.paint: the base layer is null; nothing is painted.")
		if props == null:
			push_warning("LunarMapTileRenderer.paint: the props layer is null; nothing is painted.")
		return

	ground.clear()
	base.clear()
	props.clear()

	if map == null:
		return

	for y: int in range(map.height):
		for x: int in range(map.width):
			var tile: Vector2i = Vector2i(x, y)
			_paint_ground(map, tile, ground)
			_paint_base(map, tile, base)
			_paint_props(map, tile, props)


## Writes the ground tile of [param tile] into [param layer] when it exists.
static func _paint_ground(map: LunarMap, tile: Vector2i, layer: TileMapLayer) -> void:
	var atlas: Vector2i = LunarMapTileMapper.ground_atlas(map, tile)
	if atlas == LunarMapTileMapper.NO_ATLAS:
		return
	layer.set_cell(
		tile,
		LunarMapTileMapper.SOURCE_ID,
		atlas,
		LunarMapTileMapper.ALTERNATIVE_TILE
	)


## Writes the landing pad tile of [param tile] into [param layer] when it exists.
static func _paint_base(map: LunarMap, tile: Vector2i, layer: TileMapLayer) -> void:
	var atlas: Vector2i = LunarMapTileMapper.base_atlas(map, tile)
	if atlas == LunarMapTileMapper.NO_ATLAS:
		return
	layer.set_cell(
		tile,
		LunarMapTileMapper.SOURCE_ID,
		atlas,
		LunarMapTileMapper.ALTERNATIVE_TILE
	)


## Writes the prop tile of [param tile] into [param layer] when the cell is a
## solid obstacle and it has a prop.
##
## The terrain is re-checked against [enum LunarMap.Terrain] so the solid prop
## layer can never disagree with [method LunarMap.is_walkable] because of a
## mapper change.
static func _paint_props(map: LunarMap, tile: Vector2i, layer: TileMapLayer) -> void:
	var terrain: LunarMap.Terrain = map.get_terrain(tile)
	if terrain != LunarMap.Terrain.ROCK and terrain != LunarMap.Terrain.RIDGE:
		return

	var atlas: Vector2i = LunarMapTileMapper.prop_atlas(map, tile)
	if atlas == LunarMapTileMapper.NO_ATLAS:
		return
	layer.set_cell(
		tile,
		LunarMapTileMapper.SOURCE_ID,
		atlas,
		LunarMapTileMapper.ALTERNATIVE_TILE
	)
