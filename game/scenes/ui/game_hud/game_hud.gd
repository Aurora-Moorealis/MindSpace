class_name GameHud
extends Control

## Read-only overlay of a running expedition: resources, vitals, clock, time
## controls, interaction prompt and event banners.
##
## Every value is read from [GameSim] and [SimState]; the [Astronaut] only
## supplies the interaction target. The speed and pause controls go through
## GameSim.set_speed()/set_paused() and never through get_tree().paused, so the
## HUD keeps refreshing while the simulation clock is frozen.

## Suffix appended to the interaction prompt.
const PROMPT_KEY: String = "[E]"
## Marker used when the state does not carry a resource the HUD must show.
const NO_VALUE: String = "--"
## Banner note for events without real provenance data.
const SIMULATED_EVENT: String = "Simulated event"
## Prompt text for targets that are not machines.
const INTERACT_FALLBACK: String = "Interact"

const TEXT_COLOR: Color = Color(0.87451, 0.909804, 0.941176, 1.0)
const DIM_TEXT_COLOR: Color = Color(0.62, 0.72, 0.76, 1.0)
const BANNER_BACKGROUND: Color = Color(0.058824, 0.090196, 0.121569, 0.78)
const BANNER_BORDER: Color = Color(0.290196, 0.658824, 0.705882, 0.55)
const BANNER_FONT_SIZE: int = 8

@onready var _energy_value: Label = %EnergyValue
@onready var _oxygen_value: Label = %OxygenValue
@onready var _water_value: Label = %WaterValue
@onready var _food_value: Label = %FoodValue
@onready var _health_value: Label = %HealthValue
@onready var _radiation_value: Label = %RadiationValue
@onready var _hunger_value: Label = %HungerValue
@onready var _thirst_value: Label = %ThirstValue
@onready var _clock_label: Label = %ClockLabel
@onready var _speed_label: Label = %SpeedValue
@onready var _speed_down_button: Button = %SpeedDownButton
@onready var _speed_up_button: Button = %SpeedUpButton
@onready var _pause_button: Button = %PauseButton
@onready var _comms_label: Label = %CommsLabel
@onready var _banners: VBoxContainer = %Banners
@onready var _prompt_panel: PanelContainer = %Prompt
@onready var _prompt_label: Label = %PromptLabel

## Astronaut that publishes the interaction target, or null until bound.
var _astronaut: Astronaut = null
## Last interaction target received, kept so the prompt can be re-evaluated.
var _target: Node = null
## Shared background of the runtime-created banner blocks.
var _banner_style: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	_banner_style = _make_banner_style()
	GameSim.tick_advanced.connect(_on_tick_advanced)
	GameSim.game_reset.connect(_on_game_reset)
	GameSim.game_over.connect(_on_game_over)
	_speed_down_button.pressed.connect(_on_speed_down_pressed)
	_speed_up_button.pressed.connect(_on_speed_up_pressed)
	_pause_button.pressed.connect(_on_pause_pressed)
	refresh()


## Switches the astronaut that supplies the interaction prompt. A null argument
## detaches the current one and hides the prompt.
func bind_astronaut(astronaut: Astronaut) -> void:
	if _astronaut != null and is_instance_valid(_astronaut):
		if _astronaut.interaction_target_changed.is_connected(
			_on_interaction_target_changed
		):
			_astronaut.interaction_target_changed.disconnect(
				_on_interaction_target_changed
			)
	_astronaut = astronaut
	if _astronaut == null or not is_instance_valid(_astronaut):
		_astronaut = null
		_target = null
		_refresh_prompt()
		return
	if not _astronaut.interaction_target_changed.is_connected(
		_on_interaction_target_changed
	):
		_astronaut.interaction_target_changed.connect(_on_interaction_target_changed)
	_target = _astronaut.get_interaction_target()
	_refresh_prompt()


## Rewrites every label from the current simulation state.
func refresh() -> void:
	_refresh_resources()
	_refresh_clock()
	_refresh_time_controls()
	_refresh_banners()
	_refresh_comms()
	_refresh_prompt()


## The prompt also depends on the input lock, which has no signal, so its
## visibility is re-evaluated every frame. The text is only rebuilt on events.
func _process(_delta: float) -> void:
	_sync_prompt_visibility()


