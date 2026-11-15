class_name IngameHud
extends CanvasLayer

## In-game HUD: health bar on top, five-slot hotbar at the bottom.
##
## The HUD owns the run's inventory. Gameplay gets it with `get_inventory()` and
## adds items with `add_item()`. Clicks pick and place one item at a time; drag
## and drop swaps slots. The health bar mirrors GameSim on every tick.

const SLOT_COUNT: int = 5
const LOW_HEALTH_RATIO: float = 0.3
const HELD_ICON_SIZE: Vector2 = Vector2(24.0, 24.0)
const CAPACITY_FALLBACK: float = 10.0

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

var inventory: Inventory = Inventory.new(SLOT_COUNT)

var _slots: Array[InventorySlot] = []
var _held_item: ItemData = null
var _normal_health_fill: Texture2D = null
var _clock_text: String = ""


func _ready() -> void:
	_normal_health_fill = _health_fill.texture_progress
	_collect_slots()
	inventory.slot_changed.connect(_on_slot_changed)
	inventory.selection_changed.connect(_on_selection_changed)
	GameSim.tick_advanced.connect(_on_sim_tick_advanced)
	GameSim.game_reset.connect(_on_game_reset)
	GameSim.game_over.connect(_on_game_over)
	_refresh_slots()
	_set_held_item(null)
	_refresh_stats()


func _process(_delta: float) -> void:
	if _held_icon.visible:
		_held_icon.position = get_viewport().get_mouse_position() - HELD_ICON_SIZE * 0.5
	# The multiplier can change between ticks, so the clock is refreshed here too.
	_refresh_clock(GameSim.state, GameSim.get_economy())


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
			inventory.select(digit_index)
			get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		inventory.cycle_selection(-1)
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		inventory.cycle_selection(1)


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
			_set_held_item(taken)
		else:
			inventory.select(index)
		return
	var replaced: ItemData = inventory.get_item(index)
	inventory.set_item(index, _held_item)
	_set_held_item(replaced)
	inventory.select(index)


func _on_slot_right_clicked(_index: int) -> void:
	_cancel_held_item()


func _on_slot_dropped(from_index: int, to_index: int) -> void:
	if _held_item != null:
		return
	if inventory.move_item(from_index, to_index):
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
	match int(GameSim.speed):
		1:
			return "x5"
		2:
			return "x10"
		_:
			return "x1"


func _refresh_health() -> void:
	set_health(GameSim.get_health(), GameSim.get_max_health())


func _on_game_reset() -> void:
	visible = true
	inventory.reset()
	_set_held_item(null)
	_refresh_slots()
	_refresh_stats()


## Hides the layer so the mission summary is not covered by the HUD.
func _on_game_over(_cause: StringName) -> void:
	visible = false
