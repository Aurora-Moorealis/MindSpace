extends SceneTree

## Integration smoke test for the simulation core (tasks 7.1 and 8.2).
## Loads the real economy and machine databases, drives SimTick over fresh
## states, feeds the facts into a private EventLog instance and asserts the run
## contract: numerical soundness, determinism, deaths, mission outcomes,
## blackout order and recovery, radiation and the evaluation counters.
## Run: godot --headless --path game --script res://scripts/dev/sim_smoke.gd
## Exit code 0 when every check passes, 1 otherwise.

const ECONOMY_PATH: String = "res://databases/economy.tres"
const MACHINES_PATH: String = "res://databases/machines.tres"
const EventLogScript: GDScript = preload("res://scripts/autoloads/event_log.gd")

const RUN_TICKS: int = 300
const GUARD_STEPS: int = 1000
const RESOURCE_IDS: Array[StringName] = [
	SimState.OXYGEN, SimState.WATER, SimState.FOOD, SimState.ENERGY,
]
const BLACKOUT_EXPECTED_ORDER: Array[StringName] = [
	SimState.MACHINE_LIGHTS,
	SimState.MACHINE_HYDROPONICS,
	SimState.MACHINE_WATER_RECYCLER,
	SimState.MACHINE_O2_SYSTEM,
]

var _checks: int = 0
var _failures: int = 0


func _init() -> void:
	var economy: EconomyData = ResourceLoader.load(ECONOMY_PATH) as EconomyData
	if economy == null:
		push_error("sim_smoke: cannot load %s as EconomyData" % ECONOMY_PATH)
		quit(1)
		return
	var machines: MachineDatabase = ResourceLoader.load(MACHINES_PATH) as MachineDatabase
	if machines == null:
		push_error("sim_smoke: cannot load %s as MachineDatabase" % MACHINES_PATH)
		quit(1)
		return

	_check_300_ticks(economy, machines)
	_check_mission_state(economy)
	_check_mission_victory(economy, machines)
	_check_mission_defeat(economy, machines)
	_check_mission_death_priority(economy, machines)
	_check_determinism(economy, machines)
	_check_hypoxia_death(economy, machines)
	_check_blackout_order(economy, machines)
	_check_blackout_recovery(economy, machines)
	_check_radiation(economy, machines)
	_check_summary_counters(economy, machines)
	_check_sol_from_economy(machines)
	_check_economy_fallback()
	_check_power_grid(economy, machines)
	_check_suit_shield(economy, machines)

	print("sim_smoke: %d checks, %s" % [_checks, "FAIL" if _failures > 0 else "OK"])
	quit(1 if _failures > 0 else 0)


## (a) A passive run on the real economy wins: 300 ticks leave a numerically
## sound state, close the mission clock and end in victory.
func _check_300_ticks(economy: EconomyData, machines: MachineDatabase) -> void:
	_expect(
		is_equal_approx(economy.get_value(&"mission_length_ticks", -1.0), 300.0),
		"a: the real economy must define a 300-tick mission (got %f)"
		% economy.get_value(&"mission_length_ticks", -1.0)
	)
	var state: SimState = _fresh_state(economy)
	var facts: Array[LogEntry] = []
	for i: int in range(RUN_TICKS):
		facts.append_array(SimTick.step(state, economy, machines))
	_expect(state.tick == RUN_TICKS, "a: tick must be %d (got %d)" % [RUN_TICKS, state.tick])
	for id: StringName in RESOURCE_IDS:
		var value: float = state.get_resource(id)
		_expect(is_finite(value), "a: %s must be finite (got %f)" % [id, value])
		_expect(value >= 0.0, "a: %s must not be negative (got %f)" % [id, value])
	_expect(is_finite(state.health), "a: health must be finite (got %f)" % state.health)
	_expect(state.health >= 0.0, "a: health must not be negative (got %f)" % state.health)
	_expect(
		is_finite(state.radiation_dose),
		"a: radiation dose must be finite (got %f)" % state.radiation_dose
	)
	_expect(
		is_finite(state.hunger) and is_finite(state.thirst),
		"a: hunger and thirst must be finite (got %f / %f)" % [state.hunger, state.thirst]
	)
	_expect(state.game_over, "a: 300 ticks must close the run")
	_expect(
		state.run_result == SimState.RunResult.VICTORY,
		"a: a passive run on the real economy must end in victory (got %d)"
		% state.run_result
	)
	var game_over_count: int = _count_facts(facts, LogEntry.Type.GAME_OVER)
	_expect(
		game_over_count == 1,
		"a: the run must emit exactly one GAME_OVER (got %d)" % game_over_count
	)
	print(
		"sim_smoke: a) ticks=%d facts=%d health=%.2f dose=%.2f dead=%s cause=%s result=%d over=%d"
		% [
			state.tick,
			facts.size(),
			state.health,
			state.radiation_dose,
			str(state.game_over),
			str(state.death_cause),
			state.run_result,
			game_over_count,
		]
	)


