class_name EconomyData
extends Resource

@export var rows: Array[EconomyRow] = []

# Returns the row with the given id, or null when no such row exists.
func get_row(id: StringName) -> EconomyRow:
	for row: EconomyRow in rows:
		if row.id == id:
			return row
	return null

# Returns the row value clamped to [min_value, max_value].
# A missing row yields the fallback as-is (no clamping applied).
func get_value(id: StringName, fallback: float) -> float:
	var row: EconomyRow = get_row(id)
	if row == null:
		return fallback
	return clampf(row.value, row.min_value, row.max_value)

# Returns the provenance of the row with the given id, or null when there is no row.
func get_provenance(id: StringName) -> DataProvenance:
	var row: EconomyRow = get_row(id)
	if row == null:
		return null
	return row.provenance

# Returns human-readable problems (empty array == all rows valid).
func validate_rows() -> Array[String]:
	var messages: Array[String] = []
	var seen_ids: Dictionary[StringName, int] = {}
	for index: int in rows.size():
		var row: EconomyRow = rows[index]
		var row_id: String = String(row.id)
		if row.id == &"":
			messages.append("row %d: id is empty" % index)
		if seen_ids.has(row.id):
			messages.append("row %d: id '%s' is duplicated" % [index, row_id])
		else:
			seen_ids[row.id] = 1
		if row.min_value > row.max_value:
			messages.append("row %d ('%s'): min_value > max_value" % [index, row_id])
		if row.value < row.min_value or row.value > row.max_value:
			messages.append("row %d ('%s'): value out of [min_value, max_value]" % [index, row_id])
		if row.provenance != null and row.provenance.real_data:
			if row.provenance.source == "" or row.provenance.date_archived == "":
				messages.append("row %d ('%s'): real_data requires non-empty source and date_archived" % [index, row_id])
	return messages
