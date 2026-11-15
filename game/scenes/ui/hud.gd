class_name IngameHud
extends CanvasLayer

## In-game HUD: health bar on top, five-slot hotbar at the bottom.
##
## The HUD owns the run's inventory. Gameplay gets it with `get_inventory()` and
## adds items with `add_item()`. Clicks pick and place one item at a time; drag
## and drop swaps slots. The health bar mirrors GameSim on every tick.
##
## It also shows the interaction prompt of the bound astronaut and the time
## controls (pause and speed). The prompt visibility is evaluated every frame
## because the astronaut's input lock has no signal; the time controls are
## refreshed every frame because the clock can be paused without a tick.

const SLOT_COUNT: int = 5
const LOW_HEALTH_RATIO: float = 0.3
const HELD_ICON_SIZE: Vector2 = Vector2(24.0, 24.0)
const CAPACITY_FALLBACK: float = 10.0
const RADIATION_THRESHOLD_FALLBACK: float = 30.0
const RADIATION_WARNING_RATIO: float = 0.8
## Prompt text: the interact key plus the target name.
const PROMPT_FORMAT: String = "E  %s"
## Prompt text for targets that are not machines.
const INTERACT_FALLBACK: String = "Interact"

@export var low_health_fill: Texture2D = null

@onready var _health_fill: TextureProgressBar = %HealthFill
@onready var _slots_root: Control = %Slots
@onready var _held_icon: TextureRect = %HeldIcon
@onready var _oxygen_bar: TextureProgressBar = %OxygenBar
@onready var _water_bar: TextureProgressBar = %WaterBar
@onready var _food_bar: TextureProgressBar = %FoodBar
@onready var _energy_bar: TextureProgressBar = %EnergyBar
@onready var _oxygen_value: Label = %OxygenValue
@onready var _water_value: Label = %WaterValue
@onready var _food_value: Label = %FoodValue
@onready var _energy_value: Label = %EnergyValue
@onready var _clock_label: Label = %ClockLabel
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _prompt_panel: PanelContainer = %Prompt
@onready var _prompt_label: Label = %PromptLabel
@onready var _speed_down_button: Button = %SpeedDownButton
@onready var _speed_up_button: Button = %SpeedUpButton
@onready var _pause_button: Button = %PauseButton
@onready var _speed_value: Label = %SpeedValue

var inventory: Inventory = Inventory.new(SLOT_COUNT)

var _slots: Array[InventorySlot] = []
var _held_item: ItemData = null
var _normal_health_fill: Texture2D = null
var _clock_text: String = ""
var _radiation_alarm_played: bool = false
## Astronaut that publishes the interaction target, or null until bound.
var _astronaut: Astronaut = null
## Last interaction target received, kept so its name is only rebuilt on change.
var _interaction_target: Node = null
## True once the run ended, so the HUD stays hidden behind the summary.
var _run_over: bool = false
## True while a modal interface (a machine panel) covers the run.
var _overlay_open: bool = false


func _ready() -> void:
	_normal_health_fill = _health_fill.texture_progress
	_collect_slots()
	inventory.slot_changed.connect(_on_slot_changed)
	inventory.selection_changed.connect(_on_selection_changed)
	GameSim.tick_advanced.connect(_on_sim_tick_advanced)
	GameSim.game_reset.connect(_on_game_reset)
	GameSim.game_over.connect(_on_game_over)
	_speed_down_button.pressed.connect(_on_speed_down_pressed)
	_speed_up_button.pressed.connect(_on_speed_up_pressed)
	_pause_button.pressed.connect(_on_pause_pressed)
	_refresh_slots()
	_set_held_item(null)
	_refresh_stats()
	_refresh_time_controls()
	_refresh_prompt()


func _process(_delta: float) -> void:
	if _held_icon.visible:
		_held_icon.position = get_viewport().get_mouse_position() - HELD_ICON_SIZE * 0.5
	# The multiplier can change between ticks, so the clock is refreshed here too.
	_refresh_clock(GameSim.state, GameSim.get_economy())
	# The input lock and the pause flag change without a tick.
	_sync_prompt_visibility()
	_refresh_time_controls()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var focus: Control = get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		var digit_index: int = int(key_event.keycode) - int(KEY_1)
		if digit_index >= 0 and digit_index < inventory.get_slot_count():
			if inventory.select(digit_index):
				AudioManager.play(AudioManager.Sfx.UI_CLICK)
			get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_cycle_selection_with_sound(-1)
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_cycle_selection_with_sound(1)


