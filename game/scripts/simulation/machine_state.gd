class_name MachineState
extends RefCounted

## Mutable state of one habitat machine.
## SimTick is the only writer; reset_from_economy seeds the initial values.

var id: StringName = &""
var health: float = 100.0
var powered: bool = true
var upgrade_level: int = 0


## True when the machine has no health left, regardless of its power state.
func is_broken() -> bool:
	return health <= 0.0
