extends SceneTree
## Headless smoke test for the lunar map tile representation.
##
## Paints generated maps into throwaway [TileMapLayer] nodes and checks the
## observable contract of the mapper, the renderer and the playable world scene:
## full grid coverage, terrain mapping, landing pad platform, solid props,
## determinism, repainting, scene wiring and the debug review camera. It needs no
## editor, display or input, and it never modifies the tested modules.
##
## Run with:
##   godot --headless --path game --script res://content/map/lunar/lunar_map_render_smoke.gd
##
## Exits with code 0 when every check passes and 1 otherwise.

const WORLD_SCENE: PackedScene = preload("res://content/map/lunar/lunar_map_world.tscn")
const CAMERA_DEBUG_SCENE_PATH: String = "res://content/map/lunar/lunar_map_camera_debug.tscn"
const GROUND_TILESET: TileSet = preload("res://content/map/tiles/ground_tileset.tres")
const BASE_TILESET: TileSet = preload("res://content/map/tiles/base_tileset.tres")
const PROPS_TILESET: TileSet = preload("res://content/map/props/props_tileset.tres")

const TERRAIN_MARE: int = int(LunarMap.Terrain.MARE)
const TERRAIN_HIGHLAND: int = int(LunarMap.Terrain.HIGHLAND)
const TERRAIN_CRATER_FLOOR: int = int(LunarMap.Terrain.CRATER_FLOOR)
const TERRAIN_CRATER_RIM: int = int(LunarMap.Terrain.CRATER_RIM)
const TERRAIN_EJECTA: int = int(LunarMap.Terrain.EJECTA)
const TERRAIN_RIDGE: int = int(LunarMap.Terrain.RIDGE)
const TERRAIN_ROCK: int = int(LunarMap.Terrain.ROCK)
const TERRAIN_LANDING_PAD: int = int(LunarMap.Terrain.LANDING_PAD)
const TERRAIN_COUNT: int = 8

const DEFAULT_SIZE: int = 64
const SMALL_SIZE: int = 16
const WIDE_WIDTH: int = 120
const WIDE_HEIGHT: int = 80
## Terrain byte outside [enum LunarMap.Terrain], written straight into the grid.
const UNKNOWN_TERRAIN: int = 99
const SAFE_GROUND_ATLAS: Vector2i = Vector2i(0, 0)
const CAMERA_ZOOM: Vector2 = Vector2(1.0, 1.0)
## Frames awaited while the debug camera scene finishes its deferred setup.
const CAMERA_DEBUG_SETTLE_FRAMES: int = 10
## Simulated pan used to check that the camera moves in a direction.
const PAN_STEP_SECONDS: float = 0.5
## Large simulated pan that pushes the camera against the map border.
const PAN_OVERSHOOT_SECONDS: float = 10000.0
## Atlas coordinates of the mineral row that this capability must never paint.
const MINERAL_ATLAS_COORDS: Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(2, 1),
	Vector2i(3, 1),
	Vector2i(4, 1),
]

var _checks: int = 0
var _failures: int = 0


## Three throwaway tile layers owned by the harness.
##
## The layers never enter the scene tree, so they must be freed explicitly with
## [method free_layers] once the checks that use them are done.
class RenderLayers:
	var ground_layer: TileMapLayer
	var base_layer: TileMapLayer
	var props_layer: TileMapLayer

	func _init(ground: TileMapLayer, base: TileMapLayer, props: TileMapLayer) -> void:
		ground_layer = ground
		base_layer = base
		props_layer = props

	## Frees the three layers immediately.
	func free_layers() -> void:
		ground_layer.free()
		base_layer.free()
		props_layer.free()


func _initialize() -> void:
	_check_coverage()
	_check_terrain_mapping()
	_check_landing_platform()
	_check_props()
	_check_determinism()
	_check_repaint()
	await _check_world_scene()
	await _check_debug_camera_scene()

	print("lunar_map_render_smoke: %d checks, %d failure(s)" % [_checks, _failures])
	if _failures == 0:
		print("lunar_map_render_smoke: PASSED")
		quit(0)
	else:
		printerr("lunar_map_render_smoke: FAILED")
		quit(1)


