class_name GrowthPanel
extends Control

## Full-rect wrapper of the greenhouse cultivation interface for the machine
## panel. The machine panel requires an extra screen with a Control root, hands
## it the station with [method setup] and hides its own frame until this panel
## reports [signal closed].
##
## The wrapper owns no cultivation state: the interface binds the station and the
## station keeps the cells. Closing with the button or with ui_cancel returns to
## the machine panel.

signal closed()

@onready var _interface: Node2D = $GrowthInterface

var _station: HydroponicsStation = null


func _ready() -> void:
	if not _interface.is_connected(&"closed", _on_interface_closed):
		_interface.connect(&"closed", _on_interface_closed)


## Binds the cultivation interface to the station that owns the state. The
## machine panel calls it right after adding this scene to the tree.
func setup(station: HydroponicsStation) -> void:
	_station = station
	if _interface.has_method(&"bind_station"):
		_interface.call(&"bind_station", station)
	if not _interface.is_connected(&"closed", _on_interface_closed):
		_interface.connect(&"closed", _on_interface_closed)


## Station shown by this panel, or null before setup.
func get_station() -> HydroponicsStation:
	return _station


## Closes the interface with the cancel action and forwards the left click to it.
## This runs on _input instead of only on _unhandled_input because the machine
## panel root is a Control that would eat the click (and its controller also
## listens to ui_cancel) before the interface sees it. Consuming the event here
## keeps the clicks on the interface and the machine panel open behind it.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_close_from_cancel()
		return
	if not (event is InputEventMouseButton):
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	# The interface may close itself (Back) and leave the tree, so the viewport
	# has to be captured before forwarding the click.
	var viewport: Viewport = get_viewport()
	_interface.call(&"_unhandled_input", click)
	if viewport != null:
		viewport.set_input_as_handled()


## Fallback for a dispatch without a preceding _input pass: closes the interface
## and consumes the event, so the machine panel stays open behind it.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	_close_from_cancel()


func _close_from_cancel() -> void:
	# The closed signal releases this node from the tree, so the viewport has to
	# be captured before emitting.
	var viewport: Viewport = get_viewport()
	closed.emit()
	if viewport != null:
		viewport.set_input_as_handled()


func _on_interface_closed() -> void:
	closed.emit()