## (k) Mission clock and run result reset together with the economy.
func _check_mission_state(economy: EconomyData) -> void:
	var state: SimState = _fresh_state(economy)
	_expect(
		state.run_result == SimState.RunResult.IN_PROGRESS,
		"k: a fresh run must be in progress"
	)
	_expect(
		state.mission_length_ticks == 300,
		"k: mission length must be 300 (got %d)" % state.mission_length_ticks
	)
	_expect(
		state.get_mission_ticks_left() == 300,
		"k: a fresh run must have 300 mission ticks left (got %d)"
		% state.get_mission_ticks_left()
	)
	state.tick = 1
	_expect(
		state.get_mission_ticks_left() == 299,
		"k: one elapsed tick must leave 299 (got %d)"
		% state.get_mission_ticks_left()
	)
	state.run_result = SimState.RunResult.VICTORY
	state.reset_from_economy(economy)
	_expect(
		state.run_result == SimState.RunResult.IN_PROGRESS,
		"k: a reset must clear the run result"
	)
	_expect(
		state.tick == 0 and state.get_mission_ticks_left() == 300,
		"k: a reset must restore the mission clock"
	)
	print(
		"sim_smoke: k) mission_length=%d result=%d"
		% [state.mission_length_ticks, state.run_result]
	)


## (l) Surviving the mission clock closes the run as a victory.
func _check_mission_victory(economy: EconomyData, machines: MachineDatabase) -> void:
	var safe: EconomyData = _safe_economy(RUN_TICKS)
	var state: SimState = _fresh_state(safe)
	var facts: Array[LogEntry] = []
	for i: int in range(RUN_TICKS):
		facts.append_array(SimTick.step(state, safe, machines))
	_expect(
		state.run_result == SimState.RunResult.VICTORY,
		"l: surviving the mission clock must end in victory (got %d)" % state.run_result
	)
	_expect(
		state.tick == RUN_TICKS,
		"l: a victory run must end at tick %d (got %d)" % [RUN_TICKS, state.tick]
	)
	_expect(
		state.death_cause == &"mission_complete",
		"l: a victory must record mission_complete (got %s)" % str(state.death_cause)
	)
	_expect(
		state.mission_length_ticks == int(economy.get_value(&"mission_length_ticks", -1.0)),
		"l: the synthetic mission must mirror the real economy (%d != %f)"
		% [state.mission_length_ticks, economy.get_value(&"mission_length_ticks", -1.0)]
	)
	var game_overs: Array[LogEntry] = _facts_of_type(facts, LogEntry.Type.GAME_OVER)
	_expect(
		game_overs.size() == 1,
		"l: a victory must emit exactly one GAME_OVER (got %d)" % game_overs.size()
	)
	if game_overs.size() == 1:
		var payload: Dictionary[Variant, Variant] = game_overs[0].payload
		var result_raw: Variant = payload.get(&"result")
		var cause_raw: Variant = payload.get(&"cause")
		var resources_raw: Variant = payload.get(&"resources")
		_expect(
			result_raw == &"victory",
			"l: the GAME_OVER result must be victory (got %s)" % str(result_raw)
		)
		_expect(
			cause_raw == &"mission_complete",
			"l: the GAME_OVER cause must be mission_complete (got %s)" % str(cause_raw)
		)
		_expect(
			typeof(resources_raw) == TYPE_DICTIONARY,
			"l: the GAME_OVER payload must carry a resources dictionary (got %s)"
			% type_string(typeof(resources_raw))
		)
		_expect(
			_resources_from_payload(payload).size() == RESOURCE_IDS.size(),
			"l: the victory payload must carry every resource (got %d)"
			% _resources_from_payload(payload).size()
		)
	var end_tick: int = state.tick
	var extra: Array[LogEntry] = SimTick.step(state, safe, machines)
	_expect(
		extra.is_empty(),
		"l: a finished run must not emit facts (got %d)" % extra.size()
	)
	print(
		"sim_smoke: l) ticks=%d result=%d cause=%s over=%d"
		% [end_tick, state.run_result, str(state.death_cause), game_overs.size()]
	)


## (m) A death before the mission clock closes the run as a defeat.
func _check_mission_defeat(economy: EconomyData, machines: MachineDatabase) -> void:
	var state: SimState = _fresh_state(economy)
	state.is_outside = true
	var facts: Array[LogEntry] = []
	var steps: int = 0
	while not state.game_over and steps < RUN_TICKS:
		facts.append_array(SimTick.step(state, economy, machines))
		steps += 1
	_expect(
		state.game_over,
		"m: staying outside must end the run within %d steps" % RUN_TICKS
	)
	_expect(
		state.run_result == SimState.RunResult.DEFEAT,
		"m: a death must end in defeat (got %d)" % state.run_result
	)
	_expect(
		state.tick < RUN_TICKS,
		"m: the death must happen before the mission clock (tick %d)" % state.tick
	)
	_expect(
		state.death_cause == &"radiation",
		"m: the death cause must be radiation (got %s)" % str(state.death_cause)
	)
	var game_overs: Array[LogEntry] = _facts_of_type(facts, LogEntry.Type.GAME_OVER)
	_expect(
		game_overs.size() == 1,
		"m: a defeat must emit exactly one GAME_OVER (got %d)" % game_overs.size()
	)
	if game_overs.size() == 1:
		var result_raw: Variant = game_overs[0].payload.get(&"result")
		_expect(
			result_raw == &"defeat",
			"m: the GAME_OVER result must be defeat (got %s)" % str(result_raw)
		)
	print(
		"sim_smoke: m) steps=%d death_tick=%d result=%d cause=%s"
		% [steps, state.tick, state.run_result, str(state.death_cause)]
	)


