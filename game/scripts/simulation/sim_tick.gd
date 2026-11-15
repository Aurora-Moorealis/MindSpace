class_name SimTick
extends RefCounted

## Deterministic advance of one simulation tick (contract v1).
## No randomness and no real time: same state plus same economy, same result.
## The step order is fixed: production, consumption, degradation, machine work
## (repairs in progress), events, consequences, death and calendar facts.

const _FALLBACK_CAPACITY: float = 10.0
const _FALLBACK_MAX_HEALTH: float = 100.0
const _FALLBACK_RADIATION_CAP: float = 30.0
const _FALLBACK_RADIATION_DEATH: float = 100.0
const _FALLBACK_SOLAR_OUTPUT: float = 1.5
const _FALLBACK_BLACKOUT_STEPS: float = 1.0
const _FALLBACK_SUIT_MULTIPLIER: float = 1.0


## Advances p_state one tick and returns the facts emitted by that tick.
static func step(
	state: SimState,
	economy: EconomyData,
	machines: MachineDatabase,
	events: EventData = null
) -> Array[LogEntry]:
	var facts: Array[LogEntry] = []
	# A finished run keeps counting ticks but emits nothing else.
	if state.game_over:
		state.tick += 1
		return facts

	var networks: Array[PowerNetwork] = PowerGrid.build(state)
	_apply_production(state, economy, networks)
	_apply_consumption(state, economy, machines, networks)
	state.sync_energy_resource()
	_apply_degradation(state, economy, facts)
	_apply_machine_work(state, facts)
	_apply_events(state, events, facts)
	var radiation_damage_applied: bool = _apply_consequences(
		state, economy, networks, facts
	)
	_apply_death(state, economy, facts, radiation_damage_applied)
	_apply_mission_end(state, facts)
	_apply_sol_facts(state, economy, facts)
	state.tick += 1
	return facts


## Step 2: machines that are powered and healthy produce during the day.
## Each output is the economy base plus the machine production delta. Solar
## output is stored in the batteries of the panel's own network.
static func _apply_production(
	state: SimState, economy: EconomyData, networks: Array[PowerNetwork]
) -> void:
	var is_day: bool = state.get_phase(economy) == SimState.DayPhase.DAY
	var solar: MachineState = _machine(state, SimState.MACHINE_SOLAR_ARRAY)
	if is_day and _is_operational(solar):
		var solar_base: float = economy.get_value(
			&"solar_output_per_tick", _FALLBACK_SOLAR_OUTPUT
		)
		var solar_output: float = _effective_output(solar, SimState.ENERGY, solar_base)
		for network: PowerNetwork in networks:
			if network.has_node(SimState.MACHINE_SOLAR_ARRAY):
				network.add_charge(state, economy, solar_output)
	var hydroponics: MachineState = _machine(state, SimState.MACHINE_HYDROPONICS)
	if _is_operational(hydroponics):
		var food_base: float = economy.get_value(&"hydroponics_food_output_per_tick", 0.0)
		_add_resource(
			state,
			SimState.FOOD,
			_effective_output(hydroponics, SimState.FOOD, food_base),
			economy
		)
		var oxygen_base: float = economy.get_value(
			&"hydroponics_oxygen_output_per_tick", 0.0
		)
		_add_resource(
			state,
			SimState.OXYGEN,
			_effective_output(hydroponics, SimState.OXYGEN, oxygen_base),
			economy
		)
	var recycler: MachineState = _machine(state, SimState.MACHINE_WATER_RECYCLER)
	if _is_operational(recycler):
		var water_base: float = economy.get_value(&"water_recycler_output_per_tick", 0.0)
		_add_resource(
			state,
			SimState.WATER,
			_effective_output(recycler, SimState.WATER, water_base),
			economy
		)


