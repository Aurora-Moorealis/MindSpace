extends SceneTree

## Headless validator for the events registry and its schedule data.
## Run: godot --headless --path game --script res://scripts/dev/events_check.gd
## Exit code 0 when every check passes, 1 otherwise.

const EVENTS_PATH: String = "res://databases/events.tres"
const EXPECTED_ROWS: int = 5
const MISSION_TICKS: int = 300
const CORE_RESOURCES: Array[StringName] = [
	SimState.OXYGEN,
	SimState.WATER,
	SimState.FOOD,
	SimState.ENERGY,
]

var _checks: int = 0
var _failures: int = 0


func _init() -> void:
	var events: EventData = ResourceLoader.load(EVENTS_PATH) as EventData
	if events == null:
		push_error("events_check: cannot load %s as EventData" % EVENTS_PATH)
		quit(1)
		return

	_check_registry(events)
	_check_archetypes(events)
	_check_targets(events)
	_check_schedule(events)
	_check_overlap(events)
	_check_intensity(events)
	_check_provenance(events)
	_check_rejects_invalid_rows()
	_check_rejects_late_window()

	print(
		"events_check: %d checks, %s"
		% [_checks, "FAIL" if _failures > 0 else "OK"]
	)
	quit(1 if _failures > 0 else 0)


func _check_registry(events: EventData) -> void:
	_expect(
		events.rows.size() == EXPECTED_ROWS,
		"registry must have %d rows (got %d)" % [EXPECTED_ROWS, events.rows.size()]
	)
	var errors: Array[String] = events.validate_rows()
	for message: String in errors:
		push_error("events_check: validation: " + message)
	_expect(errors.is_empty(), "registry validation must be empty (%d problems)" % errors.size())

	var seen: Dictionary[StringName, int] = {}
	for row: EventRow in events.rows:
		var is_new: bool = not seen.has(row.id)
		_expect(is_new, "id '%s' must be unique" % String(row.id))
		seen[row.id] = 1
		_expect(
			events.get_row(row.id) == row,
			"get_row('%s') must return the same row" % String(row.id)
		)

	for machine_id: StringName in SimState.MACHINE_IDS:
		_expect(
			EventRow.MACHINE_IDS.has(machine_id),
			"EventRow.MACHINE_IDS is missing '%s'" % String(machine_id)
		)
	for resource_id: StringName in CORE_RESOURCES:
		_expect(
			EventRow.RESOURCE_IDS.has(resource_id),
			"EventRow.RESOURCE_IDS is missing '%s'" % String(resource_id)
		)
	_expect(
		EventRow.RADIATION_ID == &"radiation",
		"RADIATION_ID must be 'radiation'"
	)


func _check_archetypes(events: EventData) -> void:
	_expect(
		events.get_rows_by_archetype(EventRow.Archetype.MACHINE_BREAKDOWN).size() == 1,
		"exactly one machine breakdown row"
	)
	_expect(
		events.get_rows_by_archetype(EventRow.Archetype.PRODUCTION_DROP).size() == 1,
		"exactly one production drop row"
	)
	_expect(
		events.get_rows_by_archetype(EventRow.Archetype.CONSUMPTION_SPIKE).size() == 1,
		"exactly one consumption spike row"
	)
	_expect(
		events.get_rows_by_archetype(EventRow.Archetype.RADIATION_WINDOW).size() == 1,
		"exactly one radiation window row"
	)
	_expect(
		events.get_rows_by_archetype(EventRow.Archetype.COMMS_BLACKOUT).size() == 1,
		"exactly one comms blackout row"
	)

	var radiation: EventRow = _require_row(events, &"radiation_window_01")
	if radiation != null:
		_expect(
			radiation.archetype == EventRow.Archetype.RADIATION_WINDOW,
			"radiation_window_01 must be a radiation window"
		)
		_expect(radiation.onset_tick == 3, "first radiation window must start at tick 3")

	var breakdown: EventRow = _require_row(events, &"machine_breakdown_01")
	if breakdown != null:
		_expect(
			breakdown.archetype == EventRow.Archetype.MACHINE_BREAKDOWN,
			"machine_breakdown_01 must be a machine breakdown"
		)

	var production: EventRow = _require_row(events, &"production_drop_01")
	if production != null:
		_expect(
			production.archetype == EventRow.Archetype.PRODUCTION_DROP,
			"production_drop_01 must be a production drop"
		)

	var consumption: EventRow = _require_row(events, &"consumption_spike_01")
	if consumption != null:
		_expect(
			consumption.archetype == EventRow.Archetype.CONSUMPTION_SPIKE,
			"consumption_spike_01 must be a consumption spike"
		)

	var comms: EventRow = _require_row(events, &"comms_blackout_01")
	if comms != null:
		_expect(
			comms.archetype == EventRow.Archetype.COMMS_BLACKOUT,
			"comms_blackout_01 must be a comms blackout"
		)