## (n) A fatal last tick stays a defeat: death runs before the mission clock.
func _check_mission_death_priority(economy: EconomyData, machines: MachineDatabase) -> void:
	var state: SimState = _fresh_state(economy)
	state.mission_length_ticks = 1
	state.health = 0.0
	var facts: Array[LogEntry] = SimTick.step(state, economy, machines)
	_expect(
		state.run_result == SimState.RunResult.DEFEAT,
		"n: a fatal last tick must end in defeat (got %d)" % state.run_result
	)
	_expect(
		state.death_cause != &"mission_complete",
		"n: a fatal last tick must not report mission_complete (got %s)"
		% str(state.death_cause)
	)
	var game_overs: Array[LogEntry] = _facts_of_type(facts, LogEntry.Type.GAME_OVER)
	_expect(
		game_overs.size() == 1,
		"n: the fatal last tick must emit exactly one GAME_OVER (got %d)"
		% game_overs.size()
	)
	if game_overs.size() == 1:
		var result_raw: Variant = game_overs[0].payload.get(&"result")
		_expect(
			result_raw == &"defeat",
			"n: the GAME_OVER result must be defeat (got %s)" % str(result_raw)
		)
	print(
		"sim_smoke: n) tick=%d result=%d cause=%s"
		% [state.tick, state.run_result, str(state.death_cause)]
	)


## (b) Two fresh runs of 300 ticks produce the same state and the same facts.
func _check_determinism(economy: EconomyData, machines: MachineDatabase) -> void:
	var first: SimState = _fresh_state(economy)
	var second: SimState = _fresh_state(economy)
	var first_facts: Array[LogEntry] = []
	var second_facts: Array[LogEntry] = []
	for i: int in range(RUN_TICKS):
		first_facts.append_array(SimTick.step(first, economy, machines))
		second_facts.append_array(SimTick.step(second, economy, machines))

	_expect(first.tick == second.tick, "b: both runs must end at the same tick")
	for id: StringName in RESOURCE_IDS:
		_expect(
			is_equal_approx(first.get_resource(id), second.get_resource(id)),
			"b: %s differs (%f != %f)"
			% [id, first.get_resource(id), second.get_resource(id)]
		)
	_expect(
		is_equal_approx(first.health, second.health),
		"b: health differs (%f != %f)" % [first.health, second.health]
	)
	_expect(
		is_equal_approx(first.radiation_dose, second.radiation_dose),
		"b: radiation dose differs (%f != %f)" % [first.radiation_dose, second.radiation_dose]
	)
	_expect(
		is_equal_approx(first.peak_radiation, second.peak_radiation),
		"b: peak radiation differs (%f != %f)"
		% [first.peak_radiation, second.peak_radiation]
	)
	_expect(
		is_equal_approx(first.hunger, second.hunger)
		and is_equal_approx(first.thirst, second.thirst),
		"b: hunger/thirst differ (%f/%f != %f/%f)"
		% [first.hunger, first.thirst, second.hunger, second.thirst]
	)
	_expect(
		first.suit_reserve_ticks == second.suit_reserve_ticks,
		"b: suit reserve differs (%d != %d)"
		% [first.suit_reserve_ticks, second.suit_reserve_ticks]
	)
	_expect(
		first.game_over == second.game_over and first.death_cause == second.death_cause,
		"b: death outcome differs (%s/%s != %s/%s)"
		% [str(first.game_over), str(first.death_cause), str(second.game_over), str(second.death_cause)]
	)
	for id: StringName in SimState.MACHINE_IDS:
		var first_machine: MachineState = _machine_of(first, id)
		var second_machine: MachineState = _machine_of(second, id)
		_expect(
			is_equal_approx(first_machine.health, second_machine.health),
			"b: %s health differs (%f != %f)"
			% [id, first_machine.health, second_machine.health]
		)
		_expect(
			first_machine.powered == second_machine.powered,
			"b: %s power state differs (%s != %s)"
			% [id, str(first_machine.powered), str(second_machine.powered)]
		)
	_expect(
		_fact_signature(first_facts) == _fact_signature(second_facts),
		"b: fact sequence differs (%d vs %d facts)"
		% [first_facts.size(), second_facts.size()]
	)
	print(
		"sim_smoke: b) ticks=%d/%d facts=%d/%d identical=%s"
		% [
			first.tick,
			second.tick,
			first_facts.size(),
			second_facts.size(),
			str(_fact_signature(first_facts) == _fact_signature(second_facts)),
		]
	)


