class_name MachineState
extends RefCounted

## Mutable state of one habitat machine.
## SimTick is the only writer during a tick; GameSim is the only writer outside
## the tick (player sub-tick actions such as repairs and upgrades).
## reset_from_economy seeds the initial values.

## Machine health is always kept inside [0, MAX_HEALTH].
const MAX_HEALTH: float = 100.0

var id: StringName = &""
var health: float = MAX_HEALTH
var powered: bool = true
var upgrade_level: int = 0
## Work divisions required by the repair in progress; 0 means no repair.
var repair_ticks_total: int = 0
## Work divisions already accumulated by the player.
var repair_work_done: float = 0.0
## Ids of the one-use upgrades already applied to this machine.
var applied_upgrades: Array[StringName] = []
## Additive energy-per-tick delta from upgrades (clamped at read time).
var power_delta: float = 0.0
## Additive health-per-tick delta from upgrades (clamped at read time).
var degradation_delta: float = 0.0
## Additive production delta per resource, keyed by resource id.
var output_deltas: Dictionary[StringName, float] = {}


## True when the machine has no health left, regardless of its power state.
func is_broken() -> bool:
	return health <= 0.0


## True while a started repair still has work divisions left.
func is_repairing() -> bool:
	return repair_ticks_total > 0 and repair_work_done < float(repair_ticks_total)