func _check_targets(events: EventData) -> void:
	for row: EventRow in events.rows:
		match row.archetype:
			EventRow.Archetype.MACHINE_BREAKDOWN:
				_expect(
					row.target_type == EventRow.TargetType.MACHINE,
					"'%s' must target a machine" % String(row.id)
				)
				_expect(
					SimState.MACHINE_IDS.has(row.target_id),
					"'%s' targets unknown machine '%s'"
					% [String(row.id), String(row.target_id)]
				)
			EventRow.Archetype.PRODUCTION_DROP, EventRow.Archetype.CONSUMPTION_SPIKE:
				_expect(
					row.target_type == EventRow.TargetType.RESOURCE,
					"'%s' must target a resource" % String(row.id)
				)
				_expect(
					CORE_RESOURCES.has(row.target_id),
					"'%s' targets non-core resource '%s'"
					% [String(row.id), String(row.target_id)]
				)
			EventRow.Archetype.RADIATION_WINDOW:
				_expect(
					row.target_type == EventRow.TargetType.RESOURCE,
					"'%s' must target the radiation pseudo-resource" % String(row.id)
				)
				_expect(
					row.target_id == EventRow.RADIATION_ID,
					"'%s' must target 'radiation'" % String(row.id)
				)
			EventRow.Archetype.COMMS_BLACKOUT:
				_expect(
					row.target_type == EventRow.TargetType.NONE,
					"'%s' must have no target" % String(row.id)
				)
				_expect(
					row.target_id == &"",
					"'%s' must have an empty target_id" % String(row.id)
				)
				_expect(
					is_zero_approx(row.intensity_start)
					and is_zero_approx(row.intensity_peak)
					and is_zero_approx(row.intensity_end),
					"'%s' must have zero intensity" % String(row.id)
				)


func _check_schedule(events: EventData) -> void:
	for row: EventRow in events.rows:
		_expect(row.onset_tick >= 0, "'%s' onset must be >= 0" % String(row.id))
		_expect(row.duration_ticks >= 1, "'%s' duration must be >= 1" % String(row.id))
		_expect(
			row.delay_max_ticks >= row.delay_min_ticks,
			"'%s' delay_max must be >= delay_min" % String(row.id)
		)
		_expect(
			row.end_tick() <= MISSION_TICKS,
			"'%s' must end within the 300-tick mission" % String(row.id)
		)

	var radiation: EventRow = events.get_row(&"radiation_window_01")
	if radiation == null:
		return
	_expect(radiation.end_tick() == 9, "radiation_window_01 must end at tick 9")
	_expect(not radiation.is_active_at(2), "radiation_window_01 is not active at tick 2")
	_expect(radiation.is_active_at(3), "radiation_window_01 is active at tick 3")
	_expect(radiation.is_active_at(8), "radiation_window_01 is active at tick 8")
	_expect(not radiation.is_active_at(9), "radiation_window_01 is not active at tick 9")