## (c) Zero oxygen spends the suit reserve first, then kills by hypoxia once.
func _check_hypoxia_death(economy: EconomyData, machines: MachineDatabase) -> void:
	var state: SimState = _fresh_state(economy)
	_power_off_all(state)
	state.set_resource(SimState.OXYGEN, 0.0)
	var reserve: int = state.suit_reserve_ticks
	var start_health: float = state.health
	_expect(reserve > 0, "c: the fresh run must start with a suit reserve (got %d)" % reserve)

	for i: int in range(reserve):
		SimTick.step(state, economy, machines)
	_expect(
		not state.game_over,
		"c: the %d-step suit reserve must keep the run alive" % reserve
	)
	_expect(
		is_equal_approx(state.health, start_health),
		"c: the suit reserve must absorb all damage (health %f != %f)"
		% [state.health, start_health]
	)

	var steps: int = reserve
	var death_facts: Array[LogEntry] = []
	while not state.game_over and steps < GUARD_STEPS:
		var facts: Array[LogEntry] = SimTick.step(state, economy, machines)
		if state.game_over:
			death_facts = facts
		steps += 1
	_expect(state.game_over, "c: zero oxygen must end the run within %d steps" % GUARD_STEPS)
	_expect(
		state.death_cause == &"hypoxia",
		"c: death cause must be hypoxia (got %s)" % state.death_cause
	)
	_expect(state.suit_reserve_ticks == 0, "c: the suit reserve must be consumed")
	_expect(
		steps > reserve,
		"c: the run must outlive the reserve (%d steps, reserve %d)" % [steps, reserve]
	)
	_expect(
		_count_facts(death_facts, LogEntry.Type.DEATH) == 1,
		"c: the fatal tick must emit exactly one DEATH (got %d)"
		% _count_facts(death_facts, LogEntry.Type.DEATH)
	)
	_expect(
		_count_facts(death_facts, LogEntry.Type.GAME_OVER) == 1,
		"c: the fatal tick must emit exactly one GAME_OVER"
	)
	var extra: Array[LogEntry] = SimTick.step(state, economy, machines)
	_expect(
		_count_facts(extra, LogEntry.Type.DEATH) == 0,
		"c: a finished run must not emit a second DEATH"
	)
	print(
		"sim_smoke: c) reserve=%d steps=%d death_tick=%d cause=%s"
		% [reserve, steps, state.tick, str(state.death_cause)]
	)


## (d) With no energy the machinery shuts down one machine per tick, in order.
func _check_blackout_order(economy: EconomyData, machines: MachineDatabase) -> void:
	var state: SimState = _fresh_state(economy)
	# Night keeps the working solar array from masking the blackout.
	state.tick = 12
	state.set_resource(SimState.ENERGY, 0.0)
	var blackouts: int = 0
	for index: int in range(BLACKOUT_EXPECTED_ORDER.size()):
		var facts: Array[LogEntry] = SimTick.step(state, economy, machines)
		blackouts += _count_facts(facts, LogEntry.Type.BLACKOUT)
		var shut_down_id: StringName = BLACKOUT_EXPECTED_ORDER[index]
		_expect(
			not _machine_of(state, shut_down_id).powered,
			"d: step %d must power off %s" % [index + 1, shut_down_id]
		)
		for later: int in range(index + 1, BLACKOUT_EXPECTED_ORDER.size()):
			var still_on_id: StringName = BLACKOUT_EXPECTED_ORDER[later]
			_expect(
				_machine_of(state, still_on_id).powered,
				"d: step %d must keep %s powered" % [index + 1, still_on_id]
			)
	_expect(blackouts == 1, "d: one episode must emit one BLACKOUT (got %d)" % blackouts)

	# Hydroponics is off: food drains at the consumption rate, with no output.
	var food_before: float = state.get_resource(SimState.FOOD)
	var food_drain: float = economy.get_value(&"food_consumption_per_tick", 0.0)
	SimTick.step(state, economy, machines)
	_expect(
		is_equal_approx(state.get_resource(SimState.FOOD), food_before - food_drain),
		"d: a shut-down hydroponics must not produce food (%f, expected %f)"
		% [state.get_resource(SimState.FOOD), food_before - food_drain]
	)

	# An unpowered machine does not draw power either.
	var powered_state: SimState = _fresh_state(economy)
	powered_state.tick = 12
	powered_state.set_resource(SimState.ENERGY, 5.0)
	var off_state: SimState = _fresh_state(economy)
	off_state.tick = 12
	off_state.set_resource(SimState.ENERGY, 5.0)
	_machine_of(off_state, SimState.MACHINE_LIGHTS).powered = false
	SimTick.step(powered_state, economy, machines)
	SimTick.step(off_state, economy, machines)
	# The lights draw lives in the machine sheet since the economy rows moved.
	var lights_draw: float = _machine_energy_draw(machines, SimState.MACHINE_LIGHTS)
	_expect(
		is_equal_approx(
			off_state.get_resource(SimState.ENERGY) - powered_state.get_resource(SimState.ENERGY),
			lights_draw
		),
		"d: one unpowered lights must save %.2f energy (got %f)"
		% [
			lights_draw,
			off_state.get_resource(SimState.ENERGY) - powered_state.get_resource(SimState.ENERGY),
		]
	)
	print("sim_smoke: d) blackouts=%d order=%s" % [blackouts, str(BLACKOUT_EXPECTED_ORDER)])