# ---------------------------------------------------------------------------
# Check 1: the ground layer covers the whole grid without stray cells
# ---------------------------------------------------------------------------


func _check_coverage() -> void:
	var map: LunarMap = _generate_default()
	_check(map.width == DEFAULT_SIZE and map.height == DEFAULT_SIZE, "coverage fixture is a 64x64 map")

	var layers: RenderLayers = _paint(map)
	var ground_cells: Array[Vector2i] = layers.ground_layer.get_used_cells()
	_check(
		ground_cells.size() == DEFAULT_SIZE * DEFAULT_SIZE,
		"64x64 map paints %d ground cells" % [DEFAULT_SIZE * DEFAULT_SIZE],
	)
	_check(
		_cells_are_inside(ground_cells, DEFAULT_SIZE, DEFAULT_SIZE),
		"every ground cell of the 64x64 map is inside the grid",
	)
	_check(
		_every_cell_has_data(layers.ground_layer, ground_cells),
		"every ground cell of the 64x64 map has tile data",
	)
	_check(
		_cells_are_inside(layers.base_layer.get_used_cells(), DEFAULT_SIZE, DEFAULT_SIZE)
		and _cells_are_inside(layers.props_layer.get_used_cells(), DEFAULT_SIZE, DEFAULT_SIZE),
		"every base and props cell of the 64x64 map is inside the grid",
	)
	layers.free_layers()

	var wide_config: LunarMapConfig = _new_config()
	wide_config.width = WIDE_WIDTH
	wide_config.height = WIDE_HEIGHT
	var wide_map: LunarMap = _generate(wide_config)
	var wide_layers: RenderLayers = _paint(wide_map)
	_check(
		wide_layers.ground_layer.get_used_cells().size() == WIDE_WIDTH * WIDE_HEIGHT,
		"120x80 map paints %d ground cells" % [WIDE_WIDTH * WIDE_HEIGHT],
	)
	_check(
		_cells_are_inside(wide_layers.ground_layer.get_used_cells(), WIDE_WIDTH, WIDE_HEIGHT),
		"every ground cell of the 120x80 map is inside the grid",
	)
	wide_layers.free_layers()


# ---------------------------------------------------------------------------
# Check 2: every default terrain kind and the unknown-terrain fallback
# ---------------------------------------------------------------------------


func _check_terrain_mapping() -> void:
	var map: LunarMap = _generate_default()
	var layers: RenderLayers = _paint(map)
	var counts: PackedInt32Array = _terrain_counts(map)

	for terrain: int in range(TERRAIN_COUNT):
		_check(counts[terrain] > 0, "default map contains %s tiles" % [_terrain_name(terrain)])

	_check(
		_every_cell_has_data(layers.ground_layer, layers.ground_layer.get_used_cells()),
		"every default map cell receives a valid ground tile",
	)
	_check(
		_ground_matches_mapper(map, layers.ground_layer),
		"the ground layer matches the mapper atlas coordinate cell by cell",
	)
	layers.free_layers()

	var unknown_map: LunarMap = _generate_default()
	var unknown_tile: Vector2i = Vector2i(
		unknown_map.width / 2 + 3, unknown_map.height / 2 + 3
	)
	_check(unknown_map.is_inside(unknown_tile), "unknown terrain fixture uses an interior cell")
	var unknown_index: int = unknown_map.get_index(unknown_tile)
	unknown_map.terrain[unknown_index] = UNKNOWN_TERRAIN
	_check(
		int(unknown_map.terrain[unknown_index]) == UNKNOWN_TERRAIN,
		"unknown terrain value is stored in the grid",
	)

	var unknown_atlas: Vector2i = LunarMapTileMapper.ground_atlas(unknown_map, unknown_tile)
	_check(
		unknown_atlas == SAFE_GROUND_ATLAS,
		"ground_atlas returns (0, 0) for an unknown terrain value",
	)

	var unknown_layers: RenderLayers = _paint(unknown_map)
	_check(
		unknown_layers.ground_layer.get_cell_tile_data(unknown_tile) != null,
		"an unknown terrain cell still paints a valid ground tile",
	)
	unknown_layers.free_layers()


