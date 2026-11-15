class_name MachinePanel
extends Control

## Modal panel of one habitat machine.
##
## The scene only fixes the layout; every value comes from [GameSim] on each
## refresh, so the panel never keeps a second copy of the machine state. Repair
## and upgrade buttons ask [GameSim] whether the action is allowed and show the
## reason from [UiText] when it is not. Opening the panel never pauses the clock:
## the [member GameSim.tick_advanced] signal keeps refreshing it.
##
## A station may declare an extra panel (the hydroponics cultivation grid) with
## get_extra_panel_scene(). That scene replaces the main frame until it emits
## closed, and is released afterwards.

signal closed()

@onready var _frame: PanelContainer = %Frame
@onready var _name_label: Label = %NameLabel
@onready var _hint_label: Label = %HintLabel
@onready var _health_value: Label = %HealthValue
@onready var _status_value: Label = %StatusValue
@onready var _upgrade_value: Label = %UpgradeValue
@onready var _close_button: Button = %CloseButton
@onready var _repair_cost_label: Label = %RepairCostLabel
@onready var _repair_progress: ProgressBar = %RepairProgress
@onready var _repair_button: Button = %RepairButton
@onready var _repair_reason: Label = %RepairReason
@onready var _upgrades_title: Label = %UpgradesTitle
@onready var _upgrades_scroll: ScrollContainer = %UpgradesScroll
@onready var _upgrades_list: VBoxContainer = %UpgradesList
@onready var _no_upgrades_label: Label = %NoUpgradesLabel
@onready var _extra_button: Button = %ExtraButton

const NO_UPGRADES_TEXT: String = "No upgrades available for this machine."
const EXTRA_BUTTON_TEXT: String = "Open panel"

## Machine shown by the panel; empty while it is closed.
var _machine_id: StringName = &""
## Station node that requested the panel, used to ask for its extra scene.
var _station: Node = null
## Extra panel instance while it is on screen, null otherwise.
var _extra: Control = null
## Extra panel scene declared by the station, resolved once per open.
var _extra_scene: PackedScene = null

var _upgrade_buttons: Dictionary[StringName, Button] = {}
var _upgrade_reasons: Dictionary[StringName, Label] = {}
## Disabled look of the static buttons, reused by the rows built at run time so
## both kinds of button stay consistent without a second copy of the style.
var _disabled_button_style: StyleBox = null
var _disabled_font_color: Color = Color(0.619608, 0.698039, 0.784314, 1.0)


func _ready() -> void:
	visible = false
	_frame.visible = true
	_close_button.pressed.connect(_on_close_pressed)
	_repair_button.pressed.connect(_on_repair_pressed)
	_extra_button.pressed.connect(_on_extra_pressed)
	GameSim.tick_advanced.connect(_on_tick_advanced)
	_disabled_button_style = _repair_button.get_theme_stylebox(&"disabled")
	_disabled_font_color = _repair_button.get_theme_color(&"font_disabled_color")
	_extra_button.text = EXTRA_BUTTON_TEXT
	_no_upgrades_label.visible = false
	_extra_button.visible = false
	_repair_progress.visible = false
	_repair_reason.visible = false


## Shows the panel of [param machine_id], hosted at [param station].
func open(machine_id: StringName, station: Node) -> void:
	_release_extra()
	_frame.visible = true
	_machine_id = machine_id
	_station = station
	_extra_scene = _resolve_extra_scene()
	visible = true
	_rebuild_upgrades()
	_refresh()


## Hides the panel and reports that it no longer owns the input. Closing an
## already closed panel does nothing, so a second close cannot unlock input that
## another system owns.
func close() -> void:
	if not visible:
		return
	_release_extra()
	visible = false
	_machine_id = &""
	_station = null
	_extra_scene = null
	closed.emit()


func is_open() -> bool:
	return visible