func _check_overlap(events: EventData) -> void:
	var radiation: EventRow = _require_row(events, &"radiation_window_01")
	var breakdown: EventRow = _require_row(events, &"machine_breakdown_01")
	var production: EventRow = _require_row(events, &"production_drop_01")
	var consumption: EventRow = _require_row(events, &"consumption_spike_01")
	var comms: EventRow = _require_row(events, &"comms_blackout_01")
	if (
		radiation == null
		or breakdown == null
		or production == null
		or consumption == null
		or comms == null
	):
		return

	_expect(
		events.can_overlap(radiation, breakdown),
		"radiation and breakdown must overlap"
	)
	_expect(
		events.can_overlap(breakdown, radiation),
		"overlap must be symmetric"
	)
	_expect(
		events.can_overlap(production, consumption),
		"production drop and consumption spike must overlap"
	)
	_expect(
		not events.can_overlap(radiation, production),
		"radiation and production drop must not overlap"
	)
	_expect(
		not events.can_overlap(radiation, comms),
		"radiation and comms blackout must not overlap"
	)
	_expect(not events.can_overlap(radiation, radiation), "a row cannot overlap itself")

	var any_a: EventRow = _synthetic_row(&"any_a", EventRow.OverlapPolicy.ANY)
	var any_b: EventRow = _synthetic_row(&"any_b", EventRow.OverlapPolicy.ANY)
	var exclusive: EventRow = _synthetic_row(&"exclusive", EventRow.OverlapPolicy.EXCLUSIVE)
	var whitelist_a: EventRow = _synthetic_row(
		&"whitelist_a", EventRow.OverlapPolicy.WHITELIST
	)
	var whitelist_b: EventRow = _synthetic_row(
		&"whitelist_b", EventRow.OverlapPolicy.WHITELIST
	)
	whitelist_a.overlap_with = [&"whitelist_b"]
	whitelist_b.overlap_with = [&"whitelist_a"]

	var synthetic: EventData = EventData.new()
	synthetic.rows = [any_a, any_b, exclusive, whitelist_a, whitelist_b]

	_expect(synthetic.can_overlap(any_a, any_b), "ANY + ANY must overlap")
	_expect(not synthetic.can_overlap(any_a, exclusive), "EXCLUSIVE must veto overlap")
	_expect(
		not synthetic.can_overlap(any_a, whitelist_a),
		"ANY still needs the WHITELIST side to accept"
	)
	_expect(
		synthetic.can_overlap(whitelist_a, whitelist_b),
		"mutual WHITELIST must overlap"
	)

	whitelist_a.overlap_with = []
	_expect(
		not synthetic.can_overlap(whitelist_a, whitelist_b),
		"one-sided WHITELIST must not overlap"
	)


func _check_intensity(events: EventData) -> void:
	var radiation: EventRow = events.get_row(&"radiation_window_01")
	if radiation != null:
		_expect(
			is_equal_approx(radiation.intensity_at(0), 0.2),
			"radiation intensity at tick 0 must be 0.2"
		)
		_expect(
			is_equal_approx(radiation.intensity_at(3), 0.8),
			"radiation peak must be sampled at tick 3"
		)
		_expect(
			is_equal_approx(radiation.intensity_at(5), 0.2),
			"radiation intensity at the last tick must be 0.2"
		)
		_expect(
			is_equal_approx(radiation.intensity_at(-1), 0.2),
			"negative elapsed ticks must clamp to start"
		)
		_expect(
			is_equal_approx(radiation.intensity_at(99), 0.2),
			"elapsed ticks past duration must clamp to end"
		)

	var breakdown: EventRow = events.get_row(&"machine_breakdown_01")
	if breakdown != null:
		_expect(
			is_equal_approx(breakdown.intensity_at(0), -0.5),
			"breakdown start must be -0.5"
		)
		_expect(
			is_equal_approx(breakdown.intensity_at(2), -2.0),
			"breakdown peak must be sampled at tick 2"
		)
		_expect(
			is_equal_approx(breakdown.intensity_at(3), -0.5),
			"breakdown end must be -0.5"
		)

	var one_tick: EventRow = _synthetic_row(&"one_tick", EventRow.OverlapPolicy.EXCLUSIVE)
	one_tick.duration_ticks = 1
	one_tick.intensity_start = 1.0
	one_tick.intensity_peak = 2.0
	one_tick.intensity_end = 3.0
	_expect(
		is_equal_approx(one_tick.intensity_at(0), 2.0),
		"a one-tick event must use its peak"
	)

	var two_ticks: EventRow = _synthetic_row(&"two_ticks", EventRow.OverlapPolicy.EXCLUSIVE)
	two_ticks.duration_ticks = 2
	two_ticks.intensity_start = 1.0
	two_ticks.intensity_peak = 2.0
	two_ticks.intensity_end = 3.0
	_expect(
		is_equal_approx(two_ticks.intensity_at(0), 1.0),
		"a two-tick event starts at start"
	)
	_expect(
		is_equal_approx(two_ticks.intensity_at(1), 3.0),
		"a two-tick event ends at end"
	)


