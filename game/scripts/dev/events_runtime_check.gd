extends SceneTree

## Runtime checks for the event scheduler and its effects.
## Run: godot --headless --path game --script res://scripts/dev/events_runtime_check.gd
## Exit code 0 when every check passes, 1 otherwise.

const ECONOMY_PATH: String = "res://databases/economy.tres"
const MACHINES_PATH: String = "res://databases/machines.tres"
const EVENTS_PATH: String = "res://databases/events.tres"

var _checks: int = 0
var _failures: int = 0
var _machines: MachineDatabase = null


func _init() -> void:
	var economy: EconomyData = ResourceLoader.load(ECONOMY_PATH) as EconomyData
	if economy == null:
		push_error("events_runtime_check: cannot load %s" % ECONOMY_PATH)
		quit(1)
		return
	_machines = ResourceLoader.load(MACHINES_PATH) as MachineDatabase
	if _machines == null:
		push_error("events_runtime_check: cannot load %s" % MACHINES_PATH)
		quit(1)
		return
	var events: EventData = ResourceLoader.load(EVENTS_PATH) as EventData
	if events == null:
		push_error("events_runtime_check: cannot load %s" % EVENTS_PATH)
		quit(1)
		return

	_check_radiation_window(economy, events)
	_check_machine_breakdown(economy, events)
	_check_production_and_consumption(economy, events)
	_check_comms_blackout(economy, events)
	_check_overlap_queue(economy)
	_check_determinism(economy, events)
	_check_reset(economy, events)

	print(
		"events_runtime_check: %d checks, %s"
		% [_checks, "FAIL" if _failures > 0 else "OK"]
	)
	quit(1 if _failures > 0 else 0)


func _check_radiation_window(economy: EconomyData, events: EventData) -> void:
	var outside: SimState = _fresh_state(economy)
	outside.is_outside = true
	var outside_facts: Array[LogEntry] = _step_n(outside, economy, events, 10)
	var start_tick: int = _fact_tick(outside_facts, LogEntry.Type.EVENT_STARTED, &"radiation_window_01")
	var end_tick: int = _fact_tick(outside_facts, LogEntry.Type.EVENT_ENDED, &"radiation_window_01")
	_expect(start_tick == 3, "radiation window must start at tick 3 (got %d)" % start_tick)
	_expect(end_tick == 9, "radiation window must end at tick 9 (got %d)" % end_tick)
	_expect(
		outside.radiation_dose > 10.0,
		"outside dose must include the radiation window (got %.2f)" % outside.radiation_dose
	)

	var inside: SimState = _fresh_state(economy)
	inside.is_outside = false
	_step_n(inside, economy, events, 10)
	_expect(
		is_zero_approx(inside.radiation_dose),
		"inside dose must stay at zero (got %.2f)" % inside.radiation_dose
	)


func _check_machine_breakdown(economy: EconomyData, events: EventData) -> void:
	var with_events: SimState = _fresh_state(economy)
	var without_events: SimState = _fresh_state(economy)
	var facts: Array[LogEntry] = _step_n(with_events, economy, events, 12)
	_step_n(without_events, economy, null, 12)

	var start_tick: int = _fact_tick(facts, LogEntry.Type.EVENT_STARTED, &"machine_breakdown_01")
	_expect(start_tick == 8, "machine breakdown must start at tick 8 (got %d)" % start_tick)
	var with_health: float = with_events.machines[SimState.MACHINE_WATER_RECYCLER].health
	var without_health: float = without_events.machines[SimState.MACHINE_WATER_RECYCLER].health
	_expect(
		with_health < without_health,
		"event must damage the water recycler (%.2f vs %.2f)" % [with_health, without_health]
	)


func _check_production_and_consumption(economy: EconomyData, events: EventData) -> void:
	var with_events: SimState = _fresh_state(economy)
	var without_events: SimState = _fresh_state(economy)
	_step_n(with_events, economy, events, 20)
	_step_n(without_events, economy, null, 20)

	var with_food: float = with_events.get_resource(SimState.FOOD)
	var without_food: float = without_events.get_resource(SimState.FOOD)
	_expect(
		with_food < without_food,
		"production drop must lower food (%.3f vs %.3f)" % [with_food, without_food]
	)

	var with_water: float = with_events.get_resource(SimState.WATER)
	var without_water: float = without_events.get_resource(SimState.WATER)
	_expect(
		with_water < without_water,
		"consumption spike must lower water (%.3f vs %.3f)" % [with_water, without_water]
	)


func _check_comms_blackout(economy: EconomyData, events: EventData) -> void:
	var state: SimState = _fresh_state(economy)
	var before: Array[LogEntry] = _step_n(state, economy, events, 20)
	_expect(not state.comms_blocked, "comms must be open before tick 20")
	_expect(
		_fact_tick(before, LogEntry.Type.EVENT_STARTED, &"comms_blackout_01") == -1,
		"comms blackout must not start before tick 20"
	)

	_step_n(state, economy, events, 1)
	_expect(state.comms_blocked, "comms must be blocked at tick 20")

	_step_n(state, economy, events, 6)
	_expect(not state.comms_blocked, "comms must reopen after the blackout ends")


