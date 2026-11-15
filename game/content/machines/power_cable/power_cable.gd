class_name PowerCable
extends Node2D

## Visible cable between two power nodes. It paints an L-shaped route on its own
## TileMapLayer (grid of 32 px) and exposes the PowerLink the grid controller
## collects.
##
## The route does not avoid walls: the base is small and the designer places both
## nodes in the same room or in contiguous rooms.

const GROUP: StringName = &"power_cables"
const CONTROLLER_GROUP: StringName = &"power_controllers"
const ATLAS_COLUMNS: int = 4

## Widths in screen pixels of the short connector that links a port with the
## centre of its tile. They match the 6 px art thickness of the cable (12 px at
## the 2x presentation).
const STUB_OUTLINE_WIDTH: float = 12.0
const STUB_BODY_WIDTH: float = 8.0
const STUB_CORE_WIDTH: float = 4.0
const STUB_OUTLINE_COLOR: Color = Color("#0f171f")
const STUB_BODY_COLOR: Color = Color("#6a7684")
const STUB_CORE_COLOR: Color = Color("#2f9fa6")

@export var endpoint_a: NodePath
@export var endpoint_b: NodePath
## When true the cable runs horizontally first, then vertically.
@export var horizontal_first: bool = true

@onready var _cable_layer: TileMapLayer = $Cable

var _stubs: Array[Line2D] = []


func _ready() -> void:
	add_to_group(GROUP)
	_paint_route()
	_notify_grid_changed()


func _exit_tree() -> void:
	remove_from_group(GROUP)
	_notify_grid_changed()


## Link between the two endpoints, or null when one of them is not a power node.
func make_link() -> PowerLink:
	var node_a: MachineBase = _endpoint(endpoint_a)
	var node_b: MachineBase = _endpoint(endpoint_b)
	if node_a == null or node_b == null:
		return null
	var id_a: StringName = node_a.power_node_id()
	var id_b: StringName = node_b.power_node_id()
	if id_a == &"" or id_b == &"":
		return null
	return PowerLink.new(id_a, id_b)


## Paints the route again; used after moving a node in the editor or at runtime.
func repaint() -> void:
	_paint_route()
	_notify_grid_changed()


func _paint_route() -> void:
	_cable_layer.clear()
	_clear_stubs()
	var node_a: MachineBase = _endpoint(endpoint_a)
	var node_b: MachineBase = _endpoint(endpoint_b)
	if node_a == null or node_b == null:
		return

	var start: Vector2i = _cell_of(node_a.port_position())
	var finish: Vector2i = _cell_of(node_b.port_position())
	var cells: Dictionary[Vector2i, bool] = {}
	_collect_path(start, finish, cells)
	for cell: Vector2i in cells.keys():
		var mask: int = _mask_at(cell, cells)
		_cable_layer.set_cell(cell, 0, Vector2i(mask % ATLAS_COLUMNS, mask / ATLAS_COLUMNS))
	_add_stub(node_a.port_position(), _cell_center(start))
	_add_stub(node_b.port_position(), _cell_center(finish))


## Cells of the L route, including both ends.
func _collect_path(
	start: Vector2i,
	finish: Vector2i,
	cells: Dictionary[Vector2i, bool]
) -> void:
	var current: Vector2i = start
	cells[current] = true
	var horizontal_first_step: bool = horizontal_first
	if horizontal_first_step:
		while current.x != finish.x:
			current.x += signi(finish.x - current.x)
			cells[current] = true
		while current.y != finish.y:
			current.y += signi(finish.y - current.y)
			cells[current] = true
	else:
		while current.y != finish.y:
			current.y += signi(finish.y - current.y)
			cells[current] = true
		while current.x != finish.x:
			current.x += signi(finish.x - current.x)
			cells[current] = true


## Connection mask of one cell: N=1, E=2, S=4, W=8.
func _mask_at(cell: Vector2i, cells: Dictionary[Vector2i, bool]) -> int:
	var mask: int = 0
	if cells.has(cell + Vector2i.UP):
		mask += 1
	if cells.has(cell + Vector2i.RIGHT):
		mask += 2
	if cells.has(cell + Vector2i.DOWN):
		mask += 4
	if cells.has(cell + Vector2i.LEFT):
		mask += 8
	return mask


func _cell_of(world_position: Vector2) -> Vector2i:
	return _cable_layer.local_to_map(_cable_layer.to_local(world_position))


## World position of the centre of a tile, where the cable arms meet.
func _cell_center(cell: Vector2i) -> Vector2:
	return _cable_layer.to_global(_cable_layer.map_to_local(cell))


## Short line from a machine port to the centre of its tile, so the cable ends
## exactly on the connector whatever the machine's position is.
func _add_stub(from_world: Vector2, to_world: Vector2) -> void:
	if from_world.distance_to(to_world) < 0.5:
		return
	_add_stub_line(from_world, to_world, STUB_OUTLINE_WIDTH, STUB_OUTLINE_COLOR)
	_add_stub_line(from_world, to_world, STUB_BODY_WIDTH, STUB_BODY_COLOR)
	_add_stub_line(from_world, to_world, STUB_CORE_WIDTH, STUB_CORE_COLOR)


func _add_stub_line(
	from_world: Vector2,
	to_world: Vector2,
	width: float,
	color: Color
) -> void:
	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = color
	line.antialiased = false
	line.points = PackedVector2Array([to_local(from_world), to_local(to_world)])
	add_child(line)
	_stubs.append(line)


func _clear_stubs() -> void:
	for line: Line2D in _stubs:
		if is_instance_valid(line):
			line.queue_free()
	_stubs.clear()


## Tells every grid controller to rebuild its links after this cable appears,
## disappears or changes its endpoints.
func _notify_grid_changed() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	tree.call_group(CONTROLLER_GROUP, &"rebuild")


func _endpoint(path: NodePath) -> MachineBase:
	if path.is_empty():
		return null
	var node: Node = get_node_or_null(path)
	if node == null:
		return null
	return node as MachineBase
