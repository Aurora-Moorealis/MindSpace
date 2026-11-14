class_name EventData
extends Resource

## Registry of event rows, one row per external .tres file.
## Data only: it validates rows and answers overlap queries; it does not run
## events or mutate the simulation.

@export var rows: Array[EventRow] = []


## Row with the given id, or null when it does not exist.
func get_row(id: StringName) -> EventRow:
	for row: EventRow in rows:
		if row.id == id:
			return row
	return null


## Provenance of the row with the given id, or null when it does not exist.
func get_provenance(id: StringName) -> DataProvenance:
	var row: EventRow = get_row(id)
	if row == null:
		return null
	return row.provenance


## Rows of one archetype, in registry order.
func get_rows_by_archetype(archetype: EventRow.Archetype) -> Array[EventRow]:
	var result: Array[EventRow] = []
	for row: EventRow in rows:
		if row.archetype == archetype:
			result.append(row)
	return result


## Overlap requires mutual consent: an EXCLUSIVE row vetoes the pair, and a
## WHITELIST row has to name the other event. ANY means "I do not restrict",
## but the other row still has to accept this one.
func can_overlap(first: EventRow, second: EventRow) -> bool:
	if first == null or second == null:
		return false
	if first.id == second.id:
		return false
	return first.allows_overlap_with(second) and second.allows_overlap_with(first)


## Human-readable problems; empty array means the database is valid.
func validate_rows() -> Array[String]:
	var messages: Array[String] = []
	if rows.is_empty():
		messages.append("events database has no rows")
		return messages

	var seen_ids: Dictionary[StringName, int] = {}
	for index: int in rows.size():
		var row: EventRow = rows[index]
		if row == null:
			messages.append("row %d: is null" % index)
			continue
		var row_id: String = String(row.id)
		if row.id == &"":
			messages.append("row %d: id is empty" % index)
		if seen_ids.has(row.id):
			messages.append("row %d: id '%s' is duplicated" % [index, row_id])
		else:
			seen_ids[row.id] = 1
		_validate_schedule(row, index, row_id, messages)
		_validate_intensity(row, index, row_id, messages)
		_validate_target(row, index, row_id, messages)
		_validate_overlap_row(row, index, row_id, messages)
		_validate_provenance(row, index, row_id, messages)

	_validate_overlap_references(messages)
	return messages


func _validate_schedule(
	row: EventRow,
	index: int,
	row_id: String,
	messages: Array[String]
) -> void:
	if row.onset_tick < 0:
		messages.append("row %d ('%s'): onset_tick must be >= 0" % [index, row_id])
	if row.duration_ticks < 1:
		messages.append("row %d ('%s'): duration_ticks must be >= 1" % [index, row_id])
	if row.delay_min_ticks < 0:
		messages.append("row %d ('%s'): delay_min_ticks must be >= 0" % [index, row_id])
	if row.delay_max_ticks < row.delay_min_ticks:
		messages.append(
			"row %d ('%s'): delay_max_ticks must be >= delay_min_ticks"
			% [index, row_id]
		)


func _validate_intensity(
	row: EventRow,
	index: int,
	row_id: String,
	messages: Array[String]
) -> void:
	if not is_finite(row.intensity_start):
		messages.append("row %d ('%s'): intensity_start is not finite" % [index, row_id])
	if not is_finite(row.intensity_peak):
		messages.append("row %d ('%s'): intensity_peak is not finite" % [index, row_id])
	if not is_finite(row.intensity_end):
		messages.append("row %d ('%s'): intensity_end is not finite" % [index, row_id])


func _validate_target(
	row: EventRow,
	index: int,
	row_id: String,
	messages: Array[String]
) -> void:
	match row.archetype:
		EventRow.Archetype.MACHINE_BREAKDOWN:
			_require_target(
				row, index, row_id, EventRow.TargetType.MACHINE, messages
			)
			if not EventRow.MACHINE_IDS.has(row.target_id):
				messages.append(
					"row %d ('%s'): target_id '%s' is not a machine"
					% [index, row_id, String(row.target_id)]
				)
			if not _has_negative_delta(row):
				messages.append(
					"row %d ('%s'): machine breakdown needs a negative health delta"
					% [index, row_id]
				)
			if _has_positive_delta(row):
				messages.append(
					"row %d ('%s'): machine breakdown cannot heal a machine"
					% [index, row_id]
				)
		EventRow.Archetype.PRODUCTION_DROP, EventRow.Archetype.CONSUMPTION_SPIKE:
			_require_target(
				row, index, row_id, EventRow.TargetType.RESOURCE, messages
			)
			if not EventRow.RESOURCE_IDS.has(row.target_id):
				messages.append(
					"row %d ('%s'): target_id '%s' is not a core resource"
					% [index, row_id, String(row.target_id)]
				)
			if not _has_negative_delta(row):
				messages.append(
					"row %d ('%s'): production/consumption event needs a negative delta"
					% [index, row_id]
				)
			if _has_positive_delta(row):
				messages.append(
					"row %d ('%s'): production/consumption event cannot add resources"
					% [index, row_id]
				)
		EventRow.Archetype.RADIATION_WINDOW:
			_require_target(
				row, index, row_id, EventRow.TargetType.RESOURCE, messages
			)
			if row.target_id != EventRow.RADIATION_ID:
				messages.append(
					"row %d ('%s'): radiation window must target 'radiation'"
					% [index, row_id]
				)
			if _has_negative_delta(row):
				messages.append(
					"row %d ('%s'): radiation window cannot remove dose"
					% [index, row_id]
				)
			if not _has_positive_delta(row):
				messages.append(
					"row %d ('%s'): radiation window needs a positive dose delta"
					% [index, row_id]
				)
		EventRow.Archetype.COMMS_BLACKOUT:
			_require_target(row, index, row_id, EventRow.TargetType.NONE, messages)
			if row.target_id != &"":
				messages.append(
					"row %d ('%s'): comms blackout cannot have a target_id"
					% [index, row_id]
				)
			if not _is_zero_delta(row):
				messages.append(
					"row %d ('%s'): comms blackout must have zero intensity"
					% [index, row_id]
				)


