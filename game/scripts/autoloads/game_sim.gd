extends Node

## Autoload that drives the simulation clock. It owns the run's SimState,
## converts real time into ticks, forwards every tick to SimTick and publishes
## the resulting facts to the EventLog ledger.
## No class_name on purpose: the autoload singleton is already named GameSim.

signal tick_advanced(tick: int)
signal game_over(cause: StringName)
signal game_reset()

const ECONOMY_PATH: String = "res://databases/economy.tres"
const SECONDS_PER_TICK: float = 60.0
const MAX_TICKS_PER_FRAME: int = 10

enum Speed { X1, X5, X10 }

var state: SimState = SimState.new()
var speed: Speed = Speed.X1
var paused: bool = false

var _economy: EconomyData = null
var _time_accumulator: float = 0.0


## Loads the economy database, reports its problems and prepares a fresh run.
## It does not call new_game(): booting must not clear an existing ledger.
func _ready() -> void:
	_economy = _load_economy()
	state.reset_from_economy(_economy)


## Converts this frame's real time into ticks unless the clock is paused.
func _process(delta: float) -> void:
	if paused:
		return
	feed_time(delta)


## Adds scaled real time to the accumulator and advances as many whole ticks as
## it holds, capped at MAX_TICKS_PER_FRAME. The remainder stays accumulated.
## Returns the number of ticks advanced.
func feed_time(seconds: float) -> int:
	_time_accumulator += seconds * get_rate()
	var ran: int = 0
	while _time_accumulator >= SECONDS_PER_TICK and ran < MAX_TICKS_PER_FRAME:
		_time_accumulator -= SECONDS_PER_TICK
		advance_tick()
		ran += 1
	return ran


## Steps the simulation once and publishes the facts of that tick.
func advance_tick() -> void:
	var facts: Array[LogEntry] = SimTick.step(state, _economy)
	EventLog.log_entries(facts)
	tick_advanced.emit(state.tick)
	for fact: LogEntry in facts:
		if fact.type == LogEntry.Type.GAME_OVER:
			game_over.emit(state.death_cause)
			break


func advance_ticks(count: int) -> void:
	for i: int in range(count):
		advance_tick()


## Starts a clean run: fresh state, empty accumulator and empty ledger.
func new_game() -> void:
	state.reset_from_economy(_economy)
	_time_accumulator = 0.0
	EventLog.reset()
	game_reset.emit()


func reset_game() -> void:
	new_game()


func set_speed(value: Speed) -> void:
	speed = value


func set_paused(value: bool) -> void:
	paused = value


func is_paused() -> bool:
	return paused


## Real seconds the accumulator gains per second of wall clock.
func get_rate() -> float:
	match speed:
		Speed.X5:
			return 5.0
		Speed.X10:
			return 10.0
		_:
			return 1.0


func get_economy() -> EconomyData:
	return _economy


## Loads and validates the economy database. A missing or wrongly typed resource
## never breaks the boot: it warns and falls back to an empty database.
func _load_economy() -> EconomyData:
	var loaded: Resource = ResourceLoader.load(ECONOMY_PATH)
	if loaded == null:
		push_warning("GameSim: could not load economy at " + ECONOMY_PATH)
		return EconomyData.new()
	if not loaded is EconomyData:
		push_warning("GameSim: " + ECONOMY_PATH + " is not an EconomyData resource")
		return EconomyData.new()
	var economy: EconomyData = loaded
	for message: String in economy.validate_rows():
		push_warning("GameSim: economy row problem: " + message)
	# Clamp after validating so the audit still sees the authored values.
	for row: EconomyRow in economy.rows:
		row.value = clampf(row.value, row.min_value, row.max_value)
	return economy