## Refreshes the shown values on every simulation tick while the panel is open.
func _on_tick_advanced(_tick: int) -> void:
	if visible:
		_refresh()


## Rebuilds every value from the current run state.
func _refresh() -> void:
	if not visible:
		return
	var data: MachineData = GameSim.get_machine_data(_machine_id)
	var machine: MachineState = GameSim.get_machine_state(_machine_id)
	var energy: float = GameSim.state.get_resource(SimState.ENERGY)
	var run_ended: bool = GameSim.state.game_over

	_name_label.text = UiText.display_name(data)
	_hint_label.text = data.hint_text if data != null else ""
	_hint_label.visible = not _hint_label.text.is_empty()

	if machine == null:
		_health_value.text = "-- / --"
		_status_value.text = "Unavailable"
		_upgrade_value.text = "--"
	else:
		_health_value.text = "%.1f / %.1f" % [
			machine.health, MachineState.MAX_HEALTH
		]
		_status_value.text = _status_text(machine)
		_upgrade_value.text = str(machine.upgrade_level)

	_refresh_repair(data, machine, energy, run_ended)
	_refresh_upgrades(data, machine, energy, run_ended)
	_refresh_extra()


## Status word of the machine, most severe state first.
func _status_text(machine: MachineState) -> String:
	if machine.is_broken():
		return "Broken"
	if machine.is_repairing():
		return "Under repair"
	if not machine.powered:
		return "Unpowered"
	return "Running"


## Updates the repair cost, the progress bar, the button and its reason.
func _refresh_repair(
	data: MachineData, machine: MachineState, energy: float, run_ended: bool
) -> void:
	_repair_cost_label.visible = data != null
	if data != null:
		_repair_cost_label.text = "Repair cost: %.2f energy" % maxf(0.0, data.repair_energy_cost)

	var repairing: bool = GameSim.is_repairing(_machine_id)
	_repair_progress.visible = repairing
	if repairing:
		_repair_progress.value = GameSim.repair_progress(_machine_id)

	_repair_button.disabled = not GameSim.can_start_repair(_machine_id)
	var reason: String = UiText.repair_block_reason(data, machine, energy, run_ended)
	_repair_reason.text = reason
	_repair_reason.visible = not reason.is_empty()


## Updates every upgrade row against the current state.
func _refresh_upgrades(
	data: MachineData, machine: MachineState, energy: float, run_ended: bool
) -> void:
	for upgrade_id: StringName in _upgrade_buttons:
		var button: Button = _upgrade_buttons[upgrade_id]
		var reason_label: Label = _upgrade_reasons[upgrade_id]
		var upgrade: UpgradeData = data.get_upgrade(upgrade_id) if data != null else null
		var applied: bool = machine != null and machine.applied_upgrades.has(upgrade_id)
		button.disabled = not GameSim.can_apply_upgrade(_machine_id, upgrade_id)
		button.text = "Applied" if applied else "Apply"
		var reason: String = UiText.upgrade_block_reason(
			data, machine, upgrade, energy, run_ended
		)
		reason_label.text = reason
		reason_label.visible = not reason.is_empty()


## Frees the previous rows and builds one row per upgrade the machine expresses.
func _rebuild_upgrades() -> void:
	for child: Node in _upgrades_list.get_children():
		_upgrades_list.remove_child(child)
		child.queue_free()
	_upgrade_buttons.clear()
	_upgrade_reasons.clear()

	var data: MachineData = GameSim.get_machine_data(_machine_id)
	_upgrades_title.visible = data != null
	if data == null:
		_upgrades_scroll.visible = false
		_no_upgrades_label.text = UiText.MISSING_MACHINE_DATA
		_no_upgrades_label.visible = true
		return

	var built: int = 0
	for upgrade: UpgradeData in data.upgrades:
		if upgrade == null:
			continue
		if not data.supports_effect(upgrade.effect_stat):
			continue
		_add_upgrade_row(upgrade)
		built += 1

	_upgrades_scroll.visible = built > 0
	_no_upgrades_label.text = NO_UPGRADES_TEXT
	_no_upgrades_label.visible = built == 0


