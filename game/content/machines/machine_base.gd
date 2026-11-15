class_name MachineBase
extends Node2D

## Shared base for the power machines that exist in the world (solar array and
## battery). It exposes the node identity the cables need, mirrors the run state
## on the sprite and keeps the port position used to draw the cable route.

const MACHINE_LAYER: int = 4
const INTERACT_SIZE: Vector2 = Vector2(150, 110)

signal interaction_requested(astronaut: Node)

@export var machine_id: StringName = &""
@export var port_offset: Vector2 = Vector2.ZERO

var _label: Label = null


func _ready() -> void:
	_ensure_interaction_area()
	GameSim.tick_advanced.connect(_on_tick_advanced)
	GameSim.game_reset.connect(refresh_from_state)
	refresh_from_state()


## What pressing interact does on this machine. The interaction panel is a later
## change; for now the machine publishes the request so any UI can listen.
func interact(astronaut: Node) -> void:
	interaction_requested.emit(astronaut)


## Identifier this node uses in the power grid. Cables read it through the base.
func power_node_id() -> StringName:
	return machine_id


## World position of the plug, where a cable must reach to connect.
func port_position() -> Vector2:
	return global_position + port_offset


## Machine state of this node, or null when the run does not model it.
func machine_state() -> MachineState:
	if not GameSim.state.machines.has(machine_id):
		return null
	return GameSim.state.machines[machine_id]


## Reflects the machine state on the sprite: broken machines turn red and
## unpowered machines turn grey. Subclasses can extend it.
func refresh_from_state() -> void:
	var machine: MachineState = machine_state()
	if machine == null:
		return
	if machine.is_broken():
		modulate = Color(1.0, 0.52, 0.52, 1.0)
	elif not machine.powered:
		modulate = Color(0.55, 0.58, 0.64, 1.0)
	else:
		modulate = Color.WHITE


func _on_tick_advanced(_tick: int) -> void:
	refresh_from_state()


## Creates the area the astronaut sensor uses to find this machine. It lives on
## the interaction layer so only the astronaut's sensor sees it.
func _ensure_interaction_area() -> void:
	add_to_group(&"interactables")
	var area: Area2D = Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = MACHINE_LAYER
	area.collision_mask = 0
	area.monitoring = false
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = INTERACT_SIZE
	shape.shape = rectangle
	area.add_child(shape)
	add_child(area)
