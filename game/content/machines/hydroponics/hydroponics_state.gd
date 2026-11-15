class_name HydroponicsState
extends RefCounted

## Cultivation state of the hydroponics machine: twelve cells that grow one stage
## every few ticks. It is a plain value object, so the machine station owns one
## and the visual demos own their own copy.
##
## Nothing here reads the wall clock or the global RNG: the run seed, the cell
## index and the tick the cell was sown decide every interval, so two runs with
## the same seed and the same actions grow identical plants.

const CELL_COUNT: int = 12
const ROWS: int = 3
const COLUMNS: int = 4
const STAGE_COUNT: int = 4
const MIN_INTERVAL_TICKS: int = 3
const MAX_INTERVAL_TICKS: int = 6

## Ticks elapsed since this state was created or reset.
var tick: int = 0
## Plants collected with harvest() since this state was created or reset.
var harvested: int = 0

var _run_seed: int = 0
var _planted: Array[bool] = []
var _stages: Array[int] = []
## Ticks accumulated in the current stage of each cell.
var _progress: Array[int] = []
## Ticks every stage of each cell takes, fixed when the cell is sown.
var _intervals: Array[int] = []


func _init(run_seed: int = 0) -> void:
	_run_seed = run_seed
	reset()


## Empties every cell and rewinds the counters. The run seed is kept.
func reset() -> void:
	tick = 0
	harvested = 0
	_planted.clear()
	_stages.clear()
	_progress.clear()
	_intervals.clear()
	for _index: int in range(CELL_COUNT):
		_planted.append(false)
		_stages.append(0)
		_progress.append(0)
		_intervals.append(MIN_INTERVAL_TICKS)


## Advances the state one tick and stores one tick of growth in every planted
## cell that is not mature yet. Returns true when at least one cell reached a
## new stage, so the caller knows it must redraw.
func advance_tick() -> bool:
	tick += 1
	var changed: bool = false
	for index: int in range(CELL_COUNT):
		if not _planted[index]:
			continue
		if _stages[index] >= STAGE_COUNT:
			continue
		_progress[index] += 1
		if _progress[index] < _intervals[index]:
			continue
		_progress[index] -= _intervals[index]
		_stages[index] += 1
		changed = true
	return changed


## Sows an empty cell at stage 1 with its deterministic interval. Returns false
## for a cell that is out of range or already planted.
func plant(index: int) -> bool:
	if not _is_valid(index) or _planted[index]:
		return false
	_planted[index] = true
	_stages[index] = 1
	_progress[index] = 0
	_intervals[index] = _roll_interval(index)
	return true


## Pulls out a planted cell at any stage, mature included. It produces no food:
## a mature plant discarded this way is simply lost. Returns false when the cell
## is empty or out of range.
func remove(index: int) -> bool:
	if not _is_valid(index) or not _planted[index]:
		return false
	_clear(index)
	return true


## Collects a mature plant: counts one harvested unit and empties the cell.
## Returns false unless the cell is exactly at the last stage.
func harvest(index: int) -> bool:
	if not _is_valid(index) or _stages[index] != STAGE_COUNT:
		return false
	_clear(index)
	harvested += 1
	return true


## True when the cell holds a plant, at any stage.
func is_planted(index: int) -> bool:
	if not _is_valid(index):
		return false
	return _planted[index]


## Growth stage of one cell: 0 when empty, 1..4 while it grows.
func stage_of(index: int) -> int:
	if not _is_valid(index):
		return 0
	return _stages[index]


## Ticks every stage takes in one cell, or 0 when the cell is empty or out of
## range (an empty cell has no interval to show).
func interval_of(index: int) -> int:
	if not _is_valid(index) or not _planted[index]:
		return 0
	return _intervals[index]


## Interval of one sowing, in 3..MAX_INTERVAL_TICKS ticks. It mixes the run
## seed, the cell index and the planting tick with integer arithmetic only, so
## it is stable across runs and machines.
func _roll_interval(index: int) -> int:
	var mixed: int = _run_seed
	mixed = (mixed * 73856093) ^ (index * 19349663) ^ (tick * 83492791)
	mixed = absi(mixed)
	return MIN_INTERVAL_TICKS + mixed % (MAX_INTERVAL_TICKS - MIN_INTERVAL_TICKS + 1)


func _is_valid(index: int) -> bool:
	return index >= 0 and index < CELL_COUNT


func _clear(index: int) -> void:
	_planted[index] = false
	_stages[index] = 0
	_progress[index] = 0
	_intervals[index] = MIN_INTERVAL_TICKS
