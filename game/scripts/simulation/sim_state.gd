class_name SimState
extends RefCounted

## Mutable state of one simulation run (contract v1.1).
## Holds data and derived queries only: SimTick is the only writer during a
## tick and GameSim the only writer outside it (player sub-tick actions).

const OXYGEN: StringName = &"oxygen"
const WATER: StringName = &"water"
const FOOD: StringName = &"food"
const ENERGY: StringName = &"energy"

const MACHINE_LIGHTS: StringName = &"lights"
const MACHINE_HYDROPONICS: StringName = &"hydroponics"
const MACHINE_WATER_RECYCLER: StringName = &"water_recycler"
const MACHINE_O2_SYSTEM: StringName = &"o2_system"
const MACHINE_SOLAR_ARRAY: StringName = &"solar_array"
const MACHINE_COMMS_CONSOLE: StringName = &"comms_console"
const MACHINE_REPAIR_BENCH: StringName = &"repair_bench"
const MACHINE_STORM_SHELTER: StringName = &"storm_shelter"

const MACHINE_IDS: Array[StringName] = [
	MACHINE_LIGHTS, MACHINE_HYDROPONICS, MACHINE_WATER_RECYCLER,
	MACHINE_O2_SYSTEM, MACHINE_SOLAR_ARRAY, MACHINE_COMMS_CONSOLE,
	MACHINE_REPAIR_BENCH, MACHINE_STORM_SHELTER,
]

const BLACKOUT_ORDER: Array[StringName] = [
	MACHINE_LIGHTS, MACHINE_HYDROPONICS, MACHINE_WATER_RECYCLER, MACHINE_O2_SYSTEM,
]

## Fallbacks used when a database row is missing.
const _FALLBACK_CAPACITY: float = 10.0
const _FALLBACK_INITIAL: float = 0.0
const _FALLBACK_HEALTH: float = 100.0
const _FALLBACK_HUNGER: float = 100.0
const _FALLBACK_THIRST: float = 100.0
const _FALLBACK_DAY_LENGTH: float = 12.0
const _FALLBACK_NIGHT_LENGTH: float = 12.0
const _FALLBACK_MACHINE_HEALTH: float = 100.0

enum DayPhase { DAY, NIGHT }

var tick: int = 0
var resources: Dictionary[StringName, float] = {}
var health: float = 0.0
var max_health: float = 0.0
var radiation_dose: float = 0.0
var peak_radiation: float = 0.0
var hunger: float = 0.0
var thirst: float = 0.0
var suit_reserve_ticks: int = 0
var is_outside: bool = false
var machines: Dictionary[StringName, MachineState] = {}
## Player statistics and their upgrade-driven multipliers.
var player: PlayerStats = PlayerStats.new()
var blackout_active: bool = false
var game_over: bool = false
var death_cause: StringName = &""


## Restores a fresh run from the economy database: counters back to zero,
## resources at their (clamped) initial values, player stats at their base
## values and every machine healthy, powered and free of repairs or upgrades.
func reset_from_economy(economy: EconomyData) -> void:
	tick = 0
	resources.clear()
	resources[OXYGEN] = _initial_resource(economy, &"initial_oxygen", &"capacity_oxygen")
	resources[WATER] = _initial_resource(economy, &"initial_water", &"capacity_water")
	resources[FOOD] = _initial_resource(economy, &"initial_food", &"capacity_food")
	resources[ENERGY] = _initial_resource(economy, &"initial_energy", &"capacity_energy")
	health = economy.get_value(&"initial_health", _FALLBACK_HEALTH)
	max_health = economy.get_value(&"max_health", _FALLBACK_HEALTH)
	radiation_dose = 0.0
	peak_radiation = 0.0
	player.reset_from_economy(economy)
	hunger = clampf(
		economy.get_value(&"initial_hunger", _FALLBACK_HUNGER), 0.0, player.max_hunger
	)
	thirst = clampf(
		economy.get_value(&"initial_thirst", _FALLBACK_THIRST), 0.0, player.max_thirst
	)
	suit_reserve_ticks = int(economy.get_value(&"suit_reserve_ticks", 0.0))
	is_outside = false
	machines.clear()
	for id: StringName in MACHINE_IDS:
		var machine: MachineState = MachineState.new()
		machine.id = id
		machine.health = _machine_initial_health(economy, id)
		machine.powered = true
		machine.upgrade_level = 0
		machine.repair_ticks_total = 0
		machine.repair_work_done = 0.0
		machine.applied_upgrades.clear()
		machine.power_delta = 0.0
		machine.degradation_delta = 0.0
		machine.output_deltas.clear()
		machines[id] = machine
	blackout_active = false
	game_over = false
	death_cause = &""


## Day or night for the current tick, derived from the day/night lengths.
func get_phase(economy: EconomyData) -> DayPhase:
	if tick % get_sol_length(economy) < _day_length(economy):
		return DayPhase.DAY
	return DayPhase.NIGHT


## Ticks in one sol: the configured day plus the configured night, never below 1.
func get_sol_length(economy: EconomyData) -> int:
	return maxi(1, _day_length(economy) + _night_length(economy))


## Configured day length in ticks.
func _day_length(economy: EconomyData) -> int:
	return int(economy.get_value(&"day_length_ticks", _FALLBACK_DAY_LENGTH))


## Configured night length in ticks.
func _night_length(economy: EconomyData) -> int:
	return int(economy.get_value(&"night_length_ticks", _FALLBACK_NIGHT_LENGTH))


## A run is alive until the tick declares it over.
func is_alive() -> bool:
	return not game_over


func get_resource(id: StringName) -> float:
	if not resources.has(id):
		return 0.0
	return resources[id]


## Writes the value as-is; clamping is the responsibility of the tick.
func set_resource(id: StringName, value: float) -> void:
	resources[id] = value


## Initial amount of a resource, clamped to the row capacity.
func _initial_resource(
	economy: EconomyData,
	initial_id: StringName,
	capacity_id: StringName
) -> float:
	var initial: float = economy.get_value(initial_id, _FALLBACK_INITIAL)
	var capacity: float = economy.get_value(capacity_id, _FALLBACK_CAPACITY)
	return clampf(initial, 0.0, capacity)


## Initial health row of one machine, keyed as machine_<id>_initial_health.
func _machine_initial_health(economy: EconomyData, id: StringName) -> float:
	var row_id: StringName = StringName("machine_" + String(id) + "_initial_health")
	var initial_health: float = economy.get_value(row_id, _FALLBACK_MACHINE_HEALTH)
	return clampf(initial_health, 0.0, MachineState.MAX_HEALTH)