func _cycle_selection_with_sound(step: int) -> void:
	var before: int = inventory.get_selected_index()
	inventory.cycle_selection(step)
	if inventory.get_selected_index() != before:
		AudioManager.play(AudioManager.Sfx.UI_CLICK)


## Time-control keys. The buttons have no focus, so Space reaches this handler.
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
	_astronaut = null
	_interaction_target = null
	if astronaut != null and is_instance_valid(astronaut):
		_astronaut = astronaut
		if not _astronaut.interaction_target_changed.is_connected(
			_on_interaction_target_changed
		):
			_astronaut.interaction_target_changed.connect(
				_on_interaction_target_changed
			)
		_interaction_target = _astronaut.get_interaction_target()
	_refresh_prompt()


## Inventory used by the run. Never null while the HUD is alive.
func get_inventory() -> Inventory:
	return inventory


## Adds an item to the first free slot and returns the index, or -1 when full.
func add_item(item: ItemData) -> int:
	return inventory.add_item(item)


## Re-reads every HUD value from the simulation. Gameplay calls it after changing
## the state outside a tick; the HUD already does it on ticks and reset.
func refresh_from_sim() -> void:
	_refresh_stats()


## Hides the HUD while another interface (a machine panel) covers the run, and
## brings it back when that interface closes.
func set_overlay_open(open: bool) -> void:
	_overlay_open = open
	_update_visibility()


## Updates the health bar. Values are clamped to the bar range.
func set_health(current: float, maximum: float) -> void:
	var safe_maximum: float = maxf(maximum, 0.001)
	var safe_current: float = clampf(current, 0.0, safe_maximum)
	_health_fill.max_value = safe_maximum
	_health_fill.value = safe_current
	var use_low_fill: bool = safe_current / safe_maximum <= LOW_HEALTH_RATIO
	if low_health_fill != null:
		_health_fill.texture_progress = low_health_fill if use_low_fill else _normal_health_fill


func _collect_slots() -> void:
	_slots.clear()
	for child: Node in _slots_root.get_children():
		if not child is InventorySlot:
			continue
		var slot: InventorySlot = child as InventorySlot
		slot.configure(_slots.size())
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_right_clicked.connect(_on_slot_right_clicked)
		slot.slot_dropped.connect(_on_slot_dropped)
		_slots.append(slot)


func _refresh_slots() -> void:
	for index: int in range(_slots.size()):
		_slots[index].set_item(inventory.get_item(index))
		_slots[index].set_selected(index == inventory.get_selected_index())


func _on_slot_changed(index: int, item: ItemData) -> void:
	if index < 0 or index >= _slots.size():
		return
	_slots[index].set_item(item)


func _on_selection_changed(index: int) -> void:
	for slot_index: int in range(_slots.size()):
		_slots[slot_index].set_selected(slot_index == index)


## Click with an empty hand picks the item up; click with a held item places it
## or swaps. A click on an empty slot with an empty hand only selects it.
func _on_slot_clicked(index: int) -> void:
	if _held_item == null:
		var taken: ItemData = inventory.take_item(index)
		if taken != null:
			AudioManager.play(AudioManager.Sfx.UI_CLICK)
			_set_held_item(taken)
		else:
			AudioManager.play(AudioManager.Sfx.UI_CLICK)
			inventory.select(index)
		return
	var replaced: ItemData = inventory.get_item(index)
	AudioManager.play(AudioManager.Sfx.UI_CLICK)
	inventory.set_item(index, _held_item)
	_set_held_item(replaced)
	inventory.select(index)


func _on_slot_right_clicked(_index: int) -> void:
	if _held_item == null:
		return
	AudioManager.play(AudioManager.Sfx.UI_CLICK)
	_cancel_held_item()


