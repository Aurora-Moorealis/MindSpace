class_name Battery
extends MachineBase

## Storage node of the power grid. The charge lives in SimState.batteries; this
## scene only mirrors it, so two batteries never share a number by accident.

@export var battery_id: StringName = &"battery_1"

var _meter: BatteryMeter = null
var _charge_mask: BatteryChargeMask = null


func _ready() -> void:
	GameSim.register_battery(battery_id)
	GameSim.game_reset.connect(_on_game_reset)
	machine_id = battery_id
	_meter = BatteryMeter.new()
	_meter.name = "ChargeMeter"
	_meter.position = Vector2(0.0, -62.0)
	add_child(_meter)
	_charge_mask = BatteryChargeMask.new()
	_charge_mask.name = "ChargeMask"
	add_child(_charge_mask)
	super._ready()


## A new run clears every extra battery; this scene puts itself back in the grid.
func _on_game_reset() -> void:
	GameSim.register_battery(battery_id)
	refresh_from_state()


func power_node_id() -> StringName:
	return battery_id


## A battery has no machine state: its visible state comes from its charge.
func refresh_from_state() -> void:
	var charge: float = GameSim.state.get_battery_charge(battery_id)
	var capacity: float = maxf(0.001, GameSim.state.battery_capacity)
	var ratio: float = clampf(charge / capacity, 0.0, 1.0)
	var tint: float = 0.55 + ratio * 0.45
	modulate = Color(tint, tint, tint, 1.0)
	if _meter != null:
		_meter.set_ratio(ratio)
	if _charge_mask != null:
		_charge_mask.set_ratio(ratio)