## Adds the row of one upgrade: effect and cost, the apply button and its reason.
func _add_upgrade_row(upgrade: UpgradeData) -> void:
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override(&"separation", 2)

	var line: HBoxContainer = HBoxContainer.new()
	line.add_theme_constant_override(&"separation", 8)

	var effect_label: Label = Label.new()
	effect_label.text = UiText.effect_label(upgrade.effect_stat, upgrade.delta)
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var cost_label: Label = Label.new()
	cost_label.text = "%.2f energy" % maxf(0.0, upgrade.energy_cost)
	cost_label.custom_minimum_size = Vector2(88.0, 0.0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var button: Button = Button.new()
	button.text = "Apply"
	button.custom_minimum_size = Vector2(84.0, 0.0)
	button.focus_mode = Control.FOCUS_NONE
	if _disabled_button_style != null:
		button.add_theme_stylebox_override(&"disabled", _disabled_button_style)
	button.add_theme_color_override(&"font_disabled_color", _disabled_font_color)
	button.pressed.connect(_on_upgrade_pressed.bind(upgrade.id))

	line.add_child(effect_label)
	line.add_child(cost_label)
	line.add_child(button)

	var reason_label: Label = Label.new()
	reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason_label.add_theme_color_override(&"font_color", Color(1.0, 0.72, 0.35))
	reason_label.visible = false

	row.add_child(line)
	row.add_child(reason_label)
	_upgrades_list.add_child(row)

	_upgrade_buttons[upgrade.id] = button
	_upgrade_reasons[upgrade.id] = reason_label


## Shows the extra button when the station declares an extra panel scene.
func _refresh_extra() -> void:
	_extra_button.visible = _extra == null and _extra_scene != null


## Extra panel scene declared by the station, or null when it has none.
func _resolve_extra_scene() -> PackedScene:
	if _station == null or not is_instance_valid(_station):
		return null
	if not _station.has_method(&"get_extra_panel_scene"):
		return null
	var declared: Variant = _station.call(&"get_extra_panel_scene")
	if declared is PackedScene:
		return declared as PackedScene
	return null


func _on_close_pressed() -> void:
	close()


func _on_repair_pressed() -> void:
	GameSim.start_repair(_machine_id)
	_refresh()


func _on_upgrade_pressed(upgrade_id: StringName) -> void:
	GameSim.apply_upgrade(_machine_id, upgrade_id)
	_refresh()


## Opens the extra panel over the frame, giving it the station and the close
## signal the main panel needs to come back.
func _on_extra_pressed() -> void:
	if _extra != null:
		return
	var scene: PackedScene = _extra_scene
	if scene == null:
		return
	var instance: Node = scene.instantiate()
	var extra: Control = instance as Control
	if extra == null:
		push_error("MachinePanel: extra panel scene root is not a Control.")
		instance.queue_free()
		return
	_extra = extra
	add_child(_extra)
	_extra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _extra.has_method(&"setup"):
		_extra.call(&"setup", _station)
	if _extra.has_signal(&"closed"):
		_extra.connect(&"closed", _on_extra_closed)
	_frame.visible = false
	_extra_button.visible = false


func _on_extra_closed() -> void:
	_release_extra()
	_frame.visible = true
	_refresh()


## Frees the extra panel, if any, and disconnects it so releasing cannot bounce
## back into this panel.
func _release_extra() -> void:
	if _extra == null:
		return
	var extra: Control = _extra
	_extra = null
	if not is_instance_valid(extra):
		return
	if extra.has_signal(&"closed") and extra.is_connected(&"closed", _on_extra_closed):
		extra.disconnect(&"closed", _on_extra_closed)
	if extra.get_parent() != null:
		extra.get_parent().remove_child(extra)
	extra.queue_free()