# ---------------------------------------------------------------------------
# Check 3: the landing pad platform and the spawn
# ---------------------------------------------------------------------------


func _check_landing_platform() -> void:
	var map: LunarMap = _generate_default()
	var layers: RenderLayers = _paint(map)
	var pad_cells: Array[Vector2i] = _cells_with_terrain(map, TERRAIN_LANDING_PAD)
	var pad_set: Dictionary[Vector2i, bool] = _cell_set(pad_cells)
	var base_cells: Array[Vector2i] = layers.base_layer.get_used_cells()
	var base_set: Dictionary[Vector2i, bool] = _cell_set(base_cells)

	_check(not pad_cells.is_empty(), "default map contains landing pad cells")
	_check(
		base_cells.size() == pad_cells.size(),
		"the base layer paints one tile per landing pad cell",
	)
	_check(_all_in_set(base_cells, pad_set), "every base cell is a landing pad cell")
	_check(_all_in_set(pad_cells, base_set), "every landing pad cell has a base tile")
	_check(base_set.has(map.spawn_tile), "the spawn tile has a base tile")
	_check(
		not _any_in_set(layers.props_layer.get_used_cells(), pad_set),
		"the landing pad contains no props",
	)
	layers.free_layers()


# ---------------------------------------------------------------------------
# Check 4: solid props on exactly the blocked rock and ridge cells
# ---------------------------------------------------------------------------


func _check_props() -> void:
	var map: LunarMap = _generate_default()
	var layers: RenderLayers = _paint(map)
	var prop_cells: Array[Vector2i] = layers.props_layer.get_used_cells()

	_check(not prop_cells.is_empty(), "default map paints solid props")

	var blocked_cells: int = 0
	for index: int in range(map.walkable.size()):
		if map.walkable[index] == 0:
			blocked_cells += 1
	_check(
		prop_cells.size() == blocked_cells,
		"the props layer covers all %d blocked cells" % [blocked_cells],
	)

	var only_obstacles: bool = true
	var only_blocked: bool = true
	var every_prop_solid: bool = true
	var no_mineral: bool = true
	for cell: Vector2i in prop_cells:
		var terrain: LunarMap.Terrain = map.get_terrain(cell)
		if terrain != LunarMap.Terrain.ROCK and terrain != LunarMap.Terrain.RIDGE:
			only_obstacles = false
		if map.is_walkable(cell):
			only_blocked = false
		var tile_data: TileData = layers.props_layer.get_cell_tile_data(cell)
		if tile_data == null:
			every_prop_solid = false
		else:
			var solid: bool = bool(tile_data.get_custom_data("solid"))
			if not solid:
				every_prop_solid = false
		var atlas: Vector2i = layers.props_layer.get_cell_atlas_coords(cell)
		if MINERAL_ATLAS_COORDS.has(atlas):
			no_mineral = false

	_check(only_obstacles, "every prop sits on a ROCK or RIDGE cell")
	_check(only_blocked, "no walkable cell receives a prop")
	_check(every_prop_solid, "every prop tile has solid custom data set to true")
	_check(no_mineral, "the props layer never uses mineral atlas coordinates")
	layers.free_layers()


# ---------------------------------------------------------------------------
# Check 5: determinism with the same seed and variation between seeds
# ---------------------------------------------------------------------------


