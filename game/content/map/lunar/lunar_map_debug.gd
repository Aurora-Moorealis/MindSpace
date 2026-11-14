class_name LunarMapDebug
extends Node2D
## Debug view for a procedurally generated [LunarMap].
##
## Draws every tile as a flat colour rectangle with [method CanvasItem._draw],
## so it needs no textures, tile maps or imported image assets. It also frames
## the map with a [Camera2D] and prints a small info label. This is a
## development tool only: it is not gameplay and not the project main scene.

## Viewport size used when the real viewport reports zero (headless runs).
const FALLBACK_VIEWPORT_SIZE: Vector2 = Vector2(850.0, 480.0)
## Extra space kept around the map when the camera frames it.
const CAMERA_MARGIN: float = 1.1
## Smallest accepted zoom, so the camera never ends up with a zero scale.
const MIN_CAMERA_ZOOM: float = 0.0001

const MARE_COLOR: Color = Color(0.30, 0.30, 0.32)
const HIGHLAND_COLOR: Color = Color(0.62, 0.62, 0.64)
const CRATER_FLOOR_COLOR: Color = Color(0.14, 0.14, 0.16)
const CRATER_RIM_COLOR: Color = Color(0.90, 0.90, 0.92)
const EJECTA_COLOR: Color = Color(0.46, 0.46, 0.48)
const RIDGE_COLOR: Color = Color(0.34, 0.24, 0.16)
const ROCK_COLOR: Color = Color(0.06, 0.06, 0.07)
const LANDING_PAD_COLOR: Color = Color(0.12, 0.52, 0.50)
const UNKNOWN_TERRAIN_COLOR: Color = Color(1.0, 0.0, 1.0)
const GRID_COLOR: Color = Color(0.0, 0.0, 0.0, 0.25)
const SPAWN_COLOR: Color = Color(0.15, 0.95, 0.25)
const POI_COLOR: Color = Color(1.0, 0.72, 0.12)
const SPAWN_RADIUS_RATIO: float = 0.42
const POI_RADIUS_RATIO: float = 0.30

const OVERLAY_NAME: String = "DebugOverlay"
const INFO_LABEL_NAME: String = "InfoLabel"
const INFO_LABEL_MARGIN: Vector2 = Vector2(8.0, 6.0)
const INFO_LABEL_FONT_SIZE: int = 12
const INFO_LABEL_COLOR: Color = Color(1.0, 1.0, 1.0)
const INFO_LABEL_OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.85)
const INFO_LABEL_OUTLINE_SIZE: int = 3

## Configuration used to build the map. A null value means defaults.
@export var config: LunarMapConfig
## Draws the outline of every tile when enabled.
@export var show_grid: bool = false
## Draws the points of interest when enabled.
@export var show_pois: bool = true

## Generated map shown by this node.
var map: LunarMap

var _info_label: Label = null


func _ready() -> void:
	var effective_config: LunarMapConfig = config
	if effective_config == null:
		effective_config = LunarMapConfig.new()
	map = LunarMapGenerator.generate(effective_config)
	var camera: Camera2D = _ensure_camera()
	_frame_camera(camera)
	_info_label = _ensure_info_label()
	_update_info_label()
	queue_redraw()


## Returns the generated map, or null before [method _ready] runs.
func get_map() -> LunarMap:
	return map


func _draw() -> void:
	if map == null:
		return
	var tile_extent: Vector2 = Vector2(float(map.tile_size), float(map.tile_size))
	for y: int in range(map.height):
		for x: int in range(map.width):
			var index: int = y * map.width + x
			var terrain_value: int = map.terrain[index]
			var tile_origin: Vector2 = Vector2(float(x), float(y)) * float(map.tile_size)
			var tile_rect: Rect2 = Rect2(tile_origin, tile_extent)
			draw_rect(tile_rect, _terrain_color(terrain_value), true)
			if show_grid:
				draw_rect(tile_rect, GRID_COLOR, false, 1.0)
	_draw_spawn()
	if show_pois:
		_draw_pois()


