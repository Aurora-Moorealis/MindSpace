class_name SimTick
extends RefCounted

## Deterministic advance of one simulation tick (contract v1.1).
## No randomness and no real time: same state plus same economy, same result.
## The step order is fixed: production, consumption, degradation, events
## (currently a no-op), consequences, death and calendar facts.

const _FALLBACK_CAPACITY: float = 10.0
const _FALLBACK_MAX_HEALTH: float = 100.0
const _FALLBACK_RADIATION_CAP: float = 30.0
const _FALLBACK_RADIATION_DEATH: float = 100.0
const _FALLBACK_SOLAR_OUTPUT: float = 1.5
const _FALLBACK_BLACKOUT_STEPS: float = 1.0
const _FALLBACK_SUIT_MULTIPLIER: float = 1.0


## Advances p_state one tick and returns the facts emitted by that tick.
static func step(state: SimState, economy: EconomyData) -> Array[LogEntry]:
	var facts: Array[LogEntry] = []
	# A finished run keeps counting ticks but emits nothing else.
	if state.game_over:
		state.tick += 1
		return facts

	var networks: Array[PowerNetwork] = PowerGrid.build(state)
	_apply_production(state, economy, networks)
	_apply_consumption(state, economy, networks)
	state.sync_energy_resource()
	_apply_degradation(state, economy, facts)
	# Events: no-op in this version.
	var radiation_damage_applied: bool = _apply_consequences(state, economy, networks, facts)
	_apply_death(state, economy, facts, radiation_damage_applied)
	_apply_sol_facts(state, economy, facts)
	state.tick += 1
	return facts


## Step 2: machines that are powered and healthy produce during the day.
static func _apply_production(
	state: SimState,
	economy: EconomyData,
	networks: Array[PowerNetwork]
) -> void:
	var is_day: bool = state.get_phase(economy) == SimState.DayPhase.DAY
	if is_day and _is_operational(_machine(state, SimState.MACHINE_SOLAR_ARRAY)):
		var solar_output: float = economy.get_value(&"solar_output_per_tick", _FALLBACK_SOLAR_OUTPUT)
		for network: PowerNetwork in networks:
			if network.has_node(SimState.MACHINE_SOLAR_ARRAY):
				network.add_charge(state, economy, solar_output)
	if _is_operational(_machine(state, SimState.MACHINE_HYDROPONICS)):
		_add_resource(
			state,
			SimState.FOOD,
			economy.get_value(&"hydroponics_food_output_per_tick", 0.0),
			economy
		)
		_add_resource(
			state,
			SimState.OXYGEN,
			economy.get_value(&"hydroponics_oxygen_output_per_tick", 0.0),
			economy
		)
	if _is_operational(_machine(state, SimState.MACHINE_WATER_RECYCLER)):
		_add_resource(
			state,
			SimState.WATER,
			economy.get_value(&"water_recycler_output_per_tick", 0.0),
			economy
		)


## Step 3: crew upkeep and the power draw of every network.
static func _apply_consumption(
	state: SimState,
	economy: EconomyData,
	networks: Array[PowerNetwork]
) -> void:
	_subtract_resource(
		state, SimState.OXYGEN, economy.get_value(&"oxygen_consumption_per_tick", 0.0)
	)
	_subtract_resource(
		state, SimState.WATER, economy.get_value(&"water_consumption_per_tick", 0.0)
	)
	_subtract_resource(
		state, SimState.FOOD, economy.get_value(&"food_consumption_per_tick", 0.0)
	)
	state.hunger = maxf(0.0, state.hunger - economy.get_value(&"hunger_drain_per_tick", 0.0))
	state.thirst = maxf(0.0, state.thirst - economy.get_value(&"thirst_drain_per_tick", 0.0))
	for network: PowerNetwork in networks:
		if not network.has_charge(state):
			continue
		network.spend_charge(state, network.demand(state, economy))


