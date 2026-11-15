extends Node

## Opens the machine panel when a station is interacted with.
##
## Lives next to the panel inside the run UI layer. After one frame, once the
## outpost has added its stations to the "interactables" group, it connects the
## interaction_requested signal of every [MachineBase] and binds the station to
## the callable. While the panel is open the astronaut input is locked; closing
## with the panel control, with ui_cancel, at the end of the run or on a reset
## unlocks it again.

## Panel this controller drives; in the run UI it is a sibling node.
@export var panel_path: NodePath = ^"../MachinePanel"

var _panel: MachinePanel = null
var _astronaut: Astronaut = null
var _connected_stations: Array[MachineBase] = []


func _ready() -> void:
	_panel = get_node_or_null(panel_path) as MachinePanel
	if _panel == null:
		push_error(
			"MachinePanelController: no MachinePanel at '%s'." % String(panel_path)
		)
		return
	_panel.closed.connect(_on_panel_closed)
	GameSim.game_over.connect(_on_game_over)
	GameSim.game_reset.connect(_on_game_reset)
	# The outpost adds its stations to the interactables group after its own
	# deferred start, so the first scan waits for one frame.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_connect_interactables()


## Connects every station that is already in the interactables group.
func _connect_interactables() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"interactables"):
		var station: MachineBase = node as MachineBase
		if station == null:
			continue
		if _connected_stations.has(station):
			continue
		station.interaction_requested.connect(_on_interaction_requested.bind(station))
		_connected_stations.append(station)


## Opens the panel of the station the astronaut asked to interact with.
func _on_interaction_requested(astronaut: Node, station: MachineBase) -> void:
	if _panel == null or station == null:
		return
	if not GameSim.state.is_alive():
		return
	var player: Astronaut = astronaut as Astronaut
	if player == null or not player.is_alive():
		return
	_astronaut = player
	player.set_input_locked(true)
	_panel.open(station.machine_id, station)


## Closes the open panel; the panel reports it back through closed.
func _on_cancel_requested() -> void:
	if _panel == null or not _panel.is_open():
		return
	_panel.close()


func _on_panel_closed() -> void:
	_unlock_astronaut()


func _on_game_over(_cause: StringName) -> void:
	_close_panel()


func _on_game_reset() -> void:
	_close_panel()


## Closes the panel and gives the input back to the astronaut.
func _close_panel() -> void:
	if _panel != null and _panel.is_open():
		_panel.close()
	_unlock_astronaut()


func _unlock_astronaut() -> void:
	if _astronaut != null and is_instance_valid(_astronaut):
		_astronaut.set_input_locked(false)
	_astronaut = null


## Closes the open panel with the cancel action and consumes the event.
func _unhandled_input(event: InputEvent) -> void:
	if _panel == null or not _panel.is_open():
		return
	if not event.is_action_pressed(&"ui_cancel"):
		return
	_on_cancel_requested()
	get_viewport().set_input_as_handled()
