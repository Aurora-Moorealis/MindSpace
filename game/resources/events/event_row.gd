class_name EventRow
extends Resource

## One row of the events database.
##
## Data only: this class describes an event and how its intensity changes over
## time, but it never mutates SimState. A later scheduler reads these rows.
## Target rules chosen in the design interview:
## - production and consumption events point to a resource (oxygen, water,
##   food or energy), so a two-output machine such as hydroponics is unambiguous;
## - machine breakdown points to a machine because the delta is machine health;
## - radiation uses the pseudo-resource "radiation", stored as radiation_dose;
## - comms blackout has no numeric target and only raises a flag later.

enum Archetype {
	MACHINE_BREAKDOWN,
	PRODUCTION_DROP,
	CONSUMPTION_SPIKE,
	RADIATION_WINDOW,
	COMMS_BLACKOUT,
}

enum TargetType {
	MACHINE,
	RESOURCE,
	NONE,
}

enum OverlapPolicy {
	EXCLUSIVE,
	WHITELIST,
	ANY,
}

const MACHINE_IDS: Array[StringName] = [
	&"lights",
	&"hydroponics",
	&"water_recycler",
	&"o2_system",
	&"solar_array",
	&"comms_console",
	&"repair_bench",
	&"storm_shelter",
]

const RESOURCE_IDS: Array[StringName] = [
	&"oxygen",
	&"water",
	&"food",
	&"energy",
]

## Radiation is not a SimState resource: its dose lives in radiation_dose.
const RADIATION_ID: StringName = &"radiation"

@export var id: StringName = &""
@export var archetype: Archetype = Archetype.MACHINE_BREAKDOWN
@export var target_type: TargetType = TargetType.NONE
@export var target_id: StringName = &""
@export_range(0, 100000, 1) var onset_tick: int = 0
@export_range(1, 1000, 1) var duration_ticks: int = 1
@export_range(-1000000.0, 1000000.0, 0.001) var intensity_start: float = 0.0
@export_range(-1000000.0, 1000000.0, 0.001) var intensity_peak: float = 0.0
@export_range(-1000000.0, 1000000.0, 0.001) var intensity_end: float = 0.0
@export var overlap_policy: OverlapPolicy = OverlapPolicy.EXCLUSIVE
@export var overlap_with: Array[StringName] = []
@export_range(0, 1000, 1) var delay_min_ticks: int = 0
@export_range(0, 1000, 1) var delay_max_ticks: int = 0
@export var provenance: DataProvenance = null


## First tick after the event's active window.
func end_tick() -> int:
	return onset_tick + duration_ticks


## True while the tick is inside [onset_tick, end_tick()).
func is_active_at(at_tick: int) -> bool:
	return at_tick >= onset_tick and at_tick < end_tick()


## Intensity sampled per tick. The peak is reached at duration_ticks / 2 for
## events of three or more ticks. Duration 1 uses the peak; duration 2 goes
## straight from start to end because there is no middle tick.
func intensity_at(elapsed_ticks: int) -> float:
	if duration_ticks <= 1:
		return intensity_peak
	if duration_ticks == 2:
		return lerpf(intensity_start, intensity_end, float(clampi(elapsed_ticks, 0, 1)))
	var mid_tick: int = duration_ticks / 2
	var tick: int = clampi(elapsed_ticks, 0, duration_ticks - 1)
	if tick <= mid_tick:
		return lerpf(intensity_start, intensity_peak, float(tick) / float(mid_tick))
	return lerpf(
		intensity_peak,
		intensity_end,
		float(tick - mid_tick) / float(duration_ticks - 1 - mid_tick)
	)


## This row's own vote. EventData.can_overlap() requires both rows to agree.
func allows_overlap_with(other: EventRow) -> bool:
	if other == null or other.id == id:
		return false
	match overlap_policy:
		OverlapPolicy.EXCLUSIVE:
			return false
		OverlapPolicy.ANY:
			return true
		OverlapPolicy.WHITELIST:
			return overlap_with.has(other.id)
	return false