func _on_slot_dropped(from_index: int, to_index: int) -> void:
	if _held_item != null:
		return
	if inventory.move_item(from_index, to_index):
		AudioManager.play(AudioManager.Sfx.UI_CLICK)
		inventory.select(to_index)


func _set_held_item(item: ItemData) -> void:
	_held_item = item
	var has_icon: bool = item != null and item.icon != null
	_held_icon.texture = item.icon if item != null else null
	_held_icon.visible = has_icon


## Returns the held item to the first free slot. With no free slot it stays in
## the hand so it is never lost.
func _cancel_held_item() -> void:
	if _held_item == null:
		return
	var free_index: int = inventory.find_first_empty()
	if free_index < 0:
		return
	inventory.set_item(free_index, _held_item)
	_set_held_item(null)
	inventory.select(free_index)


func _on_sim_tick_advanced(_tick: int) -> void:
	_refresh_stats()
	_check_radiation_alarm()


## Warns once when the cumulative dose reaches the warning band below the cap.
func _check_radiation_alarm() -> void:
	if _radiation_alarm_played:
		return
	var threshold: float = GameSim.get_economy().get_value(
		&"radiation_threshold_cap", RADIATION_THRESHOLD_FALLBACK
	)
	if threshold <= 0.0:
		return
	if GameSim.state.radiation_dose < threshold * RADIATION_WARNING_RATIO:
		return
	_radiation_alarm_played = true
	AudioManager.play(AudioManager.Sfx.RADIATION_ALARM)


func _refresh_stats() -> void:
	var economy: EconomyData = GameSim.get_economy()
	var state: SimState = GameSim.state
	_refresh_health()
	_update_bar(
		_oxygen_bar, _oxygen_value,
		state.get_resource(SimState.OXYGEN),
		economy.get_value(&"capacity_oxygen", CAPACITY_FALLBACK)
	)
	_update_bar(
		_water_bar, _water_value,
		state.get_resource(SimState.WATER),
		economy.get_value(&"capacity_water", CAPACITY_FALLBACK)
	)
	_update_bar(
		_food_bar, _food_value,
		state.get_resource(SimState.FOOD),
		economy.get_value(&"capacity_food", CAPACITY_FALLBACK)
	)
	_update_bar(
		_energy_bar, _energy_value,
		state.get_energy_total(),
		economy.get_value(&"capacity_energy", CAPACITY_FALLBACK)
	)
	_refresh_clock(state, economy)
	_objective_label.text = UiText.mission_objective_label(
		state.mission_length_ticks,
		state.get_mission_ticks_left()
	)


func _update_bar(
	bar: TextureProgressBar,
	value_label: Label,
	value: float,
	capacity: float
) -> void:
	var safe_capacity: float = maxf(capacity, 0.001)
	var safe_value: float = clampf(value, 0.0, safe_capacity)
	bar.max_value = safe_capacity
	bar.value = safe_value
	value_label.text = "%d%%" % roundi(safe_value / safe_capacity * 100.0)


func _refresh_clock(state: SimState, economy: EconomyData) -> void:
	var text: String = _clock_text_for(state, economy)
	if text == _clock_text:
		return
	_clock_text = text
	_clock_label.text = text


func _clock_text_for(state: SimState, economy: EconomyData) -> String:
	var sol_length: int = maxi(state.get_sol_length(economy), 1)
	var sol_index: int = int(floor(float(state.tick) / float(sol_length))) + 1
	var hour: int = state.tick - (sol_index - 1) * sol_length
	var phase: String = "DAY" if state.get_phase(economy) == SimState.DayPhase.DAY else "NIGHT"
	return "SOL %d  %s  %02d:00  %s" % [sol_index, phase, hour, _speed_text()]


func _speed_text() -> String:
	match GameSim.speed:
		GameSim.Speed.X5:
			return "x5"
		GameSim.Speed.X10:
			return "x10"
		GameSim.Speed.X100:
			return "x100"
		GameSim.Speed.X1000:
			return "x1000"
		GameSim.Speed.X10000:
			return "x10000"
	return "x1"


## Mirrors the clock state in the time controls and locks them after game over.
func _refresh_time_controls() -> void:
	_speed_value.text = _speed_text()
	_pause_button.text = "Resume" if GameSim.paused else "Pause"
	var ended: bool = GameSim.state.game_over
	_speed_down_button.disabled = ended
	_speed_up_button.disabled = ended
	_pause_button.disabled = ended


