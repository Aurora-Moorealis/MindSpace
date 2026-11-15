class_name PowerNetwork
extends RefCounted

## One connected component of the power grid: the nodes joined by cables, the
## batteries that store its charge and the aggregate queries the tick needs.

const FALLBACK_CAPACITY: float = 10.0

var id: StringName = &""
var nodes: Array[StringName] = []
var batteries: Array[StringName] = []


## True when the network contains the given node.
func has_node(node_id: StringName) -> bool:
	return nodes.has(node_id)


## Batteries sorted by id so every tick visits them in the same order.
func sorted_batteries() -> Array[StringName]:
	var result: Array[StringName] = []
	for battery_id: StringName in batteries:
		result.append(battery_id)
	result.sort_custom(_id_before)
	return result


## Sum of the charge held by the network's batteries.
func total_charge(state: SimState) -> float:
	var total: float = 0.0
	for battery_id: StringName in batteries:
		total += state.get_battery_charge(battery_id)
	return total


## Sum of the capacity of the network's batteries.
func total_capacity(economy: EconomyData) -> float:
	var per_battery: float = economy.get_value(&"capacity_energy", FALLBACK_CAPACITY)
	return per_battery * float(batteries.size())


## True when at least one battery of the network still holds charge.
func has_charge(state: SimState) -> bool:
	for battery_id: StringName in batteries:
		if state.get_battery_charge(battery_id) > 0.0:
			return true
	return false


## True when the network feeds at least one machine other than the solar array.
## Used to avoid blackout noise in networks that only hold a battery or a panel.
func has_load(state: SimState) -> bool:
	for node_id: StringName in nodes:
		if node_id == SimState.MACHINE_SOLAR_ARRAY:
			continue
		if state.machines.has(node_id):
			return true
	return false


## Power the network must pay this tick: every operational machine in it.
func demand(state: SimState, economy: EconomyData) -> float:
	var total: float = 0.0
	for node_id: StringName in nodes:
		if not state.machines.has(node_id):
			continue
		var machine: MachineState = state.machines[node_id]
		if machine == null or not machine.powered or machine.is_broken():
			continue
		var row_id: StringName = StringName("power_" + String(node_id) + "_per_tick")
		total += economy.get_value(row_id, 0.0)
	return total


## Stores up to amount in the network's batteries, in id order.
## Returns the energy that did not fit.
func add_charge(state: SimState, economy: EconomyData, amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var remaining: float = amount
	var capacity: float = economy.get_value(&"capacity_energy", FALLBACK_CAPACITY)
	for battery_id: StringName in sorted_batteries():
		if remaining <= 0.0:
			break
		var current: float = state.get_battery_charge(battery_id)
		var room: float = maxf(0.0, capacity - current)
		var added: float = minf(room, remaining)
		state.set_battery_charge(battery_id, current + added)
		remaining -= added
	return remaining


## Pays up to amount from the network's batteries, in id order.
## Returns the part of the amount that could not be paid.
func spend_charge(state: SimState, amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var remaining: float = amount
	for battery_id: StringName in sorted_batteries():
		if remaining <= 0.0:
			break
		var current: float = state.get_battery_charge(battery_id)
		var paid: float = minf(current, remaining)
		state.set_battery_charge(battery_id, current - paid)
		remaining -= paid
	return remaining


## Deterministic ordering used by sort_custom.
static func _id_before(first: StringName, second: StringName) -> bool:
	return String(first) < String(second)