## Step 4: wear each machine down; crossing from health to zero is a breakdown.
static func _apply_degradation(
	state: SimState,
	economy: EconomyData,
	facts: Array[LogEntry]
) -> void:
	for id: StringName in SimState.MACHINE_IDS:
		var machine: MachineState = _machine(state, id)
		if machine == null:
			continue
		var previous_health: float = machine.health
		var row_id: StringName = StringName("machine_" + String(id) + "_degradation_per_tick")
		var degradation: float = economy.get_value(row_id, 0.0)
		machine.health = clampf(
			machine.health - degradation, 0.0, MachineState.MAX_HEALTH
		)
		if previous_health > 0.0 and machine.health <= 0.0:
			machine.powered = false
			var payload: Dictionary[Variant, Variant] = {}
			payload[&"machine"] = id
			facts.append(LogEntry.new(LogEntry.Type.MACHINE_BREAKDOWN, state.tick, payload))


## Step 6: energy, oxygen, hunger, thirst and radiation consequences.
## Returns true when the radiation cap applied its damage this tick.
static func _apply_consequences(
	state: SimState,
	economy: EconomyData,
	networks: Array[PowerNetwork],
	facts: Array[LogEntry]
) -> bool:
	_apply_energy_consequences(state, economy, networks, facts)
	if state.get_resource(SimState.OXYGEN) <= 0.0:
		if state.suit_reserve_ticks > 0:
			state.suit_reserve_ticks -= 1
		else:
			state.health -= economy.get_value(&"hypoxia_damage_per_tick", 0.0)
	if state.hunger <= 0.0:
		state.health -= economy.get_value(&"starvation_damage_per_tick", 0.0)
	if state.thirst <= 0.0:
		state.health -= economy.get_value(&"dehydration_damage_per_tick", 0.0)
	return _apply_radiation(state, economy, facts)


## Blackout bookkeeping per network: one BLACKOUT fact per episode and network,
## plus the shutdown order applied only inside the depleted network.
static func _apply_energy_consequences(
	state: SimState,
	economy: EconomyData,
	networks: Array[PowerNetwork],
	facts: Array[LogEntry]
) -> void:
	for network: PowerNetwork in networks:
		if not network.has_load(state):
			state.blackout_networks[network.id] = false
			continue
		if network.total_charge(state) > 0.0:
			state.blackout_networks[network.id] = false
			continue
		if not bool(state.blackout_networks.get(network.id, false)):
			state.blackout_networks[network.id] = true
			var payload: Dictionary[Variant, Variant] = {}
			payload[&"network"] = network.id
			facts.append(LogEntry.new(LogEntry.Type.BLACKOUT, state.tick, payload))
		_shut_down_machines(state, economy, network)


## Powers off up to blackout_steps_per_tick machines of the priority list,
## restricted to the machines that belong to the depleted network.
static func _shut_down_machines(
	state: SimState,
	economy: EconomyData,
	network: PowerNetwork
) -> void:
	var raw_steps: float = economy.get_value(&"blackout_steps_per_tick", _FALLBACK_BLACKOUT_STEPS)
	var steps: int = int(maxf(1.0, raw_steps))
	var turned_off: int = 0
	for id: StringName in SimState.BLACKOUT_ORDER:
		if turned_off >= steps:
			break
		if not network.has_node(id):
			continue
		var machine: MachineState = _machine(state, id)
		if not _is_operational(machine):
			continue
		machine.powered = false
		turned_off += 1