func _check_determinism() -> void:
	var config: LunarMapConfig = _new_config()
	var first_map: LunarMap = _generate(config)
	var second_map: LunarMap = _generate(config)
	var first_layers: RenderLayers = _paint(first_map)
	var second_layers: RenderLayers = _paint(second_map)

	_check(
		_layers_match(first_layers, second_layers, first_map.width, first_map.height),
		"the same seed paints identical atlas coordinates cell by cell",
	)
	first_layers.free_layers()
	second_layers.free_layers()

	var other_config: LunarMapConfig = _new_config()
	other_config.seed = config.seed + 1
	var baseline_map: LunarMap = _generate(config)
	var other_map: LunarMap = _generate(other_config)
	var baseline_layers: RenderLayers = _paint(baseline_map)
	var other_layers: RenderLayers = _paint(other_map)
	_check(
		_ground_atlas_differs(
			baseline_layers.ground_layer,
			other_layers.ground_layer,
			other_map.width,
			other_map.height,
		),
		"a different seed changes at least one ground tile",
	)
	baseline_layers.free_layers()
	other_layers.free_layers()


# ---------------------------------------------------------------------------
# Check 6: repainting a smaller map clears the previous one
# ---------------------------------------------------------------------------


func _check_repaint() -> void:
	var big_map: LunarMap = _generate_default()
	var small_config: LunarMapConfig = _new_config()
	small_config.width = SMALL_SIZE
	small_config.height = SMALL_SIZE
	var small_map: LunarMap = _generate(small_config)

	var layers: RenderLayers = _new_layers()
	LunarMapTileRenderer.paint(
		big_map, layers.ground_layer, layers.base_layer, layers.props_layer
	)
	_check(
		layers.ground_layer.get_used_cells().size() == DEFAULT_SIZE * DEFAULT_SIZE,
		"the big map paints a full ground layer before repainting",
	)

	LunarMapTileRenderer.paint(
		small_map, layers.ground_layer, layers.base_layer, layers.props_layer
	)
	_check(
		layers.ground_layer.get_used_cells().size() == SMALL_SIZE * SMALL_SIZE,
		"repainting a 16x16 map leaves exactly %d ground cells" % [SMALL_SIZE * SMALL_SIZE],
	)
	_check(
		_cells_are_inside(layers.ground_layer.get_used_cells(), SMALL_SIZE, SMALL_SIZE)
		and _cells_are_inside(layers.base_layer.get_used_cells(), SMALL_SIZE, SMALL_SIZE)
		and _cells_are_inside(layers.props_layer.get_used_cells(), SMALL_SIZE, SMALL_SIZE),
		"repainting leaves no ground, base or props cell outside the 16x16 grid",
	)
	layers.free_layers()


# ---------------------------------------------------------------------------
# Check 7: the playable world scene loads, paints and centres the camera
# ---------------------------------------------------------------------------


func _check_world_scene() -> void:
	var world: LunarMapWorld = WORLD_SCENE.instantiate() as LunarMapWorld
	_check(world != null, "the world scene instantiates as LunarMapWorld")
	if world == null:
		return

	root.add_child(world)
	# The world generates its map and paints its layers from _ready, and the
	# tree needs one frame to complete the deferred setup in the harness.
	await process_frame

	var map: LunarMap = world.get_map()
	_check(map != null, "the world scene generates a map on ready")
	if map == null:
		world.free()
		return

	var ground: TileMapLayer = world.get_node_or_null("Ground") as TileMapLayer
	var base: TileMapLayer = world.get_node_or_null("Base") as TileMapLayer
	var props: TileMapLayer = world.get_node_or_null("Props") as TileMapLayer
	_check(ground != null, "the world scene has a Ground TileMapLayer")
	_check(base != null, "the world scene has a Base TileMapLayer")
	_check(props != null, "the world scene has a Props TileMapLayer")
	_check_world_layer(ground, "Ground")
	_check_world_layer(base, "Base")
	_check_world_layer(props, "Props")

	var camera: Camera2D = world.get_node_or_null("Camera2D") as Camera2D
	_check(camera != null, "the world scene has a Camera2D")
	if camera != null:
		var tile_extent: Vector2 = Vector2(float(map.tile_size), float(map.tile_size))
		var expected: Vector2 = map.tile_to_world(map.spawn_tile) + tile_extent * 0.5
		_check(
			camera.position.is_equal_approx(expected),
			"the camera is centred on the spawn tile",
		)
		_check(camera.zoom == CAMERA_ZOOM, "the camera keeps a 1:1 zoom")

	world.free()


