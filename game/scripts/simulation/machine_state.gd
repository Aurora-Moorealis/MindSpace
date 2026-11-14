class_name MachineState
extends RefCounted

## Mutable state of one habitat machine.
## SimTick is the only writer; reset_from_economy seeds the initial values.

## Machine health is always kept inside [0, MAX_HEALTH].
const MAX_HEALTH: float = 100.0

var id: StringName = &""
var health: float = MAX_HEALTH
var powered: bool = true
var upgrade_level: int = 0


## True when the machine has no health left, regardless of its power state.
func is_broken() -> bool:
	return health <= 0.0