## (o) A recharged network powers the machines back in reverse blackout order,
## one per tick, skips a broken machine and powers nothing while charge is zero.
func _check_blackout_recovery(economy: EconomyData, machines: MachineDatabase) -> void:
	var state: SimState = _fresh_state(economy)
	# Night keeps the working solar array from masking the blackout.
	state.tick = 12
	state.set_battery_charge(SimState.DEFAULT_BATTERY_ID, 0.0)
	for index: int in range(BLACKOUT_EXPECTED_ORDER.size()):
		SimTick.step(state, economy, machines)
	for id: StringName in BLACKOUT_EXPECTED_ORDER:
		_expect(
			not _machine_of(state, id).powered,
			"o: the blackout must power off %s" % id
		)

	var capacity: float = economy.get_value(
		&"capacity_energy", PowerNetwork.FALLBACK_CAPACITY
	)
	var recovery_order: Array[StringName] = []
	for index: int in range(BLACKOUT_EXPECTED_ORDER.size() - 1, -1, -1):
		recovery_order.append(BLACKOUT_EXPECTED_ORDER[index])
	state.set_battery_charge(SimState.DEFAULT_BATTERY_ID, capacity)
	for step: int in range(recovery_order.size()):
		SimTick.step(state, economy, machines)
		var restored_id: StringName = recovery_order[step]
		_expect(
			_machine_of(state, restored_id).powered,
			"o: recovery step %d must power on %s" % [step + 1, restored_id]
		)
		for pending_index: int in range(step + 1, recovery_order.size()):
			var waiting_id: StringName = recovery_order[pending_index]
			_expect(
				not _machine_of(state, waiting_id).powered,
				"o: recovery step %d must keep %s powered off" % [step + 1, waiting_id]
			)

	# A broken machine is skipped: the charged network cannot power it on.
	var o2: MachineState = _machine_of(state, SimState.MACHINE_O2_SYSTEM)
	o2.health = 0.0
	o2.powered = false
	state.set_battery_charge(SimState.DEFAULT_BATTERY_ID, capacity)
	SimTick.step(state, economy, machines)
	_expect(
		not o2.powered,
		"o: a broken O2 system must stay off while the network has charge"
	)

	# Repairing it puts it back inside the recovery order: O2 comes first again.
	o2.health = MachineState.MAX_HEALTH
	state.set_battery_charge(SimState.DEFAULT_BATTERY_ID, capacity)
	SimTick.step(state, economy, machines)
	_expect(o2.powered, "o: a repaired O2 system must power on again")

	# A network that stays at zero charge powers nothing on.
	state.tick = 12
	state.set_battery_charge(SimState.DEFAULT_BATTERY_ID, 0.0)
	for id: StringName in BLACKOUT_EXPECTED_ORDER:
		_machine_of(state, id).powered = false
	SimTick.step(state, economy, machines)
	for id: StringName in BLACKOUT_EXPECTED_ORDER:
		_expect(
			not _machine_of(state, id).powered,
			"o: a network at zero charge must not power on %s" % id
		)
	print(
		"sim_smoke: o) recovery=%s capacity=%.2f energy=%.2f"
		% [str(recovery_order), capacity, state.get_energy_total()]
	)


## (e) Radiation only accumulates outside, caps max_health and finally kills.
func _check_radiation(economy: EconomyData, machines: MachineDatabase) -> void:
	var state: SimState = _fresh_state(economy)
	_power_off_all(state)
	state.is_outside = false
	for i: int in range(5):
		SimTick.step(state, economy, machines)
	_expect(
		state.radiation_dose == 0.0,
		"e: inside the shelter the dose must stay 0 (got %f)" % state.radiation_dose
	)

	state.is_outside = true
	for i: int in range(5):
		SimTick.step(state, economy, machines)
	_expect(
		is_equal_approx(state.radiation_dose, 6.0),
		"e: 5 exterior steps (1.2 each) must reach 6.0 dose (got %f)" % state.radiation_dose
	)

	state.is_outside = false
	for i: int in range(5):
		SimTick.step(state, economy, machines)
	_expect(
		is_equal_approx(state.radiation_dose, 6.0),
		"e: the dose must never decay (got %f)" % state.radiation_dose
	)

	state.radiation_dose = 50.0
	state.max_health = 100.0
	state.health = 100.0
	SimTick.step(state, economy, machines)
	_expect(
		is_equal_approx(state.max_health, 30.0),
		"e: above the cap threshold max_health must be 30 (got %f)" % state.max_health
	)
	_expect(
		state.health <= 30.0,
		"e: health must be clamped to the capped max_health (got %f)" % state.health
	)

	# Keep the crew artificially healthy so the dose can reach the death
	# threshold: the cap damage would otherwise end the run first.
	state.is_outside = true
	var guard: int = 0
	while not state.game_over and guard < GUARD_STEPS:
		state.health = 100.0
		SimTick.step(state, economy, machines)
		guard += 1
	_expect(state.game_over, "e: staying outside must end the run")
	_expect(
		state.radiation_dose >= 100.0,
		"e: the death threshold must be reached (dose %f)" % state.radiation_dose
	)
	_expect(
		state.death_cause == &"radiation",
		"e: death cause must be radiation (got %s)" % state.death_cause
	)
	print(
		"sim_smoke: e) dose=%.2f max_health=%.2f health=%.2f cause=%s"
		% [state.radiation_dose, state.max_health, state.health, str(state.death_cause)]
	)


