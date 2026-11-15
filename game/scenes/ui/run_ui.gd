extends CanvasLayer

## UI layer of a playable run: HUD, machine panel and mission evaluation.
##
## The layer only composes and wires its children: the HUD reads the simulation,
## the panel drives the machines and the evaluation presents the summary. This
## script owns the transitions around them (end of the run, restart, back to
## the menu) and the debug control that forces the run to end.

@onready var _hud: IngameHud = $Hud
@onready var _panel: MachinePanel = $MachinePanel
@onready var _debug_button: Button = $DebugEndButton
## Typed as Control because evaluation.gd declares no class_name; its public
## API (present/hide_summary) and its signals are resolved at runtime.
@onready var _evaluation: Control = $Evaluation


func _ready() -> void:
	GameSim.game_over.connect(_on_game_over)
	GameSim.game_reset.connect(_on_game_reset)
	_panel.visibility_changed.connect(_on_panel_visibility_changed)
	_evaluation.restart_requested.connect(_on_restart_requested)
	_evaluation.menu_requested.connect(_on_menu_requested)
	# The forced end of the run is a developer tool: it stays hidden outside
	# debug builds and never takes focus from the game.
	_debug_button.visible = OS.is_debug_build()
	_debug_button.pressed.connect(GameSim.force_end_run)


## Shows the mission summary over the frozen scene.
func _on_game_over(_cause: StringName) -> void:
	_evaluation.present()


## The machine panel is modal: while it is open the HUD steps aside so nothing
## overlaps the panel or its buttons.
func _on_panel_visibility_changed() -> void:
	_hud.set_overlay_open(_panel.visible)
	_debug_button.visible = OS.is_debug_build() and not _panel.visible


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
