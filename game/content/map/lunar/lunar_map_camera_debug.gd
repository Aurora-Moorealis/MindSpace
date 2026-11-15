class_name LunarMapCameraDebug
extends Node2D
## Review scene for a generated lunar map with a free-panning camera.
##
## Instances [constant WORLD_SCENE] as a [LunarMapWorld], keeps a reference to
## its generated [LunarMap] and its [Camera2D], and pans that camera with the
## W/A/S/D keys. Every pan is clamped to the map bounds, so the review never
## scrolls past the edges of the generated map. This is a development tool
## only: it is not gameplay and not the project main scene.

const WORLD_SCENE: PackedScene = preload("res://content/map/lunar/lunar_map_world.tscn")
## Viewport size used when the real viewport reports zero (headless runs).
const FALLBACK_VIEWPORT_SIZE: Vector2 = Vector2(850.0, 480.0)
## Name of the [Camera2D] node owned by the instanced world scene.
const WORLD_CAMERA_NAME: String = "Camera2D"

## Configuration used to build the map. A null value means the world defaults.
@export var config: LunarMapConfig
## Camera panning speed in world pixels per second.
@export var pan_speed: float = 384.0

var _world: LunarMapWorld
var _camera: Camera2D
var _map: LunarMap


func _ready() -> void:
	_world = WORLD_SCENE.instantiate() as LunarMapWorld
	if _world == null:
		push_error("LunarMapCameraDebug: the world scene is not a LunarMapWorld.")
		return
	if config != null:
		_world.config = config
	add_child(_world)
	# The world generates its map and paints its layers from _ready, and a frame
	# has to elapse before the map is available in headless runs.
	await get_tree().process_frame
	_map = _world.get_map()
	_camera = _world.get_node_or_null(WORLD_CAMERA_NAME) as Camera2D
	_clamp_camera()


func _process(delta: float) -> void:
	var direction: Vector2 = _read_direction()
	if direction != Vector2.ZERO:
		pan_camera(direction, delta)


## Returns the generated map, or null before the world finishes its setup.
func get_map() -> LunarMap:
	return _map


## Returns the world camera, or null before the world finishes its setup.
func get_camera() -> Camera2D:
	return _camera


## Moves the camera along [param direction] for [param delta] seconds.
##
## [param direction] is normalized, so diagonals travel at [member pan_speed]
## too. The resulting position is clamped to the map bounds.
func pan_camera(direction: Vector2, delta: float) -> void:
	if _camera == null or direction == Vector2.ZERO:
		return
	_camera.position += direction.normalized() * pan_speed * delta
	_clamp_camera()


## Returns the direction requested by the physical W/A/S/D keys.
func _read_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction.x += 1.0
	return direction


## Keeps the camera inside the map, centring it when the map is smaller.
func _clamp_camera() -> void:
	if _camera == null or _map == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = FALLBACK_VIEWPORT_SIZE
	var half_view: Vector2 = viewport_size / (2.0 * _camera.zoom)
	var world_size: Vector2 = Vector2(_map.get_world_size())
	_camera.position = Vector2(
		_clamp_axis(_camera.position.x, half_view.x, world_size.x),
		_clamp_axis(_camera.position.y, half_view.y, world_size.y),
	)


## Clamps one axis to the map bounds, or centres it when the map is smaller.
func _clamp_axis(value: float, half_view: float, world_extent: float) -> float:
	if world_extent <= half_view * 2.0:
		return world_extent * 0.5
	return clampf(value, half_view, world_extent - half_view)