## (f) get_summary() aggregates the facts of a radiation death run.
func _check_summary_counters(economy: EconomyData, machines: MachineDatabase) -> void:
	var state: SimState = _fresh_state(economy)
	var ledger: EventLogScript = EventLogScript.new()
	state.is_outside = true
	var steps: int = 0
	while not state.game_over and steps < GUARD_STEPS:
		ledger.log_entries(SimTick.step(state, economy, machines))
		steps += 1
	_expect(state.game_over, "f: staying outside must end the run")
	_expect(
		state.death_cause == &"radiation",
		"f: death cause must be radiation (got %s)" % state.death_cause
	)

	var summary: EvaluationSummary = ledger.get_summary()
	_expect(
		summary.sols_elapsed == ledger.get_count(LogEntry.Type.SOL_COMPLETED),
		"f: sols_elapsed must count SOL_COMPLETED (got %d)"
		% summary.sols_elapsed
	)
	_expect(
		is_equal_approx(summary.peak_radiation, state.radiation_dose),
		"f: peak_radiation must be the highest dose (%f != %f)"
		% [summary.peak_radiation, state.radiation_dose]
	)

	var game_over_entries: Array[LogEntry] = ledger.get_entries_by_type(LogEntry.Type.GAME_OVER)
	_expect(game_over_entries.size() == 1, "f: exactly one GAME_OVER must be logged")
	var expected_resources: Dictionary[StringName, float] = {}
	if not game_over_entries.is_empty():
		expected_resources = _resources_from_payload(game_over_entries[0].payload)
	_expect(
		summary.final_resources == expected_resources,
		"f: final_resources must match the GAME_OVER payload (%s != %s)"
		% [str(summary.final_resources), str(expected_resources)]
	)
	_expect(
		summary.final_resources == state.resources,
		"f: final_resources must match the state at game over"
	)
	_expect(
		summary.reports_sent == 0
		and summary.submissions_completed == 0
		and summary.shelter_uses == 0,
		"f: a plain run must not count reports, submissions or shelter uses"
	)

	for i: int in range(2):
		ledger.log_entry(LogEntry.new(LogEntry.Type.REPORT_SENT, state.tick, {}))
	ledger.log_entry(LogEntry.new(LogEntry.Type.SUBMISSION_COMPLETED, state.tick, {}))
	for i: int in range(2):
		ledger.log_entry(LogEntry.new(LogEntry.Type.SHELTER_USED, state.tick, {}))
	var updated: EvaluationSummary = ledger.get_summary()
	_expect(
		updated.reports_sent == 2,
		"f: reports_sent must be 2 (got %d)" % updated.reports_sent
	)
	_expect(
		updated.submissions_completed == 1,
		"f: submissions_completed must be 1 (got %d)" % updated.submissions_completed
	)
	_expect(
		updated.shelter_uses == 2,
		"f: shelter_uses must be 2 (got %d)" % updated.shelter_uses
	)
	print(
		"sim_smoke: f) steps=%d sols=%d peak=%.2f entries=%d"
		% [steps, summary.sols_elapsed, summary.peak_radiation, ledger.get_entries().size()]
	)
	ledger.free()