## Moves the speed one step inside X1..X10000; a step past an end is ignored.
func _step_speed(step: int) -> void:
	if GameSim.state.game_over:
		return
	var changed: bool = false
	match GameSim.speed:
		GameSim.Speed.X1:
			if step > 0:
				GameSim.set_speed(GameSim.Speed.X5)
				changed = true
		GameSim.Speed.X5:
			if step > 0:
				GameSim.set_speed(GameSim.Speed.X10)
				changed = true
			elif step < 0:
				GameSim.set_speed(GameSim.Speed.X1)
				changed = true
		GameSim.Speed.X10:
			if step > 0:
				GameSim.set_speed(GameSim.Speed.X100)
				changed = true
			elif step < 0:
				GameSim.set_speed(GameSim.Speed.X5)
				changed = true
		GameSim.Speed.X100:
			if step > 0:
				GameSim.set_speed(GameSim.Speed.X1000)
				changed = true
			elif step < 0:
				GameSim.set_speed(GameSim.Speed.X10)
				changed = true
		GameSim.Speed.X1000:
			if step > 0:
				GameSim.set_speed(GameSim.Speed.X10000)
				changed = true
			elif step < 0:
				GameSim.set_speed(GameSim.Speed.X100)
				changed = true
		GameSim.Speed.X10000:
			if step < 0:
				GameSim.set_speed(GameSim.Speed.X1000)
				changed = true
	if changed:
		AudioManager.play(AudioManager.Sfx.UI_CLICK)
	_refresh_time_controls()
	_refresh_clock(GameSim.state, GameSim.get_economy())


func _toggle_pause() -> void:
	if GameSim.state.game_over:
		return
	GameSim.set_paused(not GameSim.paused)
	AudioManager.play(AudioManager.Sfx.UI_CLICK)
	_refresh_time_controls()


func _on_speed_down_pressed() -> void:
	_step_speed(-1)


func _on_speed_up_pressed() -> void:
	_step_speed(1)


func _on_pause_pressed() -> void:
	_toggle_pause()


func _on_interaction_target_changed(target: Node) -> void:
	_interaction_target = target
	_refresh_prompt()


## Rebuilds the prompt text from the current target and syncs its visibility.
## With no target the text is cleared so a stale name is never shown.
func _refresh_prompt() -> void:
	var text: String = ""
	if _has_target():
		text = PROMPT_FORMAT % _target_display_name()
	_prompt_label.text = text
	_sync_prompt_visibility()


## Shows the prompt only with a live target, a live run and unlocked input.
func _sync_prompt_visibility() -> void:
	var ready_to_show: bool = (
		_astronaut != null
		and is_instance_valid(_astronaut)
		and _has_target()
		and not GameSim.state.game_over
		and not _astronaut.is_input_locked()
	)
	_prompt_panel.visible = ready_to_show


func _has_target() -> bool:
	return _interaction_target != null and is_instance_valid(_interaction_target)


## Visible name of the target: the machine sheet when it has a machine id,
## otherwise the generic interaction text.
func _target_display_name() -> String:
	if not _has_target():
		return INTERACT_FALLBACK
	var raw_machine_id: Variant = _interaction_target.get(&"machine_id")
	if raw_machine_id is StringName:
		var machine_id: StringName = raw_machine_id
		if machine_id != &"":
			return UiText.display_name(GameSim.get_machine_data(machine_id))
	return INTERACT_FALLBACK


func _refresh_health() -> void:
	set_health(GameSim.get_health(), GameSim.get_max_health())


func _on_game_reset() -> void:
	_run_over = false
	_radiation_alarm_played = false
	_update_visibility()
	inventory.reset()
	_set_held_item(null)
	_refresh_slots()
	_refresh_stats()
	_refresh_time_controls()
	_refresh_prompt()


## Hides the layer so the mission summary is not covered by the HUD.
func _on_game_over(_cause: StringName) -> void:
	_run_over = true
	_update_visibility()


func _update_visibility() -> void:
	visible = not _run_over and not _overlay_open