func _require_target(
	row: EventRow,
	index: int,
	row_id: String,
	expected: EventRow.TargetType,
	messages: Array[String]
) -> void:
	if row.target_type != expected:
		messages.append(
			"row %d ('%s'): target_type must be %s"
			% [index, row_id, EventRow.TargetType.keys()[expected]]
		)


func _has_negative_delta(row: EventRow) -> bool:
	return row.intensity_start < 0.0 or row.intensity_peak < 0.0 or row.intensity_end < 0.0


func _has_positive_delta(row: EventRow) -> bool:
	return row.intensity_start > 0.0 or row.intensity_peak > 0.0 or row.intensity_end > 0.0


func _is_zero_delta(row: EventRow) -> bool:
	return (
		is_zero_approx(row.intensity_start)
		and is_zero_approx(row.intensity_peak)
		and is_zero_approx(row.intensity_end)
	)


func _validate_overlap_row(
	row: EventRow,
	index: int,
	row_id: String,
	messages: Array[String]
) -> void:
	match row.overlap_policy:
		EventRow.OverlapPolicy.EXCLUSIVE:
			if not row.overlap_with.is_empty():
				messages.append(
					"row %d ('%s'): EXCLUSIVE rows cannot list overlap_with"
					% [index, row_id]
				)
		EventRow.OverlapPolicy.ANY:
			if not row.overlap_with.is_empty():
				messages.append(
					"row %d ('%s'): ANY rows do not need overlap_with"
					% [index, row_id]
				)
		EventRow.OverlapPolicy.WHITELIST:
			if row.overlap_with.is_empty():
				messages.append(
					"row %d ('%s'): WHITELIST requires at least one id"
					% [index, row_id]
				)
			var seen: Dictionary[StringName, int] = {}
			for other_id: StringName in row.overlap_with:
				if other_id == row.id:
					messages.append(
						"row %d ('%s'): overlap_with cannot reference itself"
						% [index, row_id]
					)
				if seen.has(other_id):
					messages.append(
						"row %d ('%s'): overlap_with has duplicate '%s'"
						% [index, row_id, String(other_id)]
					)
				else:
					seen[other_id] = 1


func _validate_overlap_references(messages: Array[String]) -> void:
	for index: int in rows.size():
		var row: EventRow = rows[index]
		if row == null or row.overlap_policy != EventRow.OverlapPolicy.WHITELIST:
			continue
		for other_id: StringName in row.overlap_with:
			var other: EventRow = get_row(other_id)
			if other == null:
				messages.append(
					"row %d ('%s'): overlap_with references unknown id '%s'"
					% [index, String(row.id), String(other_id)]
				)
				continue
			if other.overlap_policy == EventRow.OverlapPolicy.EXCLUSIVE:
				messages.append(
					"row %d ('%s'): overlap_with '%s' is EXCLUSIVE"
					% [index, String(row.id), String(other_id)]
				)
			elif (
				other.overlap_policy == EventRow.OverlapPolicy.WHITELIST
				and not other.overlap_with.has(row.id)
			):
				messages.append(
					"row %d ('%s'): overlap with '%s' is one-sided"
					% [index, String(row.id), String(other_id)]
				)


func _validate_provenance(
	row: EventRow,
	index: int,
	row_id: String,
	messages: Array[String]
) -> void:
	if row.provenance == null:
		messages.append("row %d ('%s'): provenance is required" % [index, row_id])
		return
	if not row.provenance.real_data:
		return
	if row.provenance.source.is_empty():
		messages.append(
			"row %d ('%s'): real_data requires a non-empty source" % [index, row_id]
		)
	if not _is_iso_date(row.provenance.date_archived):
		messages.append(
			"row %d ('%s'): real_data requires an ISO-8601 date_archived"
			% [index, row_id]
		)


func _is_iso_date(value: String) -> bool:
	if value.length() != 10:
		return false
	if value[4] != "-" or value[7] != "-":
		return false
	var year: String = value.substr(0, 4)
	var month: String = value.substr(5, 2)
	var day: String = value.substr(8, 2)
	if not year.is_valid_int() or not month.is_valid_int() or not day.is_valid_int():
		return false
	var month_number: int = int(month)
	var day_number: int = int(day)
	return month_number >= 1 and month_number <= 12 and day_number >= 1 and day_number <= 31
