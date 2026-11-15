class_name ActiveEvent
extends RefCounted

## One event currently applying its effect during a tick.
## The row is static data; started_tick records when it actually began, which
## may be later than row.onset_tick when the event waited in the queue.

var row: EventRow = null
var started_tick: int = 0


func _init(p_row: EventRow = null, p_started_tick: int = 0) -> void:
	row = p_row
	started_tick = p_started_tick


## First tick after the event's actual window.
func end_tick() -> int:
	if row == null:
		return started_tick
	return started_tick + row.duration_ticks
