class_name Astronaut
extends CharacterBody2D

## Player-controlled astronaut on the generated lunar surface.
##
## Movement is resolved against the [LunarMap] walkability flags instead of the
## TileSet physics layers: every substep tests a small collision box on the X
## axis first and on the Y axis afterwards, so blocked movement slides along the
## free axis. The map is the single source of truth for terrain and bounds.
##
## The astronaut also owns the player-side view of the run: it reports the suit
## and the interior/exterior state (surface, exterior zones and shelters) to
## [GameSim], picks the nearest interactable in range and publishes the vitals
## the HUD reads. Survival rules stay in SimState and the tick.

signal vitals_changed()
signal interaction_target_changed(target: Node)
signal suit_changed(level: int)

enum Suit { BASIC, SHIELDED }

## Walking speed in world pixels per second, before the player speed multiplier.
@export var base_speed: float = 160.0
## Suit the astronaut starts the run with.
@export var suit: Suit = Suit.BASIC
## Whether the spawn point counts as exterior. The surface is exterior by
## default; a shelter zone still wins over it while the astronaut is inside one.
@export var starts_outside: bool = true

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

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _interact_sensor: Area2D = $InteractSensor
@onready var _zone_sensor: Area2D = $ZoneSensor

## Map the astronaut walks on. Null until [method setup] is called.
var _map: LunarMap = null
## Last facing frame, kept so it can be applied once the sprite is available.
var _facing_frame: int = FRAME_DOWN
var _targets: Array[Node] = []
var _current_target: Node = null
var _exterior_areas: Dictionary[Area2D, bool] = {}
var _shelter_areas: Dictionary[Area2D, bool] = {}
var _alive: bool = true
## Set while a modal UI panel owns the input; movement and interaction stop.
var _input_locked: bool = false


func _ready() -> void:
	_interact_sensor.area_entered.connect(_on_interactable_entered)
	_interact_sensor.area_exited.connect(_on_interactable_exited)
	_zone_sensor.area_entered.connect(_on_zone_entered)
	_zone_sensor.area_exited.connect(_on_zone_exited)
	GameSim.tick_advanced.connect(_on_tick_advanced)
	GameSim.game_reset.connect(_on_game_reset)
	GameSim.game_over.connect(_on_game_over)
	GameSim.set_outside(starts_outside)
	_apply_suit()
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
	if not _alive or _input_locked or GameSim.is_paused() or _map == null:
		return
	var direction: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	if direction != Vector2.ZERO:
		move(direction, delta)


## Calls interact on the current target while the game is being played.
func _unhandled_input(event: InputEvent) -> void:
	if not _alive or _input_locked or GameSim.is_paused():
		return
	if event.is_action_pressed(&"interact"):
		_interact()


## Current interaction target, or null when no machine is in range.
func get_interaction_target() -> Node:
	return _current_target


func is_alive() -> bool:
	return _alive


func get_suit() -> Suit:
	return suit


## Changes the equipped suit and applies it to the run.
func set_suit(value: Suit) -> void:
	suit = value
	_apply_suit()


## Marks the astronaut as outside; used by the zone areas and by test scenes.
func set_outside(value: bool) -> void:
	GameSim.set_outside(value)


## Suspends or restores movement and interaction input, for example while a
## modal panel is open.
func set_input_locked(value: bool) -> void:
	_input_locked = value


func is_input_locked() -> bool:
	return _input_locked


func get_health() -> float:
	return GameSim.state.health


func get_oxygen() -> float:
	return GameSim.state.get_resource(SimState.OXYGEN)


func get_hunger() -> float:
	return GameSim.state.hunger


func get_thirst() -> float:
	return GameSim.state.thirst


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


func _interact() -> void:
	if _current_target == null:
		return
	if not _current_target.has_method(&"interact"):
		return
	_current_target.interact(self)


func _on_interactable_entered(area: Area2D) -> void:
	_add_target(area)


func _on_interactable_exited(area: Area2D) -> void:
	_remove_target(area)


func _add_target(area: Area2D) -> void:
	var candidate: Node = area.get_parent()
	if candidate == null or not candidate.has_method(&"interact"):
		return
	if not _targets.has(candidate):
		_targets.append(candidate)
	_refresh_target()


func _remove_target(area: Area2D) -> void:
	var candidate: Node = area.get_parent()
	if candidate == null:
		return
	_targets.erase(candidate)
	_refresh_target()


## Keeps the closest valid target and notifies listeners when it changes.
func _refresh_target() -> void:
	var nearest: Node = null
	var nearest_distance: float = INF
	var valid_targets: Array[Node] = []
	for target: Node in _targets:
		if not is_instance_valid(target):
			continue
		valid_targets.append(target)
		var node_2d: Node2D = target as Node2D
		if node_2d == null:
			continue
		var distance: float = global_position.distance_squared_to(node_2d.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = target
	_targets = valid_targets
	if nearest == _current_target:
		return
	_current_target = nearest
	interaction_target_changed.emit(_current_target)


func _on_zone_entered(area: Area2D) -> void:
	var tracked: bool = false
	if area.is_in_group(&"exterior_zones"):
		_exterior_areas[area] = true
		tracked = true
	if area.is_in_group(&"shelter_zones"):
		_shelter_areas[area] = true
		tracked = true
	if not tracked:
		return
	_apply_zone_state()


func _on_zone_exited(area: Area2D) -> void:
	var tracked: bool = false
	if area.is_in_group(&"exterior_zones"):
		_exterior_areas.erase(area)
		tracked = true
	if area.is_in_group(&"shelter_zones"):
		_shelter_areas.erase(area)
		tracked = true
	if not tracked:
		return
	_apply_zone_state()


## Publishes whether the astronaut is outside to [GameSim].
##
## The surface counts as exterior by default ([member starts_outside]) or while
## any exterior zone is overlapped. A shelter always wins: overlapping a shelter
## zone makes the astronaut interior even inside an exterior zone.
func _apply_zone_state() -> void:
	var inside: bool = not _shelter_areas.is_empty()
	var outside: bool = starts_outside or not _exterior_areas.is_empty()
	GameSim.set_outside(outside and not inside)


func _on_tick_advanced(_tick: int) -> void:
	vitals_changed.emit()


func _on_game_over(_cause: StringName) -> void:
	_alive = false
	velocity = Vector2.ZERO


func _on_game_reset() -> void:
	_alive = true
	_apply_suit()
	_input_locked = false
	_apply_zone_state()


func _apply_suit() -> void:
	GameSim.set_suit_level(int(suit))
	suit_changed.emit(int(suit))
