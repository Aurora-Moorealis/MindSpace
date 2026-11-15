class_name Astronaut
extends CharacterBody2D

## Player avatar. Moves on four axes, shows the matching view of the sprite
## sheet, chooses the nearest interactable in range and reports the suit and the
## interior/exterior zone to GameSim. It never owns the survival rules: health,
## oxygen, hunger and thirst live in SimState and the tick updates them.

signal vitals_changed()
signal interaction_target_changed(target: Node)
signal suit_changed(level: int)

enum Suit { BASIC, SHIELDED }
enum Facing { FRONT, BACK, LEFT, RIGHT }

const FRAME_FRONT: int = 0
const FRAME_BACK: int = 1
const FRAME_LEFT: int = 2
const FRAME_RIGHT: int = 3

@export var move_speed: float = 120.0
@export var suit: Suit = Suit.BASIC
## Only used before the astronaut enters any exterior zone, for test scenes.
@export var starts_outside: bool = false

@onready var _sprite: Sprite2D = $Sprite
@onready var _interact_sensor: Area2D = $InteractSensor
@onready var _zone_sensor: Area2D = $ZoneSensor

var _facing: Facing = Facing.FRONT
var _targets: Array[Node] = []
var _current_target: Node = null
var _exterior_areas: Dictionary[Area2D, bool] = {}
var _alive: bool = true


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
	_update_facing()


func _physics_process(_delta: float) -> void:
	if not _alive:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var direction: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	velocity = direction * move_speed
	if direction.length_squared() > 0.0:
		_update_direction(direction)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not _alive:
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


## Marks the astronaut as outside; used by the zone and by test scenes.
func set_outside(value: bool) -> void:
	GameSim.set_outside(value)


func get_health() -> float:
	return GameSim.state.health


func get_oxygen() -> float:
	return GameSim.state.get_resource(SimState.OXYGEN)


func get_hunger() -> float:
	return GameSim.state.hunger


func get_thirst() -> float:
	return GameSim.state.thirst


func _update_direction(direction: Vector2) -> void:
	if absf(direction.x) >= absf(direction.y):
		_facing = Facing.RIGHT if direction.x > 0.0 else Facing.LEFT
	else:
		_facing = Facing.FRONT if direction.y > 0.0 else Facing.BACK
	_update_facing()


func _update_facing() -> void:
	match _facing:
		Facing.BACK:
			_sprite.frame = FRAME_BACK
		Facing.LEFT:
			_sprite.frame = FRAME_LEFT
		Facing.RIGHT:
			_sprite.frame = FRAME_RIGHT
		_:
			_sprite.frame = FRAME_FRONT


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
	if not area.is_in_group(&"exterior_zones"):
		return
	_exterior_areas[area] = true
	GameSim.set_outside(true)


func _on_zone_exited(area: Area2D) -> void:
	if not area.is_in_group(&"exterior_zones"):
		return
	_exterior_areas.erase(area)
	GameSim.set_outside(not _exterior_areas.is_empty())


func _on_tick_advanced(_tick: int) -> void:
	vitals_changed.emit()


func _on_game_over(_cause: StringName) -> void:
	_alive = false
	velocity = Vector2.ZERO


func _on_game_reset() -> void:
	_alive = true
	_apply_suit()
	GameSim.set_outside(starts_outside or not _exterior_areas.is_empty())


func _apply_suit() -> void:
	GameSim.set_suit_level(int(suit))
	suit_changed.emit(int(suit))