## Radiation is cumulative and never decays; the cap lowers max_health.
## Returns true only when the cap branch applied damage this tick.
static func _apply_radiation(
	state: SimState,
	economy: EconomyData,
	facts: Array[LogEntry]
) -> bool:
	if state.is_outside:
		var suit_multiplier: float = 1.0
		if state.suit_level >= 1:
			suit_multiplier = economy.get_value(
				&"suit_v2_radiation_multiplier", _FALLBACK_SUIT_MULTIPLIER
			)
		state.radiation_dose += economy.get_value(
			&"radiation_per_tick_exterior", 0.0
		) * suit_multiplier
		if state.radiation_dose > state.peak_radiation:
			state.peak_radiation = state.radiation_dose
			var payload: Dictionary[Variant, Variant] = {}
			payload[&"dose"] = state.radiation_dose
			facts.append(LogEntry.new(LogEntry.Type.RADIATION_PEAK, state.tick, payload))
	var death_threshold: float = economy.get_value(
		&"radiation_threshold_death", _FALLBACK_RADIATION_DEATH
	)
	if state.radiation_dose >= death_threshold:
		state.health = 0.0
		return false
	var cap_threshold: float = economy.get_value(
		&"radiation_threshold_cap", _FALLBACK_RADIATION_CAP
	)
	if state.radiation_dose > cap_threshold:
		var base_max_health: float = economy.get_value(
			&"max_health", _FALLBACK_MAX_HEALTH
		)
		state.max_health = base_max_health * cap_threshold / 100.0
		state.health = minf(state.health, state.max_health)
		state.health -= economy.get_value(&"radiation_health_damage_per_tick", 0.0)
		return true
	return false


## Step 6 (death): the first tick that reaches zero health closes the run.
static func _apply_death(
	state: SimState,
	economy: EconomyData,
	facts: Array[LogEntry],
	radiation_damage_applied: bool
) -> void:
	state.health = maxf(0.0, state.health)
	if state.health > 0.0:
		return
	var death_threshold: float = economy.get_value(
		&"radiation_threshold_death", _FALLBACK_RADIATION_DEATH
	)
	var cap_threshold: float = economy.get_value(
		&"radiation_threshold_cap", _FALLBACK_RADIATION_CAP
	)
	var cause: StringName = &"health"
	if state.radiation_dose >= death_threshold:
		cause = &"radiation"
	elif state.radiation_dose > cap_threshold and radiation_damage_applied:
		cause = &"radiation"
	elif state.get_resource(SimState.OXYGEN) <= 0.0 and state.suit_reserve_ticks <= 0:
		cause = &"hypoxia"
	elif state.hunger <= 0.0:
		cause = &"starvation"
	elif state.thirst <= 0.0:
		cause = &"dehydration"
	state.game_over = true
	state.death_cause = cause
	var death_payload: Dictionary[Variant, Variant] = {}
	death_payload[&"cause"] = cause
	facts.append(LogEntry.new(LogEntry.Type.DEATH, state.tick, death_payload))
	var over_payload: Dictionary[Variant, Variant] = {}
	over_payload[&"resources"] = state.resources.duplicate()
	facts.append(LogEntry.new(LogEntry.Type.GAME_OVER, state.tick, over_payload))


## Step 7: a SOL_COMPLETED fact at the end of every sol, whose length comes from
## the same economy rows that drive the day/night phase.
static func _apply_sol_facts(state: SimState, economy: EconomyData, facts: Array[LogEntry]) -> void:
	var sol_length: int = state.get_sol_length(economy)
	var new_tick: int = state.tick + 1
	if new_tick % sol_length != 0:
		return
	var payload: Dictionary[Variant, Variant] = {}
	payload[&"sol"] = int(new_tick / sol_length)
	facts.append(LogEntry.new(LogEntry.Type.SOL_COMPLETED, state.tick, payload))


## Machine lookup that tolerates a state built without reset_from_economy.
static func _machine(state: SimState, id: StringName) -> MachineState:
	if not state.machines.has(id):
		return null
	var machine: MachineState = state.machines[id]
	return machine


## A machine produces, consumes and can be shut down only while powered and healthy.
static func _is_operational(machine: MachineState) -> bool:
	if machine == null:
		return false
	return machine.powered and not machine.is_broken()


## Adds amount to a resource, clamped to its capacity row.
static func _add_resource(
	state: SimState,
	id: StringName,
	amount: float,
	economy: EconomyData
) -> void:
	var capacity_id: StringName = StringName("capacity_" + String(id))
	var capacity: float = economy.get_value(capacity_id, _FALLBACK_CAPACITY)
	state.set_resource(id, minf(state.get_resource(id) + amount, capacity))


## Subtracts amount from a resource, clamped at zero.
static func _subtract_resource(state: SimState, id: StringName, amount: float) -> void:
	state.set_resource(id, maxf(0.0, state.get_resource(id) - amount))