func _check_provenance(events: EventData) -> void:
	for row: EventRow in events.rows:
		_expect(row.provenance != null, "'%s' must have provenance" % String(row.id))
		if row.provenance == null:
			continue
		_expect(
			events.get_provenance(row.id) == row.provenance,
			"'%s' provenance lookup mismatch" % String(row.id)
		)
		_expect(
			not row.provenance.real_data,
			"'%s' is still a placeholder (real_data must be false)" % String(row.id)
		)
		if row.provenance.real_data:
			_expect(
				not row.provenance.source.is_empty(),
				"'%s' real_data requires source" % String(row.id)
			)
			_expect(
				not row.provenance.date_archived.is_empty(),
				"'%s' real_data requires date_archived" % String(row.id)
			)


func _check_rejects_invalid_rows() -> void:
	var invalid: EventRow = EventRow.new()
	invalid.id = &"invalid_row"
	invalid.archetype = EventRow.Archetype.MACHINE_BREAKDOWN
	invalid.target_type = EventRow.TargetType.RESOURCE
	invalid.target_id = &"food"
	invalid.onset_tick = 0
	invalid.duration_ticks = 1
	invalid.intensity_start = 1.0
	invalid.intensity_peak = 1.0
	invalid.intensity_end = 1.0

	var invalid_data: EventData = EventData.new()
	invalid_data.rows = [invalid]
	var problems: Array[String] = invalid_data.validate_rows()
	_expect(
		not problems.is_empty(),
		"validator must reject a row with a wrong target, a positive breakdown delta and no provenance"
	)


func _check_rejects_late_window() -> void:
	var late: EventRow = EventRow.new()
	late.id = &"late_window"
	late.archetype = EventRow.Archetype.MACHINE_BREAKDOWN
	late.target_type = EventRow.TargetType.MACHINE
	late.target_id = &"water_recycler"
	late.onset_tick = EventData.MISSION_TICKS
	late.duration_ticks = 1
	late.intensity_start = -1.0
	late.intensity_peak = -1.0
	late.intensity_end = -1.0
	late.provenance = DataProvenance.new()

	var late_data: EventData = EventData.new()
	late_data.rows = [late]
	var problems: Array[String] = late_data.validate_rows()
	var mentions_mission_limit: bool = false
	for message: String in problems:
		if message.contains("300-tick mission"):
			mentions_mission_limit = true
			break
	_expect(
		mentions_mission_limit,
		"validator must reject a window that ends after the 300-tick mission"
	)


func _require_row(events: EventData, id: StringName) -> EventRow:
	var row: EventRow = events.get_row(id)
	_expect(row != null, "row '%s' must exist" % String(id))
	return row


func _synthetic_row(row_id: StringName, policy: EventRow.OverlapPolicy) -> EventRow:
	var row: EventRow = EventRow.new()
	row.id = row_id
	row.overlap_policy = policy
	return row


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		return
	_failures += 1
	push_error("events_check FAILED: " + message)