## (i) Power grid: default single network, panel without battery and a cut cable.
func _check_power_grid(economy: EconomyData, machines: MachineDatabase) -> void:
	var state: SimState = _fresh_state(economy)
	var networks: Array[PowerNetwork] = PowerGrid.build(state)
	_expect(networks.size() == 1, "i: the default base must be one network (got %d)" % networks.size())
	if not networks.is_empty():
		_expect(
			networks[0].batteries.has(SimState.DEFAULT_BATTERY_ID),
			"i: the default network must contain the installed battery"
		)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), state.get_energy_total()),
		"i: the energy mirror must equal the battery total"
	)

	# Panel wired to a load but with no battery: production is discarded.
	var no_battery: SimState = _fresh_state(economy)
	no_battery.batteries.clear()
	no_battery.power_links.append(
		PowerLink.new(SimState.MACHINE_SOLAR_ARRAY, SimState.MACHINE_LIGHTS)
	)
	no_battery.tick = 0
	SimTick.step(no_battery, economy, machines)
	_expect(
		is_equal_approx(no_battery.get_energy_total(), 0.0),
		"i: a panel without a battery must store nothing (got %f)"
		% no_battery.get_energy_total()
	)

	# Cut cable: battery_1 powers only the lights, battery_2 only hydroponics.
	var cut: SimState = _fresh_state(economy)
	cut.batteries.clear()
	cut.add_battery(&"battery_1")
	cut.add_battery(&"battery_2")
	cut.set_battery_charge(&"battery_1", 0.0)
	cut.set_battery_charge(&"battery_2", 10.0)
	cut.power_links.clear()
	cut.power_links.append(PowerLink.new(SimState.MACHINE_LIGHTS, &"battery_1"))
	cut.power_links.append(PowerLink.new(SimState.MACHINE_HYDROPONICS, &"battery_2"))
	cut.tick = 12
	var cut_networks: Array[PowerNetwork] = PowerGrid.build(cut)
	_expect(
		cut_networks.size() >= 2,
		"i: a cut cable must split the grid (got %d networks)" % cut_networks.size()
	)
	SimTick.step(cut, economy, machines)
	_expect(
		not _machine_of(cut, SimState.MACHINE_LIGHTS).powered,
		"i: the lights on the empty battery network must power off"
	)
	_expect(
		_machine_of(cut, SimState.MACHINE_HYDROPONICS).powered,
		"i: hydroponics on the charged battery network must stay on"
	)
	_expect(
		is_equal_approx(cut.get_resource(SimState.ENERGY), cut.get_energy_total()),
		"i: the energy mirror must track both batteries after a tick"
	)
	print(
		"sim_smoke: i) default=1 cut=%d energy=%.2f battery=%.2f"
		% [cut_networks.size(), cut.get_resource(SimState.ENERGY), cut.get_energy_total()]
	)


## (j) The shielded suit multiplies the exterior radiation gain.
func _check_suit_shield(economy: EconomyData, machines: MachineDatabase) -> void:
	var per_tick: float = economy.get_value(&"radiation_per_tick_exterior", 0.0)
	var multiplier: float = economy.get_value(&"suit_v2_radiation_multiplier", 1.0)
	_expect(multiplier < 1.0, "j: the shield row must reduce the dose (got %f)" % multiplier)

	var basic: SimState = _fresh_state(economy)
	_power_off_all(basic)
	basic.is_outside = true
	basic.suit_level = 0
	for i: int in range(2):
		SimTick.step(basic, economy, machines)
	_expect(
		is_equal_approx(basic.radiation_dose, per_tick * 2.0),
		"j: the basic suit must take the full dose (got %f, expected %f)"
		% [basic.radiation_dose, per_tick * 2.0]
	)

	var shielded: SimState = _fresh_state(economy)
	_power_off_all(shielded)
	shielded.is_outside = true
	shielded.suit_level = 1
	for i: int in range(2):
		SimTick.step(shielded, economy, machines)
	_expect(
		is_equal_approx(shielded.radiation_dose, per_tick * 2.0 * multiplier),
		"j: the shielded suit must take %f (got %f)"
		% [per_tick * 2.0 * multiplier, shielded.radiation_dose]
	)
	print(
		"sim_smoke: j) basic=%.2f shielded=%.2f multiplier=%.2f"
		% [basic.radiation_dose, shielded.radiation_dose, multiplier]
	)


## Fresh state seeded from the economy database.
func _fresh_state(economy: EconomyData) -> SimState:
	var state: SimState = SimState.new()
	state.reset_from_economy(economy)
	return state


## Machine state by id; the caller guarantees the machine exists.
func _machine_of(state: SimState, id: StringName) -> MachineState:
	var machine: MachineState = state.machines[id]
	return machine


## Energy the machine sheet declares per tick; 0 when there is no energy entry.
func _machine_energy_draw(machines: MachineDatabase, id: StringName) -> float:
	var data: MachineData = machines.get_machine(id)
	if data == null:
		return 0.0
	var total: float = 0.0
	for entry: MachineConsumption in data.consumption:
		if entry != null and entry.resource == SimState.ENERGY:
			total += entry.amount_per_tick
	return total


func _power_off_all(state: SimState) -> void:
	for id: StringName in SimState.MACHINE_IDS:
		_machine_of(state, id).powered = false


func _count_facts(entries: Array[LogEntry], type: LogEntry.Type) -> int:
	var count: int = 0
	for entry: LogEntry in entries:
		if entry.type == type:
			count += 1
	return count


## Facts of one type, in emission order.
func _facts_of_type(entries: Array[LogEntry], type: LogEntry.Type) -> Array[LogEntry]:
	var result: Array[LogEntry] = []
	for entry: LogEntry in entries:
		if entry.type == type:
			result.append(entry)
	return result


