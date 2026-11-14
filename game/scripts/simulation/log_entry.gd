class_name LogEntry
extends RefCounted

## One fact of a run recorded in the EventLog ledger.
## The payload maps StringName keys to flat values only (see is_plain_payload).

enum Type {
	REPAIR,
	UPGRADE,
	REPORT_SENT,
	RADIATION_PEAK,
	SHELTER_USED,
	SUBMISSION_COMPLETED,
	MACHINE_BREAKDOWN,
	BLACKOUT,
	SOL_COMPLETED,
	DEATH,
	GAME_OVER,
}

var type: Type = Type.REPAIR
var tick: int = 0
## Dictionary[Variant, Variant] is the explicit form of a bare Dictionary: the
## checker rejects untyped collections, and Dictionary[StringName, Variant]
## cannot receive untyped dictionary literals in this engine version.
var payload: Dictionary[Variant, Variant] = {}


func _init(
	p_type: Type = Type.REPAIR,
	p_tick: int = 0,
	p_payload: Dictionary[Variant, Variant] = {}
) -> void:
	type = p_type
	tick = p_tick
	payload = p_payload


## True when p_value is within the declared Type range.
static func is_valid_type(p_value: int) -> bool:
	return p_value >= Type.REPAIR and p_value <= Type.GAME_OVER


## True when every value (recursively, through nested arrays and dictionaries)
## is a flat serializable type. Objects, callables and null are rejected.
static func is_plain_payload(p_payload: Dictionary[Variant, Variant]) -> bool:
	return _is_plain_value(p_payload)


static func _is_plain_value(p_value: Variant) -> bool:
	match typeof(p_value):
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING, TYPE_STRING_NAME:
			return true
		TYPE_ARRAY:
			for item: Variant in (p_value as Array):
				if not _is_plain_value(item):
					return false
			return true
		TYPE_DICTIONARY:
			for nested_value: Variant in (p_value as Dictionary).values():
				if not _is_plain_value(nested_value):
					return false
			return true
		_:
			return false