func _unhandled_input(event: InputEvent) -> void:
	if GameSim.state.game_over:
		return
	if event.is_action_pressed(&"speed_up"):
		_step_speed(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"speed_down"):
		_step_speed(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _on_tick_advanced(_tick: int) -> void:
	refresh()


func _on_game_reset() -> void:
	refresh()


func _on_game_over(_cause: StringName) -> void:
	refresh()


func _on_interaction_target_changed(target: Node) -> void:
	_target = target
	_refresh_prompt()


func _on_speed_down_pressed() -> void:
	_step_speed(-1)


func _on_speed_up_pressed() -> void:
	_step_speed(1)


func _on_pause_pressed() -> void:
	_toggle_pause()


## Moves the speed one step inside X1..X10; a step past an end is ignored.
func _step_speed(step: int) -> void:
	if GameSim.state.game_over:
		return
	match GameSim.speed:
		GameSim.Speed.X1:
			if step > 0:
				GameSim.set_speed(GameSim.Speed.X5)
		GameSim.Speed.X5:
			if step > 0:
				GameSim.set_speed(GameSim.Speed.X10)
			elif step < 0:
				GameSim.set_speed(GameSim.Speed.X1)
		GameSim.Speed.X10:
			if step < 0:
				GameSim.set_speed(GameSim.Speed.X5)
	_refresh_time_controls()


func _toggle_pause() -> void:
	if GameSim.state.game_over:
		return
	GameSim.set_paused(not GameSim.paused)
	_refresh_time_controls()


func _refresh_resources() -> void:
	var state: SimState = GameSim.state
	_set_resource_value(_energy_value, SimState.ENERGY, state)
	_set_resource_value(_oxygen_value, SimState.OXYGEN, state)
	_set_resource_value(_water_value, SimState.WATER, state)
	_set_resource_value(_food_value, SimState.FOOD, state)
	_health_value.text = "%d / %d" % [
		int(round(state.health)), int(round(state.max_health))
	]
	_radiation_value.text = "%.1f" % state.radiation_dose
	_hunger_value.text = "%.1f" % state.hunger
	_thirst_value.text = "%.1f" % state.thirst


## One resource row: a missing entry is reported as unavailable, not as zero.
func _set_resource_value(label: Label, id: StringName, state: SimState) -> void:
	if not state.resources.has(id):
		label.text = NO_VALUE
		return
	label.text = "%.1f" % state.get_resource(id)


func _refresh_clock() -> void:
	var state: SimState = GameSim.state
	var economy: EconomyData = GameSim.get_economy()
	var sol_length: int = state.get_sol_length(economy)
	var sol: int = int(floor(float(state.tick) / float(sol_length))) + 1
	var phase: String = "Night"
	if state.get_phase(economy) == SimState.DayPhase.DAY:
		phase = "Day"
	_clock_label.text = "Sol %d - %s - tick %d" % [sol, phase, state.tick]


func _refresh_time_controls() -> void:
	_speed_label.text = _speed_text()
	_pause_button.text = "Resume" if GameSim.paused else "Pause"
	var ended: bool = GameSim.state.game_over
	_speed_down_button.disabled = ended
	_speed_up_button.disabled = ended
	_pause_button.disabled = ended


func _speed_text() -> String:
	match GameSim.speed:
		GameSim.Speed.X5:
			return "x5"
		GameSim.Speed.X10:
			return "x10"
	return "x1"


## Rebuilds one banner block per active event: archetype and current intensity,
## then the provenance of the row.
func _refresh_banners() -> void:
	for child: Node in _banners.get_children():
		_banners.remove_child(child)
		child.queue_free()
	var state: SimState = GameSim.state
	for active: ActiveEvent in state.active_events:
		if active == null or active.row == null:
			continue
		_banners.add_child(_build_banner(active, state.tick))


func _build_banner(active: ActiveEvent, tick: int) -> PanelContainer:
	var elapsed: int = maxi(0, tick - active.started_tick)
	var intensity: float = active.row.intensity_at(elapsed)
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(&"panel", _banner_style)
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 0)
	panel.add_child(column)
	column.add_child(
		_make_banner_label(
			"%s %.2f" % [UiText.archetype_label(active.row.archetype), intensity],
			TEXT_COLOR
		)
	)
	column.add_child(
		_make_banner_label(_provenance_line(active.row.provenance), DIM_TEXT_COLOR)
	)
	return panel


## Second banner line: the real source and its date, or the simulated note.
func _provenance_line(provenance: DataProvenance) -> String:
	if provenance == null or not provenance.real_data:
		return SIMULATED_EVENT
	return "Source: %s (%s)" % [provenance.source, provenance.date_archived]


func _make_banner_label(text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", BANNER_FONT_SIZE)
	label.add_theme_color_override(&"font_color", color)
	return label


func _make_banner_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = BANNER_BACKGROUND
	style.border_color = BANNER_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(4.0)
	return style


func _refresh_comms() -> void:
	_comms_label.visible = GameSim.state.comms_blocked


func _refresh_prompt() -> void:
	if not _has_target():
		_prompt_label.text = ""
	else:
		_prompt_label.text = "%s  %s" % [_target_display_name(), PROMPT_KEY]
	_sync_prompt_visibility()


## Shows the prompt only with a live target, a live run and unlocked input.
func _sync_prompt_visibility() -> void:
	_prompt_panel.visible = _has_target() and not _is_prompt_blocked()


func _has_target() -> bool:
	return _target != null and is_instance_valid(_target)


func _is_prompt_blocked() -> bool:
	if GameSim.state.game_over:
		return true
	if _astronaut != null and is_instance_valid(_astronaut):
		return _astronaut.is_input_locked()
	return false


## Visible name of the target: the machine sheet when it has a machine id,
## otherwise the generic interaction text.
func _target_display_name() -> String:
	if not _has_target():
		return INTERACT_FALLBACK
	var raw_machine_id: Variant = _target.get(&"machine_id")
	if raw_machine_id is StringName:
		var machine_id: StringName = raw_machine_id
		if machine_id != &"":
			return UiText.display_name(GameSim.get_machine_data(machine_id))
	return INTERACT_FALLBACK
