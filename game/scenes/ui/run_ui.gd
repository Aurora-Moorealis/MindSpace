extends CanvasLayer

## UI layer of a playable run: HUD, machine panel and mission evaluation.
##
## The layer only composes and wires its children: the HUD reads the simulation,
## the panel drives the machines and the evaluation presents the summary. This
## script owns the transitions around them (end of the run, restart, back to
## the menu) and the debug control that forces the run to end.

## Astronaut of the playable scene that feeds the HUD interaction prompt.
@export var astronaut_path: NodePath = ^"../Astronaut"

@onready var _hud: GameHud = $GameHud
@onready var _debug_button: Button = $DebugEndButton
## Typed as Control because evaluation.gd declares no class_name; its public
## API (present/hide_summary) and its signals are resolved at runtime.
@onready var _evaluation: Control = $Evaluation


func _ready() -> void:
	var astronaut: Astronaut = get_node_or_null(astronaut_path) as Astronaut
	if astronaut == null:
		push_error("RunUi: no Astronaut at '%s'." % String(astronaut_path))
	_hud.bind_astronaut(astronaut)
	GameSim.game_over.connect(_on_game_over)
	GameSim.game_reset.connect(_on_game_reset)
	_evaluation.restart_requested.connect(_on_restart_requested)
	_evaluation.menu_requested.connect(_on_menu_requested)
	# The forced end of the run is a developer tool: it stays hidden outside
	# debug builds and never takes focus from the game.
	_debug_button.visible = OS.is_debug_build()
	_debug_button.pressed.connect(GameSim.force_end_run)


## Shows the mission summary over the frozen scene.
func _on_game_over(_cause: StringName) -> void:
	_evaluation.present()


## Hides the summary so a fresh run starts on the playable scene.
func _on_game_reset() -> void:
	_evaluation.hide_summary()


## Starts a clean run and rebuilds the playable scene from scratch.
func _on_restart_requested() -> void:
	GameSim.new_game()
	get_tree().reload_current_scene()


## Leaves the run and returns to the main menu.
func _on_menu_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/welcome/welcome.tscn")


## Ends the run with the debug action, exactly like the debug button.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not event.is_action_pressed(&"debug_end_run"):
		return
	GameSim.force_end_run()
	get_viewport().set_input_as_handled()