func _check_overlap_queue(economy: EconomyData) -> void:
	var first: EventRow = _synthetic_breakdown(&"queue_a", 0)
	var second: EventRow = _synthetic_breakdown(&"queue_b", 0)
	first.overlap_policy = EventRow.OverlapPolicy.EXCLUSIVE
	second.overlap_policy = EventRow.OverlapPolicy.EXCLUSIVE
	first.delay_min_ticks = 1
	first.delay_max_ticks = 1
	second.delay_min_ticks = 1
	second.delay_max_ticks = 1

	var events: EventData = EventData.new()
	var rows: Array[EventRow] = [first, second]
	events.rows = rows

	var state: SimState = _fresh_state(economy)
	var facts: Array[LogEntry] = _step_n(state, economy, events, 5)
	var first_tick: int = _fact_tick(facts, LogEntry.Type.EVENT_STARTED, &"queue_a")
	var second_tick: int = _fact_tick(facts, LogEntry.Type.EVENT_STARTED, &"queue_b")
	_expect(first_tick == 0, "first exclusive event must start at tick 0 (got %d)" % first_tick)
	_expect(
		second_tick == 3,
		"blocked exclusive event must wait until tick 3 (got %d)" % second_tick
	)


func _check_determinism(economy: EconomyData, events: EventData) -> void:
	var first: SimState = _fresh_state(economy)
	var second: SimState = _fresh_state(economy)
	first.is_outside = true
	second.is_outside = true
	var first_facts: Array[LogEntry] = _step_n(first, economy, events, 30)
	var second_facts: Array[LogEntry] = _step_n(second, economy, events, 30)

	_expect(first.tick == second.tick, "both runs must end at the same tick")
	_expect(_fact_signature(first_facts) == _fact_signature(second_facts), "fact sequence must match")
	for id: StringName in [SimState.OXYGEN, SimState.WATER, SimState.FOOD, SimState.ENERGY]:
		_expect(
			is_equal_approx(first.get_resource(id), second.get_resource(id)),
			"resource '%s' must match" % String(id)
		)
	_expect(
		is_equal_approx(first.radiation_dose, second.radiation_dose),
		"radiation dose must match"
	)
	_expect(
		is_equal_approx(
			first.machines[SimState.MACHINE_WATER_RECYCLER].health,
			second.machines[SimState.MACHINE_WATER_RECYCLER].health
		),
		"water recycler health must match"
	)


func _check_reset(economy: EconomyData, events: EventData) -> void:
	var state: SimState = _fresh_state(economy)
	_step_n(state, economy, events, 4)
	_expect(state.event_cursor > 0, "event cursor must advance during a run")
	state.reset_from_economy(economy)
	_expect(state.event_cursor == 0, "reset must rewind the event cursor")
	_expect(state.active_events.is_empty(), "reset must clear active events")
	_expect(state.pending_events.is_empty(), "reset must clear pending events")
	_expect(not state.comms_blocked, "reset must reopen comms")


func _synthetic_breakdown(row_id: StringName, onset_tick: int) -> EventRow:
	var row: EventRow = EventRow.new()
	row.id = row_id
	row.archetype = EventRow.Archetype.MACHINE_BREAKDOWN
	row.target_type = EventRow.TargetType.MACHINE
	row.target_id = SimState.MACHINE_WATER_RECYCLER
	row.onset_tick = onset_tick
	row.duration_ticks = 2
	row.intensity_start = -1.0
	row.intensity_peak = -1.0
	row.intensity_end = -1.0
	return row


func _fresh_state(economy: EconomyData) -> SimState:
	var state: SimState = SimState.new()
	state.reset_from_economy(economy)
	return state


func _step_n(
	state: SimState,
	economy: EconomyData,
	events: EventData,
	count: int
) -> Array[LogEntry]:
	var facts: Array[LogEntry] = []
	for step_index: int in range(count):
		facts.append_array(SimTick.step(state, economy, _machines, events))
	return facts


## Tick of the first STARTED/ENDED fact with the given event id, or -1.
func _fact_tick(facts: Array[LogEntry], type: LogEntry.Type, event_id: StringName) -> int:
	for fact: LogEntry in facts:
		if fact.type != type:
			continue
		var raw_id: Variant = fact.payload.get(&"id")
		if typeof(raw_id) == TYPE_STRING_NAME and raw_id == event_id:
			return fact.tick
	return -1


func _fact_signature(facts: Array[LogEntry]) -> Array[String]:
	var signature: Array[String] = []
	for fact: LogEntry in facts:
		signature.append("%d@%d" % [fact.type, fact.tick])
	return signature


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		return
	_failures += 1
	push_error("events_runtime_check FAILED: " + message)