## Step 3: crew upkeep plus the consumption sheet of every operating machine.
## Invalid entries are sanitized on read: null, empty/unknown resources and
## duplicated resources are ignored, and a negative amount counts as zero.
static func _apply_consumption(
	state: SimState,
	economy: EconomyData,
	machines: MachineDatabase,
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
		var energy_drain: float = 0.0
		for id: StringName in network.nodes:
			var machine: MachineState = _machine(state, id)
			if not _is_operational(machine):
				continue
			var data: MachineData = null
			if machines != null:
				data = machines.get_machine(id)
			# A missing sheet was already reported at boot: consume nothing.
			if data == null:
				continue
			energy_drain += _apply_machine_consumption(state, machine, data)
		network.spend_charge(state, energy_drain)


## Applies the sanitized consumption of one machine and returns its energy
## drain. The first valid entry per resource wins; later duplicates are ignored.
static func _apply_machine_consumption(
	state: SimState, machine: MachineState, data: MachineData
) -> float:
	var energy_drain: float = 0.0
	var has_energy_entry: bool = false
	var seen_resources: Dictionary[StringName, bool] = {}
	for entry: MachineConsumption in data.consumption:
		if entry == null:
			continue
		# Invalid or unknown resources are ignored: they never create state keys.
		if not MachineConsumption.VALID_RESOURCES.has(entry.resource):
			continue
		if seen_resources.has(entry.resource):
			continue
		seen_resources[entry.resource] = true
		var amount: float = maxf(0.0, entry.amount_per_tick)
		if entry.resource == SimState.ENERGY:
			has_energy_entry = true
			energy_drain += maxf(0.0, amount + machine.power_delta)
		else:
			_subtract_resource(state, entry.resource, amount)
	# A power upgrade still applies when the sheet declares no energy entry.
	if not has_energy_entry:
		energy_drain += maxf(0.0, machine.power_delta)
	return energy_drain


## Step 4: wear each machine down; crossing from health to zero is a breakdown.
## Degradation is the economy row plus the machine degradation delta.
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
		var degradation: float = maxf(
			0.0, economy.get_value(row_id, 0.0) + machine.degradation_delta
		)
		machine.health = clampf(
			machine.health - degradation, 0.0, MachineState.MAX_HEALTH
		)
		if previous_health > 0.0 and machine.health <= 0.0:
			machine.powered = false
			var payload: Dictionary[Variant, Variant] = {}
			payload[&"machine"] = id
			facts.append(LogEntry.new(LogEntry.Type.MACHINE_BREAKDOWN, state.tick, payload))


## Step 5: every repair in progress accumulates player work divisions; the
## tick that reaches the total restores the machine and emits one REPAIR fact.
static func _apply_machine_work(state: SimState, facts: Array[LogEntry]) -> void:
	for id: StringName in SimState.MACHINE_IDS:
		var machine: MachineState = _machine(state, id)
		if machine == null:
			continue
		if machine.repair_ticks_total <= 0:
			continue
		if machine.repair_work_done >= float(machine.repair_ticks_total):
			continue
		machine.repair_work_done += state.player.repair_speed_multiplier
		if machine.repair_work_done < float(machine.repair_ticks_total):
			continue
		machine.health = MachineState.MAX_HEALTH
		machine.powered = true
		machine.repair_ticks_total = 0
		machine.repair_work_done = 0.0
		var payload: Dictionary[Variant, Variant] = {}
		payload[&"machine"] = id
		facts.append(LogEntry.new(LogEntry.Type.REPAIR, state.tick, payload))
## Step 6: event scheduler and active event effects.
## Expire first, enqueue due rows, start what can start, then apply intensity.
static func _apply_events(
	state: SimState,
	events: EventData,
	facts: Array[LogEntry]
) -> void:
	if events == null:
		state.active_events.clear()
		state.pending_events.clear()
		state.comms_blocked = false
		return

	var ordered: Array[EventRow] = _sorted_events(events)
	_expire_active_events(state, facts)
	_enqueue_due_events(state, ordered)
	_start_ready_events(state, events, facts)
	_apply_active_events(state, facts)
	state.comms_blocked = _has_active_blackout(state)


## Sorted by onset and then id, so the cursor is stable and deterministic.
static func _sorted_events(events: EventData) -> Array[EventRow]:
	var ordered: Array[EventRow] = []
	for row: EventRow in events.rows:
		ordered.append(row)
	ordered.sort_custom(
		func(first: EventRow, second: EventRow) -> bool:
			if first.onset_tick == second.onset_tick:
				return String(first.id) < String(second.id)
			return first.onset_tick < second.onset_tick
	)
	return ordered


## Emits EVENT_ENDED for every active event whose window is over.
static func _expire_active_events(state: SimState, facts: Array[LogEntry]) -> void:
	var remaining: Array[ActiveEvent] = []
	for active: ActiveEvent in state.active_events:
		if active.row == null:
			continue
		if state.tick >= active.end_tick():
			var payload: Dictionary[Variant, Variant] = {}
			payload[&"id"] = active.row.id
			payload[&"end_tick"] = state.tick
			facts.append(LogEntry.new(LogEntry.Type.EVENT_ENDED, state.tick, payload))
		else:
			remaining.append(active)
	state.active_events = remaining


## Moves every row whose onset has arrived into the pending queue.
static func _enqueue_due_events(state: SimState, ordered: Array[EventRow]) -> void:
	while state.event_cursor < ordered.size():
		var row: EventRow = ordered[state.event_cursor]
		if row.onset_tick > state.tick:
			break
		state.pending_events.append(PendingEvent.new(row, state.tick))
		state.event_cursor += 1


## Starts pending events that are due and can overlap with every active event.
## A blocked event waits until the latest active window ends plus a deterministic
## delay derived from the run seed and the event id.
static func _start_ready_events(
	state: SimState,
	events: EventData,
	facts: Array[LogEntry]
) -> void:
	var still_pending: Array[PendingEvent] = []
	for pending: PendingEvent in state.pending_events:
		if pending.row == null:
			continue
		if pending.not_before_tick > state.tick:
			still_pending.append(pending)
			continue
		if _can_start(state, events, pending.row):
			state.active_events.append(ActiveEvent.new(pending.row, state.tick))
			var payload: Dictionary[Variant, Variant] = {}
			payload[&"id"] = pending.row.id
			payload[&"archetype"] = pending.row.archetype
			payload[&"target"] = pending.row.target_id
			payload[&"started_tick"] = state.tick
			facts.append(LogEntry.new(LogEntry.Type.EVENT_STARTED, state.tick, payload))
		else:
			pending.not_before_tick = (
				_latest_active_end_tick(state) + _queue_delay(state, pending.row)
			)
			still_pending.append(pending)
	state.pending_events = still_pending


static func _can_start(state: SimState, events: EventData, row: EventRow) -> bool:
	for active: ActiveEvent in state.active_events:
		if active.row == null:
			continue
		if not events.can_overlap(row, active.row):
			return false
	return true


static func _latest_active_end_tick(state: SimState) -> int:
	var latest: int = state.tick
	for active: ActiveEvent in state.active_events:
		if active.row == null:
			continue
		latest = maxi(latest, active.end_tick())
	return latest


## Deterministic delay in [delay_min_ticks, delay_max_ticks].
static func _queue_delay(state: SimState, row: EventRow) -> int:
	var minimum: int = maxi(0, row.delay_min_ticks)
	var maximum: int = maxi(minimum, row.delay_max_ticks)
	if maximum <= minimum:
		return minimum
	var span: int = maximum - minimum + 1
	var seed_text: String = "%d:%s" % [state.run_seed, String(row.id)]
	return minimum + (_stable_hash(seed_text) % span)


## FNV-1a over UTF-8 code points; stable across runs, unlike hash().
static func _stable_hash(text: String) -> int:
	var hash_value: int = 2166136261
	for index: int in text.length():
		hash_value = hash_value ^ text.unicode_at(index)
		hash_value = (hash_value * 16777619) & 0xFFFFFFFF
	return hash_value


static func _apply_active_events(state: SimState, facts: Array[LogEntry]) -> void:
	for active: ActiveEvent in state.active_events:
		if active.row == null:
			continue
		var elapsed: int = state.tick - active.started_tick
		_apply_event_effect(state, active.row, active.row.intensity_at(elapsed), facts)


static func _apply_event_effect(
	state: SimState,
	row: EventRow,
	delta: float,
	facts: Array[LogEntry]
) -> void:
	match row.archetype:
		EventRow.Archetype.MACHINE_BREAKDOWN:
			var machine: MachineState = _machine(state, row.target_id)
			if machine == null:
				return
			var previous_health: float = machine.health
			machine.health = maxf(0.0, machine.health + delta)
			if previous_health > 0.0 and machine.health <= 0.0:
				machine.powered = false
				var payload: Dictionary[Variant, Variant] = {}
				payload[&"machine"] = row.target_id
				payload[&"event"] = row.id
				facts.append(LogEntry.new(LogEntry.Type.MACHINE_BREAKDOWN, state.tick, payload))
		EventRow.Archetype.PRODUCTION_DROP, EventRow.Archetype.CONSUMPTION_SPIKE:
			_subtract_resource(state, row.target_id, -delta)
		EventRow.Archetype.RADIATION_WINDOW:
			if state.is_outside:
				state.radiation_dose += delta
		EventRow.Archetype.COMMS_BLACKOUT:
			pass


static func _has_active_blackout(state: SimState) -> bool:
	for active: ActiveEvent in state.active_events:
		if active.row != null and active.row.archetype == EventRow.Archetype.COMMS_BLACKOUT:
			return true
	return false


## Step 7: energy, oxygen, hunger, thirst and radiation consequences.
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
## plus the shutdown order applied only inside the depleted network. A network
## that holds charge again powers its machines back in reverse order. The legacy
## blackout_active flag stays true while any network is in blackout.
static func _apply_energy_consequences(
	state: SimState,
	economy: EconomyData,
	networks: Array[PowerNetwork],
	facts: Array[LogEntry]
) -> void:
	var any_blackout: bool = false
	for network: PowerNetwork in networks:
		if not network.has_load(state):
			state.blackout_networks[network.id] = false
			continue
		if network.total_charge(state) > 0.0:
			state.blackout_networks[network.id] = false
			_restore_machines(state, economy, network)
			continue
		any_blackout = true
		if not bool(state.blackout_networks.get(network.id, false)):
			state.blackout_networks[network.id] = true
			var payload: Dictionary[Variant, Variant] = {}
			payload[&"network"] = network.id
			facts.append(LogEntry.new(LogEntry.Type.BLACKOUT, state.tick, payload))
		_shut_down_machines(state, economy, network)
	state.blackout_active = any_blackout


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


## Powers on up to blackout_steps_per_tick machines of the priority list in
## reverse order, restricted to the machines that belong to the recharged
## network. Already powered machines and broken machines are skipped, so a
## breakdown waits until it is repaired.
static func _restore_machines(
	state: SimState,
	economy: EconomyData,
	network: PowerNetwork
) -> void:
	var raw_steps: float = economy.get_value(&"blackout_steps_per_tick", _FALLBACK_BLACKOUT_STEPS)
	var steps: int = int(maxf(1.0, raw_steps))
	var order: Array[StringName] = SimState.BLACKOUT_ORDER
	var restored: int = 0
	for index: int in range(order.size() - 1, -1, -1):
		if restored >= steps:
			break
		var id: StringName = order[index]
		if not network.has_node(id):
			continue
		var machine: MachineState = _machine(state, id)
		if machine == null or machine.powered or machine.is_broken():
			continue
		machine.powered = true
		restored += 1


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


## Step 8: the first tick that reaches zero health closes the run.
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
	state.run_result = SimState.RunResult.DEFEAT
	state.death_cause = cause
	var death_payload: Dictionary[Variant, Variant] = {}
	death_payload[&"cause"] = cause
	facts.append(LogEntry.new(LogEntry.Type.DEATH, state.tick, death_payload))
	var over_payload: Dictionary[Variant, Variant] = {}
	over_payload[&"resources"] = state.resources.duplicate()
	over_payload[&"cause"] = cause
	over_payload[&"result"] = &"defeat"
	facts.append(LogEntry.new(LogEntry.Type.GAME_OVER, state.tick, over_payload))


## Step 9: the mission clock closes the run in victory when it reaches the
## configured length with the astronaut alive. Death has already run, so a
## fatal last tick stays a defeat and never produces a second GAME_OVER.
static func _apply_mission_end(state: SimState, facts: Array[LogEntry]) -> void:
	if state.game_over:
		return
	if state.tick + 1 < state.mission_length_ticks:
		return
	state.game_over = true
	state.run_result = SimState.RunResult.VICTORY
	state.death_cause = &"mission_complete"
	var payload: Dictionary[Variant, Variant] = {}
	payload[&"resources"] = state.resources.duplicate()
	payload[&"cause"] = state.death_cause
	payload[&"result"] = &"victory"
	facts.append(LogEntry.new(LogEntry.Type.GAME_OVER, state.tick, payload))


## Step 10: a SOL_COMPLETED fact at the end of every sol, whose length comes from
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


## Base economy output plus the machine production delta, never negative.
static func _effective_output(
	machine: MachineState, resource_id: StringName, base: float
) -> float:
	return maxf(0.0, base + machine.output_deltas.get(resource_id, 0.0))


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