# ---------------------------------------------------------------------------
# Check 8: the debug review scene pans and clamps its camera
# ---------------------------------------------------------------------------


func _check_debug_camera_scene() -> void:
	var packed: PackedScene = load(CAMERA_DEBUG_SCENE_PATH) as PackedScene
	_check(packed != null, "the debug camera scene loads")
	if packed == null:
		return

	var viewer: LunarMapCameraDebug = packed.instantiate() as LunarMapCameraDebug
	_check(viewer != null, "the debug camera scene instantiates as LunarMapCameraDebug")
	if viewer == null:
		return

	root.add_child(viewer)
	# The viewer waits one frame in _ready before reading the world map, so the
	# harness polls for a few frames instead of assuming a single one.
	var map: LunarMap = null
	for _frame: int in range(CAMERA_DEBUG_SETTLE_FRAMES):
		await process_frame
		map = viewer.get_map()
		if map != null:
			break
	_check(map != null, "the debug camera scene exposes the generated map")
	var camera: Camera2D = viewer.get_camera()
	_check(camera != null, "the debug camera scene exposes the world Camera2D")
	if map == null or camera == null:
		viewer.free()
		return

	var tile_extent: Vector2 = Vector2(float(map.tile_size), float(map.tile_size))
	var spawn_center: Vector2 = map.tile_to_world(map.spawn_tile) + tile_extent * 0.5
	_check(
		camera.position.is_equal_approx(spawn_center),
		"the debug camera starts centred on the spawn tile",
	)

	var before_pan: Vector2 = camera.position
	viewer.pan_camera(Vector2.ZERO, PAN_STEP_SECONDS)
	_check(
		camera.position.is_equal_approx(before_pan),
		"panning with a zero direction leaves the camera untouched",
	)

	viewer.pan_camera(Vector2.RIGHT, PAN_STEP_SECONDS)
	_check(
		camera.position.x > before_pan.x and is_equal_approx(camera.position.y, before_pan.y),
		"pan_camera moves the camera to the right at constant pan_speed",
	)

	viewer.pan_camera(Vector2.LEFT, PAN_OVERSHOOT_SECONDS)
	var left_border: Vector2 = camera.position
	_check(
		left_border.x < before_pan.x,
		"pan_camera moves the camera back to the left of the spawn",
	)
	viewer.pan_camera(Vector2.LEFT, PAN_OVERSHOOT_SECONDS)
	var world_size: Vector2i = map.get_world_size()
	_check(
		camera.position.is_equal_approx(left_border),
		"the camera stops at the left map border instead of scrolling past it",
	)
	_check(
		left_border.x >= 0.0
		and left_border.x <= float(world_size.x) * 0.5
		and left_border.y >= 0.0
		and left_border.y <= float(world_size.y),
		"the clamped camera stays inside the left half of the map",
	)

	viewer.free()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _new_config() -> LunarMapConfig:
	return LunarMapConfig.new()


func _generate(config: LunarMapConfig) -> LunarMap:
	return LunarMapGenerator.generate(config)


func _generate_default() -> LunarMap:
	return _generate(_new_config())


func _new_layers() -> RenderLayers:
	var ground: TileMapLayer = TileMapLayer.new()
	ground.tile_set = GROUND_TILESET
	var base: TileMapLayer = TileMapLayer.new()
	base.tile_set = BASE_TILESET
	var props: TileMapLayer = TileMapLayer.new()
	props.tile_set = PROPS_TILESET
	return RenderLayers.new(ground, base, props)


func _paint(map: LunarMap) -> RenderLayers:
	var layers: RenderLayers = _new_layers()
	LunarMapTileRenderer.paint(
		map, layers.ground_layer, layers.base_layer, layers.props_layer
	)
	return layers


