class_name PendingEvent
extends RefCounted

## An event that is due but has not started yet, either because it cannot
## overlap with the active event or because its deterministic queue delay has
## not elapsed.

var row: EventRow = null
var not_before_tick: int = 0


func _init(p_row: EventRow = null, p_not_before_tick: int = 0) -> void:
	row = p_row
	not_before_tick = p_not_before_tick
