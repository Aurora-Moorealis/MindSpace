class_name Astronaut
extends CharacterBody2D
## Player-controlled astronaut that walks across the generated lunar surface.
##
## Movement is resolved against the [LunarMap] walkability flags instead of the
## TileSet physics layers: every substep tests a small collision box on the X
## axis first and on the Y axis afterwards, so blocked movement slides along the
## free axis. The map is the single source of truth for terrain and bounds.

## Walking speed in world pixels per second, before the player speed multiplier.
@export var base_speed: float = 160.0

## Side of the square collision box, in world pixels.
const COLLISION_SIZE: float = 12.0
## Half side of the collision box, used to build its four corners.
const HALF_COLLISION_SIZE: float = COLLISION_SIZE * 0.5
## Longest distance a single collision substep may cover.
const MAX_SUBSTEP: float = 8.0

## Sprite frames of astronaut_4dir.png: down, up, left and right.
const FRAME_DOWN: int = 0
const FRAME_UP: int = 1
const FRAME_LEFT: int = 2
const FRAME_RIGHT: int = 3

## Map the astronaut walks on. Null until [method setup] is called.
var _map: LunarMap = null
## Last facing frame, kept so it can be applied once the sprite is available.
var _facing_frame: int = FRAME_DOWN

@onready var _sprite: Sprite2D = $Sprite2D


## Applies the current facing frame once the scene nodes exist.
func _ready() -> void:
	_apply_frame(_facing_frame)


## Binds the astronaut to [param map] and places it at the center of its spawn
## tile with the default downward-facing frame.
func setup(map: LunarMap) -> void:
	_map = map
	var half_tile: Vector2 = Vector2(float(map.tile_size), float(map.tile_size)) * 0.5
	position = map.tile_to_world(map.spawn_tile) + half_tile
	_facing_frame = FRAME_DOWN
	_apply_frame(_facing_frame)


## Moves the astronaut for [param delta] seconds along [param direction].
##
## The displacement is split into substeps of at most [constant MAX_SUBSTEP]
## pixels so low framerates cannot tunnel through a tile. Each substep tries the
## X axis and then the Y axis; a blocked axis is skipped while the other one
## still moves. The facing frame follows the input direction.
func move(direction: Vector2, delta: float) -> void:
	if _map == null or direction == Vector2.ZERO or delta <= 0.0:
		return
	_update_facing(direction)
	var speed: float = base_speed * GameSim.state.player.move_speed_multiplier
	var motion: Vector2 = direction.normalized() * speed * delta
	var substeps: int = maxi(1, ceili(motion.length() / MAX_SUBSTEP))
	var step: Vector2 = motion / float(substeps)
	for _step_index: int in range(substeps):
		var next_x: Vector2 = position + Vector2(step.x, 0.0)
		if is_zero_approx(step.x) or _can_stand_at(next_x):
			position.x = next_x.x
		var next_y: Vector2 = position + Vector2(0.0, step.y)
		if is_zero_approx(step.y) or _can_stand_at(next_y):
			position.y = next_y.y


## Reads the movement actions and walks while the simulation clock is running.
func _physics_process(delta: float) -> void:
	if GameSim.is_paused() or _map == null:
		return
	var direction: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	if direction != Vector2.ZERO:
		move(direction, delta)


## Returns whether the collision box centered on [param candidate] lies fully on
## walkable tiles inside the map.
func _can_stand_at(candidate: Vector2) -> bool:
	var corners: Array[Vector2] = [
		candidate + Vector2(-HALF_COLLISION_SIZE, -HALF_COLLISION_SIZE),
		candidate + Vector2(HALF_COLLISION_SIZE, -HALF_COLLISION_SIZE),
		candidate + Vector2(-HALF_COLLISION_SIZE, HALF_COLLISION_SIZE),
		candidate + Vector2(HALF_COLLISION_SIZE, HALF_COLLISION_SIZE),
	]
	for corner: Vector2 in corners:
		var tile: Vector2i = _map.world_to_tile(corner)
		if not _map.is_inside(tile) or not _map.is_walkable(tile):
			return false
	return true


## Stores and applies the sprite frame that matches [param direction]. A
## diagonal direction keeps the horizontal frame because the components tie.
func _update_facing(direction: Vector2) -> void:
	var frame: int = _facing_frame
	if absf(direction.x) >= absf(direction.y):
		frame = FRAME_RIGHT if direction.x > 0.0 else FRAME_LEFT
	else:
		frame = FRAME_DOWN if direction.y > 0.0 else FRAME_UP
	_facing_frame = frame
	_apply_frame(frame)


## Writes [param frame] to the sprite.
##
## The sprite is resolved lazily because a headless harness may call
## [method setup] or [method move] before the node receives its first frame.
func _apply_frame(frame: int) -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite == null:
		return
	_sprite.frame = frame