## Comparable list of the (type, tick, payload) tuples of a fact sequence.
func _fact_signature(entries: Array[LogEntry]) -> Array[String]:
	var signature: Array[String] = []
	for entry: LogEntry in entries:
		signature.append("%d@%d:%s" % [entry.type, entry.tick, str(entry.payload)])
	return signature


## Rekeys a GAME_OVER resources payload as a typed StringName -> float map.
func _resources_from_payload(payload: Dictionary[Variant, Variant]) -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {}
	var raw: Variant = payload.get(&"resources")
	if typeof(raw) != TYPE_DICTIONARY:
		return result
	var raw_dict: Dictionary[Variant, Variant] = raw
	for key: Variant in raw_dict.keys():
		if typeof(key) != TYPE_STRING_NAME:
			continue
		var key_name: StringName = key
		var value: Variant = raw_dict[key]
		if typeof(value) == TYPE_FLOAT:
			var value_float: float = value
			result[key_name] = value_float
	return result


## (g) The sol length follows the economy rows instead of a hardcoded constant.
func _check_sol_from_economy(machines: MachineDatabase) -> void:
	var economy: EconomyData = EconomyData.new()
	economy.rows.append(_row(&"day_length_ticks", 6.0))
	economy.rows.append(_row(&"night_length_ticks", 6.0))
	var state: SimState = _fresh_state(economy)
	_expect(
		state.get_sol_length(economy) == 12,
		"g: sol length must be day + night (got %d)" % state.get_sol_length(economy)
	)

	var sols: Array[int] = []
	for i: int in range(12):
		for fact: LogEntry in SimTick.step(state, economy, machines):
			if fact.type == LogEntry.Type.SOL_COMPLETED:
				sols.append(int(fact.payload.get(&"sol")))
	_expect(sols == [1], "g: 12 ticks must close exactly sol 1 (got %s)" % str(sols))

	for i: int in range(12):
		for fact: LogEntry in SimTick.step(state, economy, machines):
			if fact.type == LogEntry.Type.SOL_COMPLETED:
				sols.append(int(fact.payload.get(&"sol")))
	_expect(sols == [1, 2], "g: 24 ticks must close sols 1 and 2 (got %s)" % str(sols))
	print("sim_smoke: g) sol_length=12 sols=%s" % str(sols))


## (h) An out-of-range row yields the fallback instead of a clamped value.
func _check_economy_fallback() -> void:
	var economy: EconomyData = EconomyData.new()
	economy.rows.append(_row(&"solar_output_per_tick", 500.0))
	_expect(
		is_equal_approx(economy.get_value(&"solar_output_per_tick", 1.5), 1.5),
		"h: an out-of-range row must yield the fallback (got %f)"
		% economy.get_value(&"solar_output_per_tick", 1.5)
	)
	_expect(
		is_equal_approx(economy.get_value(&"missing_row", 2.5), 2.5),
		"h: a missing row must yield the fallback (got %f)"
		% economy.get_value(&"missing_row", 2.5)
	)
	print("sim_smoke: h) out-of-range and missing rows fall back")


## Synthetic economy that keeps the crew alive for a whole mission: mission
## clock, sol length and full tanks, with no consumption, production,
## degradation, radiation or event rows.
func _safe_economy(mission_ticks: int) -> EconomyData:
	var economy: EconomyData = EconomyData.new()
	economy.rows.append(_row_with_max(&"mission_length_ticks", float(mission_ticks), 1000.0))
	economy.rows.append(_row_with_max(&"day_length_ticks", 12.0, 100.0))
	economy.rows.append(_row_with_max(&"night_length_ticks", 12.0, 100.0))
	economy.rows.append(_row_with_max(&"initial_health", 100.0, 100.0))
	economy.rows.append(_row_with_max(&"max_health", 100.0, 100.0))
	economy.rows.append(_row_with_max(&"initial_oxygen", 100.0, 100.0))
	economy.rows.append(_row_with_max(&"capacity_oxygen", 100.0, 100.0))
	economy.rows.append(_row_with_max(&"initial_water", 100.0, 100.0))
	economy.rows.append(_row_with_max(&"capacity_water", 100.0, 100.0))
	economy.rows.append(_row_with_max(&"initial_food", 100.0, 100.0))
	economy.rows.append(_row_with_max(&"capacity_food", 100.0, 100.0))
	economy.rows.append(_row_with_max(&"initial_energy", 100.0, 100.0))
	economy.rows.append(_row_with_max(&"capacity_energy", 100.0, 100.0))
	return economy


## Economy row with 100 as its upper bound.
func _row(id: StringName, value: float) -> EconomyRow:
	var row: EconomyRow = EconomyRow.new()
	row.id = id
	row.value = value
	row.max_value = 100.0
	return row


## Economy row with an explicit upper bound; the lower bound stays at 0.
func _row_with_max(id: StringName, value: float, max_value: float) -> EconomyRow:
	var row: EconomyRow = EconomyRow.new()
	row.id = id
	row.value = value
	row.max_value = max_value
	return row


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		return
	_failures += 1
	push_error("sim_smoke FAILED: " + message)