func _terrain_counts(map: LunarMap) -> PackedInt32Array:
	var counts: PackedInt32Array = PackedInt32Array()
	counts.resize(TERRAIN_COUNT)
	counts.fill(0)
	for value: int in map.terrain:
		if value >= 0 and value < TERRAIN_COUNT:
			counts[value] += 1
	return counts


func _terrain_name(terrain: int) -> String:
	match terrain:
		TERRAIN_MARE:
			return "MARE"
		TERRAIN_HIGHLAND:
			return "HIGHLAND"
		TERRAIN_CRATER_FLOOR:
			return "CRATER_FLOOR"
		TERRAIN_CRATER_RIM:
			return "CRATER_RIM"
		TERRAIN_EJECTA:
			return "EJECTA"
		TERRAIN_RIDGE:
			return "RIDGE"
		TERRAIN_ROCK:
			return "ROCK"
		TERRAIN_LANDING_PAD:
			return "LANDING_PAD"
		_:
			return "UNKNOWN"


func _cells_with_terrain(map: LunarMap, terrain: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(map.height):
		for x: int in range(map.width):
			var tile: Vector2i = Vector2i(x, y)
			if int(map.get_terrain(tile)) == terrain:
				cells.append(tile)
	return cells


func _cell_set(cells: Array[Vector2i]) -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in cells:
		result[cell] = true
	return result


func _all_in_set(cells: Array[Vector2i], cell_set: Dictionary[Vector2i, bool]) -> bool:
	for cell: Vector2i in cells:
		if not cell_set.has(cell):
			return false
	return true


func _any_in_set(cells: Array[Vector2i], cell_set: Dictionary[Vector2i, bool]) -> bool:
	for cell: Vector2i in cells:
		if cell_set.has(cell):
			return true
	return false


func _cells_are_inside(cells: Array[Vector2i], width: int, height: int) -> bool:
	for cell: Vector2i in cells:
		if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
			return false
	return true


func _every_cell_has_data(layer: TileMapLayer, cells: Array[Vector2i]) -> bool:
	for cell: Vector2i in cells:
		if layer.get_cell_tile_data(cell) == null:
			return false
	return true


func _ground_matches_mapper(map: LunarMap, layer: TileMapLayer) -> bool:
	for y: int in range(map.height):
		for x: int in range(map.width):
			var tile: Vector2i = Vector2i(x, y)
			var expected: Vector2i = LunarMapTileMapper.ground_atlas(map, tile)
			if expected == LunarMapTileMapper.NO_ATLAS:
				return false
			if layer.get_cell_source_id(tile) != LunarMapTileMapper.SOURCE_ID:
				return false
			if layer.get_cell_atlas_coords(tile) != expected:
				return false
	return true


func _layers_match(
	first: RenderLayers, second: RenderLayers, width: int, height: int
) -> bool:
	for y: int in range(height):
		for x: int in range(width):
			var tile: Vector2i = Vector2i(x, y)
			if (
				first.ground_layer.get_cell_atlas_coords(tile)
				!= second.ground_layer.get_cell_atlas_coords(tile)
			):
				return false
			if (
				first.base_layer.get_cell_atlas_coords(tile)
				!= second.base_layer.get_cell_atlas_coords(tile)
			):
				return false
			if (
				first.props_layer.get_cell_atlas_coords(tile)
				!= second.props_layer.get_cell_atlas_coords(tile)
			):
				return false
	return true


func _ground_atlas_differs(
	first: TileMapLayer, second: TileMapLayer, width: int, height: int
) -> bool:
	for y: int in range(height):
		for x: int in range(width):
			var tile: Vector2i = Vector2i(x, y)
			if first.get_cell_atlas_coords(tile) != second.get_cell_atlas_coords(tile):
				return true
	return false


func _check_world_layer(layer: TileMapLayer, label: String) -> void:
	if layer == null:
		return
	_check(layer.tile_set != null, "the %s layer has a TileSet" % [label])
	_check(
		layer.get_used_cells().size() > 0,
		"the %s layer has cells" % [label],
	)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("[PASS] ", label)
	else:
		_failures += 1
		printerr("[FAIL] ", label)