# ---------------------------------------------------------------------------
# Colours and markers
# ---------------------------------------------------------------------------


func _terrain_color(terrain_value: int) -> Color:
	match terrain_value:
		LunarMap.Terrain.MARE:
			return MARE_COLOR
		LunarMap.Terrain.HIGHLAND:
			return HIGHLAND_COLOR
		LunarMap.Terrain.CRATER_FLOOR:
			return CRATER_FLOOR_COLOR
		LunarMap.Terrain.CRATER_RIM:
			return CRATER_RIM_COLOR
		LunarMap.Terrain.EJECTA:
			return EJECTA_COLOR
		LunarMap.Terrain.RIDGE:
			return RIDGE_COLOR
		LunarMap.Terrain.ROCK:
			return ROCK_COLOR
		LunarMap.Terrain.LANDING_PAD:
			return LANDING_PAD_COLOR
	return UNKNOWN_TERRAIN_COLOR


func _draw_spawn() -> void:
	var radius: float = float(map.tile_size) * SPAWN_RADIUS_RATIO
	draw_circle(_tile_center(map.spawn_tile), radius, SPAWN_COLOR, true)


func _draw_pois() -> void:
	var radius: float = float(map.tile_size) * POI_RADIUS_RATIO
	for tile: Vector2i in map.poi_tiles:
		draw_circle(_tile_center(tile), radius, POI_COLOR, true)


func _tile_center(tile: Vector2i) -> Vector2:
	return map.tile_to_world(tile) + Vector2(
		float(map.tile_size), float(map.tile_size)
	) * 0.5


# ---------------------------------------------------------------------------
# Camera and info label
# ---------------------------------------------------------------------------


func _ensure_camera() -> Camera2D:
	for child: Node in get_children():
		if child is Camera2D:
			var existing: Camera2D = child as Camera2D
			existing.enabled = true
			return existing
	var camera: Camera2D = Camera2D.new()
	camera.name = "Camera2D"
	add_child(camera)
	return camera


func _frame_camera(camera: Camera2D) -> void:
	if camera == null or map == null:
		return
	var world_size: Vector2 = Vector2(map.get_world_size())
	world_size.x = maxf(world_size.x, 1.0)
	world_size.y = maxf(world_size.y, 1.0)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = FALLBACK_VIEWPORT_SIZE
	var zoom_x: float = viewport_size.x / (world_size.x * CAMERA_MARGIN)
	var zoom_y: float = viewport_size.y / (world_size.y * CAMERA_MARGIN)
	var zoom_value: float = maxf(minf(zoom_x, zoom_y), MIN_CAMERA_ZOOM)
	camera.zoom = Vector2(zoom_value, zoom_value)
	camera.position = world_size * 0.5
	camera.enabled = true
	camera.make_current()


func _ensure_info_label() -> Label:
	var overlay: CanvasLayer = _find_overlay()
	if overlay == null:
		overlay = CanvasLayer.new()
		overlay.name = OVERLAY_NAME
		overlay.layer = 1
		add_child(overlay)
	var label: Label = _find_info_label(overlay)
	if label == null:
		label = Label.new()
		label.name = INFO_LABEL_NAME
		overlay.add_child(label)
	label.position = INFO_LABEL_MARGIN
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", INFO_LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", INFO_LABEL_COLOR)
	label.add_theme_color_override("font_outline_color", INFO_LABEL_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", INFO_LABEL_OUTLINE_SIZE)
	return label


func _find_overlay() -> CanvasLayer:
	for child: Node in get_children():
		if child is CanvasLayer and child.name == OVERLAY_NAME:
			return child as CanvasLayer
	return null


func _find_info_label(overlay: CanvasLayer) -> Label:
	for child: Node in overlay.get_children():
		if child is Label and child.name == INFO_LABEL_NAME:
			return child as Label
	return null


func _update_info_label() -> void:
	if _info_label == null or map == null:
		return
	_info_label.text = "seed %d | %d x %d tiles | %d POIs" % [
		map.seed, map.width, map.height, map.poi_tiles.size()
	]
