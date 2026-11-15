class_name HydroponicsState
extends RefCounted

const CELL_COUNT: int = 12
const BASE_INTERVAL: float = 4.0
const MIN_INTERVAL: float = 3.0
const MAX_INTERVAL: float = 6.0
const VARIATION_CHANCE: float = 0.5

static var planted: Array[bool] = []
static var planted_at: Array[float] = []
static var intervals: Array[float] = []
static var harvested: int = 0


static func ensure_initialized() -> void:
	if planted.size() == CELL_COUNT:
		return
	planted.clear()
	planted_at.clear()
	intervals.clear()
	for _i: int in range(CELL_COUNT):
		planted.append(false)
		planted_at.append(0.0)
		intervals.append(BASE_INTERVAL)


static func now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


static func _roll_interval() -> float:
	if randf() < VARIATION_CHANCE:
		return randf_range(MIN_INTERVAL, MAX_INTERVAL)
	return BASE_INTERVAL


static func plant(index: int) -> void:
	ensure_initialized()
	planted[index] = true
	planted_at[index] = now()
	intervals[index] = _roll_interval()


static func clear(index: int) -> void:
	ensure_initialized()
	planted[index] = false
	planted_at[index] = 0.0
	intervals[index] = BASE_INTERVAL


static func harvest(index: int) -> void:
	clear(index)
	harvested += 1


static func stage_of(index: int) -> int:
	ensure_initialized()
	if not planted[index]:
		return 0
	return clampi(int((now() - planted_at[index]) / intervals[index]) + 1, 1, 4)
