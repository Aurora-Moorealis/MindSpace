extends SceneTree

## Integration smoke test for the machines module (wave 3 verification, v1.1).
## Loads the real economy and machine databases, drives the GameSim machine API
## (repair and upgrade actions), feeds synthetic sheets to the tick and asserts
## the contract: registry integrity, sheet-driven consumption and its sanitized
## clamps, degradation and production clamps, repair divisions including broken
## machines, rejected actions, upgrade support per machine, every upgrade effect
## stat, invalid-data validators, restart and tick integration.
## Run: godot --headless --path game --script res://scripts/dev/machines_smoke.gd
## Exit code 0 when every check passes, 1 otherwise.
##
## The autoloads are only present once the scripted main loop starts, so the
## whole run happens on the first processed frame. Their methods are reached
## through typed wrappers because autoload identifiers are not available at
## compile time in this mode.

const ECONOMY_PATH: String = "res://databases/economy.tres"
const MACHINES_PATH: String = "res://databases/machines.tres"

var _checks: int = 0
var _failures: int = 0
var _ran: bool = false
var _game_sim: Node = null
var _event_log: Node = null
var _economy: EconomyData = null
var _real_registry: MachineDatabase = null


func _process(_delta: float) -> bool:
	if _ran:
		return false
	_ran = true
	_run()
	return false


## Runs every verification group, then reports and quits.
func _run() -> void:
	_game_sim = root.get_node_or_null("GameSim")
	_event_log = root.get_node_or_null("EventLog")
	if _game_sim == null or _event_log == null:
		_expect(false, "boot: the GameSim and EventLog autoloads must be available")
		_finish()
		return
	# The autoload clock must not advance while the checks drive ticks by hand.
	_game_sim.call(&"set_paused", true)

	var economy_value: Variant = _game_sim.call(&"get_economy")
	_economy = economy_value as EconomyData
	_real_registry = ResourceLoader.load(MACHINES_PATH) as MachineDatabase
	if _economy == null:
		_expect(false, "boot: GameSim must expose an economy database")
		_finish()
		return
	if _real_registry == null:
		_expect(false, "boot: %s must load as a MachineDatabase" % MACHINES_PATH)
		_finish()
		return

	_check_registry()
	_check_consumption()
	_check_degradation()
	_check_production()
	_check_repair()
	_check_broken_repair()
	_check_repair_rejections()
	_check_upgrades()
	_check_upgrade_rejections()
	_check_effective_tick()
	_check_validators()
	_check_restart()
	_check_integration()

	_finish()


## 1) The committed registry and its eight sheets are complete and valid.
func _check_registry() -> void:
	var problems: Array[String] = _real_registry.validate()
	_expect(
		problems.is_empty(),
		"registry: validate() must be empty (got %d: %s)" % [problems.size(), str(problems)]
	)
	_expect(
		_real_registry.machines.size() == SimState.MACHINE_IDS.size(),
		"registry: expected %d sheets (got %d)"
		% [SimState.MACHINE_IDS.size(), _real_registry.machines.size()]
	)
	_expect(
		_real_registry.get_machine(&"not_a_machine") == null,
		"registry: an unknown id must not resolve to a sheet"
	)

	var expected_draws: Dictionary[StringName, float] = {
		SimState.MACHINE_LIGHTS: 0.2,
		SimState.MACHINE_HYDROPONICS: 0.4,
		SimState.MACHINE_WATER_RECYCLER: 0.4,
		SimState.MACHINE_O2_SYSTEM: 0.5,
		SimState.MACHINE_SOLAR_ARRAY: 0.0,
		SimState.MACHINE_COMMS_CONSOLE: 0.2,
		SimState.MACHINE_REPAIR_BENCH: 0.1,
		SimState.MACHINE_STORM_SHELTER: 0.1,
	}

	for id: StringName in SimState.MACHINE_IDS:
		var data: MachineData = _real_registry.get_machine(id)
		_expect(data != null, "registry: %s must have a sheet" % id)
		if data == null:
			continue
		_expect(
			data.display_name_key == id,
			"registry: %s display_name_key must be its id (got %s)"
			% [id, String(data.display_name_key)]
		)
		_expect(
			data.repair_ticks == 1,
			"registry: %s repair_ticks must be 1 (got %d)" % [id, data.repair_ticks]
		)
		_expect(
			is_equal_approx(data.repair_energy_cost, 1.0),
			"registry: %s repair_energy_cost must be 1.0 (got %f)"
			% [id, data.repair_energy_cost]
		)
		_expect(
			data.upgrades.is_empty(),
			"registry: %s upgrades must stay empty in this change" % id
		)
		_expect(
			is_equal_approx(_energy_draw(_real_registry, id), expected_draws[id]),
			"registry: %s energy draw must be %.2f (got %f)"
			% [id, expected_draws[id], _energy_draw(_real_registry, id)]
		)
		if id == SimState.MACHINE_SOLAR_ARRAY:
			_expect(
				data.consumption.is_empty(),
				"registry: solar_array must declare no consumption"
			)
		else:
			_expect(
				data.consumption.size() == 1,
				"registry: %s must declare exactly one consumption entry (got %d)"
				% [id, data.consumption.size()]
			)
			if data.consumption.size() == 1:
				var entry: MachineConsumption = data.consumption[0]
				_expect(
					entry != null and entry.resource == SimState.ENERGY,
					"registry: %s must consume energy" % id
				)

	var null_rows: int = 0
	if _real_registry.machines.size() == SimState.MACHINE_IDS.size():
		var same_order: bool = true
		for index: int in SimState.MACHINE_IDS.size():
			var row: MachineData = _real_registry.machines[index]
			if row == null:
				null_rows += 1
				same_order = false
				continue
			if row.id != SimState.MACHINE_IDS[index]:
				same_order = false
		_expect(
			same_order,
			"registry: the sheet order must follow SimState.MACHINE_IDS"
		)
	_expect(
		null_rows == 0,
		"registry: no registry row may be null (got %d)" % null_rows
	)

	var boot_registry: MachineDatabase = _game_sim.get(&"_machines") as MachineDatabase
	_expect(boot_registry != null, "registry: GameSim must load a machine database at boot")
	if boot_registry != null:
		_expect(
			boot_registry.validate().is_empty(),
			"registry: the GameSim-loaded database must validate clean"
		)
		_expect(
			boot_registry.get_machine(SimState.MACHINE_LIGHTS) != null,
			"registry: the GameSim-loaded database must expose lights"
		)
	_expect(
		_sim_machine_data(SimState.MACHINE_LIGHTS) != null,
		"registry: GameSim.get_machine_data must resolve a core id"
	)
	_expect(
		_sim_machine_data(&"not_a_machine") == null,
		"registry: GameSim.get_machine_data must return null for an unknown id"
	)
	_expect(
		_sim_machine(SimState.MACHINE_LIGHTS) != null,
		"registry: GameSim.get_machine_state must resolve a core id"
	)
	_expect(
		_sim_machine(&"not_a_machine") == null,
		"registry: GameSim.get_machine_state must return null for an unknown id"
	)

	_expect(
		_economy.rows.size() == 55,
		"registry: economy must keep 55 rows (got %d)" % _economy.rows.size()
	)
	_expect(
		_economy.validate_rows().is_empty(),
		"registry: economy rows must validate clean"
	)
	var power_rows: int = 0
	for row: EconomyRow in _economy.rows:
		if String(row.id).begins_with("power_"):
			power_rows += 1
	_expect(
		power_rows == 0,
		"registry: no power_* economy row may survive (got %d)" % power_rows
	)
	print("machines_smoke: 1) registry valid with 8 sheets")


## 2) Operating machines consume their sheet; off, broken and empty sheets do not.
func _check_consumption() -> void:
	var on_state: SimState = _fresh_state()
	on_state.tick = 12
	on_state.set_resource(SimState.ENERGY, 5.0)
	var off_state: SimState = _fresh_state()
	off_state.tick = 12
	off_state.set_resource(SimState.ENERGY, 5.0)
	_operate_none(off_state)
	SimTick.step(on_state, _economy, _real_registry)
	SimTick.step(off_state, _economy, _real_registry)
	var total_draw: float = _total_energy_draw(_real_registry)
	_expect(
		is_equal_approx(off_state.get_resource(SimState.ENERGY), 5.0),
		"consumption: powered-off machines must not drain energy (got %f)"
		% off_state.get_resource(SimState.ENERGY)
	)
	_expect(
		is_equal_approx(on_state.get_resource(SimState.ENERGY), 5.0 - total_draw),
		"consumption: operating machines must drain %.2f energy (got %f)"
		% [total_draw, on_state.get_resource(SimState.ENERGY)]
	)

	var broken_state: SimState = _fresh_state()
	broken_state.tick = 12
	broken_state.set_resource(SimState.ENERGY, 5.0)
	_operate_none(broken_state)
	var broken_lights: MachineState = _machine_of(broken_state, SimState.MACHINE_LIGHTS)
	broken_lights.powered = true
	broken_lights.health = 0.0
	SimTick.step(broken_state, _economy, _real_registry)
	_expect(
		is_equal_approx(broken_state.get_resource(SimState.ENERGY), 5.0),
		"consumption: a broken machine must not drain energy (got %f)"
		% broken_state.get_resource(SimState.ENERGY)
	)

	var empty_state: SimState = _fresh_state()
	empty_state.tick = 12
	empty_state.set_resource(SimState.ENERGY, 5.0)
	_operate_only(empty_state, _only(SimState.MACHINE_SOLAR_ARRAY))
	SimTick.step(empty_state, _economy, _real_registry)
	_expect(
		is_equal_approx(empty_state.get_resource(SimState.ENERGY), 5.0),
		"consumption: an empty consumption list must drain nothing (got %f)"
		% empty_state.get_resource(SimState.ENERGY)
	)

	var non_energy_registry: MachineDatabase = _build_non_energy_registry()
	var non_energy_state: SimState = _fresh_state()
	non_energy_state.tick = 12
	_operate_only(non_energy_state, _only(SimState.MACHINE_LIGHTS))
	non_energy_state.set_resource(SimState.FOOD, 5.0)
	non_energy_state.set_resource(SimState.OXYGEN, 5.0)
	non_energy_state.set_resource(SimState.ENERGY, 5.0)
	SimTick.step(non_energy_state, _economy, non_energy_registry)
	var crew_food: float = _economy.get_value(&"food_consumption_per_tick", 0.0)
	var crew_oxygen: float = _economy.get_value(&"oxygen_consumption_per_tick", 0.0)
	_expect(
		is_equal_approx(
			non_energy_state.get_resource(SimState.FOOD), 5.0 - crew_food - 0.5
		),
		"consumption: a food entry must be subtracted (got %f)"
		% non_energy_state.get_resource(SimState.FOOD)
	)
	_expect(
		is_equal_approx(
			non_energy_state.get_resource(SimState.OXYGEN), 5.0 - crew_oxygen - 0.3
		),
		"consumption: an oxygen entry must be subtracted (got %f)"
		% non_energy_state.get_resource(SimState.OXYGEN)
	)
	_expect(
		is_equal_approx(non_energy_state.get_resource(SimState.ENERGY), 5.0),
		"consumption: a sheet without an energy entry must not drain energy (got %f)"
		% non_energy_state.get_resource(SimState.ENERGY)
	)

	non_energy_state.set_resource(SimState.FOOD, 0.05)
	non_energy_state.set_resource(SimState.OXYGEN, 0.02)
	SimTick.step(non_energy_state, _economy, non_energy_registry)
	_expect(
		non_energy_state.get_resource(SimState.FOOD) == 0.0,
		"consumption: food must clamp at zero (got %f)"
		% non_energy_state.get_resource(SimState.FOOD)
	)
	_expect(
		non_energy_state.get_resource(SimState.OXYGEN) == 0.0,
		"consumption: oxygen must clamp at zero (got %f)"
		% non_energy_state.get_resource(SimState.OXYGEN)
	)

	var clamp_state: SimState = _fresh_state()
	clamp_state.tick = 12
	_operate_only(clamp_state, _only(SimState.MACHINE_LIGHTS))
	clamp_state.set_resource(SimState.ENERGY, 0.1)
	SimTick.step(clamp_state, _economy, _real_registry)
	_expect(
		clamp_state.get_resource(SimState.ENERGY) == 0.0,
		"consumption: energy must clamp at zero (got %f)"
		% clamp_state.get_resource(SimState.ENERGY)
	)

	# v1.1 sanitization: a power delta bigger than the entry clamps at zero.
	var power_clamp_state: SimState = _fresh_state()
	power_clamp_state.tick = 12
	_operate_only(power_clamp_state, _only(SimState.MACHINE_LIGHTS))
	power_clamp_state.set_resource(SimState.ENERGY, 5.0)
	_machine_of(power_clamp_state, SimState.MACHINE_LIGHTS).power_delta = -0.5
	SimTick.step(
		power_clamp_state,
		_economy,
		_build_single_consumption_registry(SimState.ENERGY, 0.2)
	)
	_expect(
		is_equal_approx(power_clamp_state.get_resource(SimState.ENERGY), 5.0),
		"consumption clamp: a power delta above the entry must drain nothing (got %f)"
		% power_clamp_state.get_resource(SimState.ENERGY)
	)

	# A negative amount counts as zero instead of adding resources.
	var negative_energy_state: SimState = _fresh_state()
	negative_energy_state.tick = 12
	_operate_only(negative_energy_state, _only(SimState.MACHINE_LIGHTS))
	negative_energy_state.set_resource(SimState.ENERGY, 5.0)
	SimTick.step(
		negative_energy_state,
		_economy,
		_build_single_consumption_registry(SimState.ENERGY, -0.5)
	)
	_expect(
		is_equal_approx(negative_energy_state.get_resource(SimState.ENERGY), 5.0),
		"consumption clamp: a negative energy amount must not add energy (got %f)"
		% negative_energy_state.get_resource(SimState.ENERGY)
	)

	var negative_food_state: SimState = _fresh_state()
	negative_food_state.tick = 12
	_operate_only(negative_food_state, _only(SimState.MACHINE_LIGHTS))
	negative_food_state.set_resource(SimState.FOOD, 5.0)
	SimTick.step(
		negative_food_state,
		_economy,
		_build_single_consumption_registry(SimState.FOOD, -0.5)
	)
	_expect(
		is_equal_approx(negative_food_state.get_resource(SimState.FOOD), 5.0 - crew_food),
		"consumption clamp: a negative food amount must not add food (got %f)"
		% negative_food_state.get_resource(SimState.FOOD)
	)

	# An unknown resource is ignored and never creates a state key.
	var unknown_resource_state: SimState = _fresh_state()
	unknown_resource_state.tick = 12
	_operate_only(unknown_resource_state, _only(SimState.MACHINE_LIGHTS))
	unknown_resource_state.set_resource(SimState.ENERGY, 5.0)
	SimTick.step(
		unknown_resource_state,
		_economy,
		_build_single_consumption_registry(&"plasma", 1.0)
	)
	_expect(
		not unknown_resource_state.resources.has(&"plasma"),
		"consumption clamp: an unknown resource must not create a state key"
	)
	_expect(
		is_equal_approx(unknown_resource_state.get_resource(SimState.ENERGY), 5.0),
		"consumption clamp: an unknown resource must not drain energy (got %f)"
		% unknown_resource_state.get_resource(SimState.ENERGY)
	)

	# Duplicated resources: only the first valid entry counts.
	var duplicate_state: SimState = _fresh_state()
	duplicate_state.tick = 12
	_operate_only(duplicate_state, _only(SimState.MACHINE_LIGHTS))
	duplicate_state.set_resource(SimState.ENERGY, 5.0)
	_machine_of(duplicate_state, SimState.MACHINE_LIGHTS).power_delta = -0.1
	SimTick.step(
		duplicate_state, _economy, _build_duplicate_energy_registry()
	)
	_expect(
		is_equal_approx(duplicate_state.get_resource(SimState.ENERGY), 4.9),
		"consumption clamp: a duplicated energy entry must not apply the delta twice (got %f)"
		% duplicate_state.get_resource(SimState.ENERGY)
	)

	# A power delta still applies from a base of zero when the sheet has no
	# energy entry, and a negative delta never adds energy.
	var no_entry_lights: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 1, 1.0)
	var no_entry_registry: MachineDatabase = MachineDatabase.new()
	no_entry_registry.machines.append(no_entry_lights)
	var base_zero_state: SimState = _fresh_state()
	base_zero_state.tick = 12
	_operate_only(base_zero_state, _only(SimState.MACHINE_LIGHTS))
	base_zero_state.set_resource(SimState.ENERGY, 5.0)
	_machine_of(base_zero_state, SimState.MACHINE_LIGHTS).power_delta = 0.3
	SimTick.step(base_zero_state, _economy, no_entry_registry)
	_expect(
		is_equal_approx(base_zero_state.get_resource(SimState.ENERGY), 4.7),
		"consumption clamp: a power delta must apply from base zero (got %f)"
		% base_zero_state.get_resource(SimState.ENERGY)
	)
	var negative_base_zero_state: SimState = _fresh_state()
	negative_base_zero_state.tick = 12
	_operate_only(negative_base_zero_state, _only(SimState.MACHINE_LIGHTS))
	negative_base_zero_state.set_resource(SimState.ENERGY, 5.0)
	_machine_of(negative_base_zero_state, SimState.MACHINE_LIGHTS).power_delta = -0.3
	SimTick.step(negative_base_zero_state, _economy, no_entry_registry)
	_expect(
		is_equal_approx(negative_base_zero_state.get_resource(SimState.ENERGY), 5.0),
		"consumption clamp: a negative base-zero power delta must not add energy (got %f)"
		% negative_base_zero_state.get_resource(SimState.ENERGY)
	)
	print("machines_smoke: 2) sheet-driven consumption and clamps")


## 2b) Effective degradation clamps at zero and adds positive deltas.
func _check_degradation() -> void:
	var base: float = _economy.get_value(&"machine_lights_degradation_per_tick", 0.0)
	_expect(
		base > 0.0,
		"degradation: the lights base row must be positive (got %f)" % base
	)
	var clamped: SimState = _fresh_state()
	clamped.tick = 12
	clamped.set_resource(SimState.ENERGY, 5.0)
	var clamped_lights: MachineState = _machine_of(clamped, SimState.MACHINE_LIGHTS)
	clamped_lights.health = 50.0
	clamped_lights.degradation_delta = -base - 5.0
	SimTick.step(clamped, _economy, _real_registry)
	_expect(
		is_equal_approx(clamped_lights.health, 50.0),
		"degradation clamp: a delta below the base row must stop the wear (got %f)"
		% clamped_lights.health
	)

	var added: SimState = _fresh_state()
	added.tick = 12
	added.set_resource(SimState.ENERGY, 5.0)
	var added_lights: MachineState = _machine_of(added, SimState.MACHINE_LIGHTS)
	added_lights.degradation_delta = 0.03
	SimTick.step(added, _economy, _real_registry)
	_expect(
		is_equal_approx(added_lights.health, MachineState.MAX_HEALTH - (base + 0.03)),
		"degradation clamp: a positive delta must add wear (got %f)"
		% added_lights.health
	)
	print("machines_smoke: 2b) effective degradation clamps")


## 2c) Effective production clamps at zero and respects the resource capacity.
func _check_production() -> void:
	var solar_base: float = _economy.get_value(&"solar_output_per_tick", 0.0)
	var energy_capacity: float = _economy.get_value(&"capacity_energy", 10.0)
	var capped: SimState = _fresh_state()
	capped.tick = 0
	_operate_only(capped, _only(SimState.MACHINE_SOLAR_ARRAY))
	capped.set_resource(SimState.ENERGY, energy_capacity - 0.2)
	_machine_of(capped, SimState.MACHINE_SOLAR_ARRAY).output_deltas[SimState.ENERGY] = 5.0
	SimTick.step(capped, _economy, _real_registry)
	_expect(
		is_equal_approx(capped.get_resource(SimState.ENERGY), energy_capacity),
		"production: a delta above the capacity must be cut to the capacity (got %f)"
		% capped.get_resource(SimState.ENERGY)
	)

	var zeroed: SimState = _fresh_state()
	zeroed.tick = 0
	_operate_only(zeroed, _only(SimState.MACHINE_SOLAR_ARRAY))
	zeroed.set_resource(SimState.ENERGY, 0.0)
	_machine_of(zeroed, SimState.MACHINE_SOLAR_ARRAY).output_deltas[SimState.ENERGY] = (
		-solar_base - 5.0
	)
	SimTick.step(zeroed, _economy, _real_registry)
	_expect(
		zeroed.get_resource(SimState.ENERGY) == 0.0,
		"production: a negative effective output must clamp at zero (got %f)"
		% zeroed.get_resource(SimState.ENERGY)
	)
	print("machines_smoke: 2c) effective production clamps")


## 3) Repair divisions, cost, progress, single fact and player speed.
func _check_repair() -> void:
	var registry: MachineDatabase = _build_repair_registry()
	_sim_set_registry(registry)
	_sim_new_game()
	var state: SimState = _sim_state()
	state.tick = 12
	state.set_resource(SimState.ENERGY, 5.0)
	var machine: MachineState = _sim_machine(SimState.MACHINE_LIGHTS)
	machine.health = 40.0
	machine.powered = false

	_expect(
		_sim_can_repair(SimState.MACHINE_LIGHTS),
		"repair: a damaged machine with energy must be repairable"
	)
	_expect(
		_sim_start_repair(SimState.MACHINE_LIGHTS),
		"repair: start_repair must accept the valid request"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 3.5),
		"repair: the 1.5 cost must be charged at start (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		machine.repair_ticks_total == 4,
		"repair: repair_ticks_total must take the sheet value (got %d)"
		% machine.repair_ticks_total
	)
	_expect(
		is_zero_approx(machine.repair_work_done),
		"repair: a fresh repair must start with no work done"
	)
	_expect(
		_sim_is_repairing(SimState.MACHINE_LIGHTS),
		"repair: the machine must report a repair in progress"
	)
	_expect(
		_sim_repair_progress(SimState.MACHINE_LIGHTS) == 0.0,
		"repair: a fresh repair must report zero progress (got %f)"
		% _sim_repair_progress(SimState.MACHINE_LIGHTS)
	)
	_expect(
		_event_count(LogEntry.Type.REPAIR) == 0,
		"repair: starting must not emit REPAIR yet"
	)

	_sim_advance_tick()
	_expect(
		is_equal_approx(_sim_repair_progress(SimState.MACHINE_LIGHTS), 0.25),
		"repair x1: one of four divisions must report 0.25 (got %f)"
		% _sim_repair_progress(SimState.MACHINE_LIGHTS)
	)
	_expect(
		_event_count(LogEntry.Type.REPAIR) == 0,
		"repair x1: an unfinished repair must not emit REPAIR"
	)
	_sim_advance_tick()
	_expect(
		is_equal_approx(_sim_repair_progress(SimState.MACHINE_LIGHTS), 0.5),
		"repair x1: two of four divisions must report 0.5 (got %f)"
		% _sim_repair_progress(SimState.MACHINE_LIGHTS)
	)
	_sim_advance_tick()
	_expect(
		is_equal_approx(_sim_repair_progress(SimState.MACHINE_LIGHTS), 0.75),
		"repair x1: three of four divisions must report 0.75 (got %f)"
		% _sim_repair_progress(SimState.MACHINE_LIGHTS)
	)
	_sim_advance_tick()
	_expect(
		not _sim_is_repairing(SimState.MACHINE_LIGHTS),
		"repair x1: the fourth tick must finish the repair"
	)
	_expect(
		is_equal_approx(machine.health, MachineState.MAX_HEALTH),
		"repair x1: completion must restore full health (got %f)" % machine.health
	)
	_expect(machine.powered, "repair x1: completion must power the machine")
	_expect(
		machine.repair_ticks_total == 0 and is_zero_approx(machine.repair_work_done),
		"repair x1: completion must clear the repair counters"
	)
	_expect(
		_sim_repair_progress(SimState.MACHINE_LIGHTS) == 0.0,
		"repair x1: a finished repair must report zero progress"
	)
	_expect(
		_event_count(LogEntry.Type.REPAIR) == 1,
		"repair x1: exactly one REPAIR fact must be logged (got %d)"
		% _event_count(LogEntry.Type.REPAIR)
	)
	var repair_entries: Array[LogEntry] = _event_entries(LogEntry.Type.REPAIR)
	if repair_entries.size() == 1:
		_expect(
			repair_entries[0].payload.get(&"machine") == SimState.MACHINE_LIGHTS,
			"repair x1: the REPAIR payload must carry the machine id"
		)
		_expect(
			repair_entries[0].tick == state.tick - 1,
			"repair x1: the REPAIR fact must carry the completing tick"
		)
	_sim_advance_tick()
	_expect(
		_event_count(LogEntry.Type.REPAIR) == 1,
		"repair x1: a finished repair must not emit a second REPAIR"
	)

	# Speed 2: the same four divisions finish in two ticks instead of four.
	_sim_new_game()
	state = _sim_state()
	state.tick = 12
	state.set_resource(SimState.ENERGY, 5.0)
	state.player.repair_speed_multiplier = 2.0
	machine = _sim_machine(SimState.MACHINE_LIGHTS)
	machine.health = 40.0
	machine.powered = false
	_expect(
		_sim_start_repair(SimState.MACHINE_LIGHTS),
		"repair x2: the valid request must start"
	)
	_sim_advance_tick()
	_expect(
		is_equal_approx(_sim_repair_progress(SimState.MACHINE_LIGHTS), 0.5),
		"repair x2: one tick must add two of four divisions (got %f)"
		% _sim_repair_progress(SimState.MACHINE_LIGHTS)
	)
	_expect(
		_sim_is_repairing(SimState.MACHINE_LIGHTS),
		"repair x2: the repair must still be in progress after one tick"
	)
	_sim_advance_tick()
	_expect(
		not _sim_is_repairing(SimState.MACHINE_LIGHTS),
		"repair x2: the second tick must finish the repair"
	)
	_expect(
		is_equal_approx(machine.health, MachineState.MAX_HEALTH),
		"repair x2: completion must restore full health (got %f)" % machine.health
	)
	_expect(
		_event_count(LogEntry.Type.REPAIR) == 1,
		"repair x2: exactly one REPAIR fact must be logged (got %d)"
		% _event_count(LogEntry.Type.REPAIR)
	)

	# v1.1: completed work with no active repair reports zero progress.
	machine.repair_ticks_total = 2
	machine.repair_work_done = 2.0
	_expect(
		_sim_repair_progress(SimState.MACHINE_LIGHTS) == 0.0,
		"repair: completed work with no active repair must report zero progress"
	)
	machine.repair_ticks_total = 0
	machine.repair_work_done = 0.0
	print("machines_smoke: 3) repair divisions, cost and player speed")


## 3b) A broken machine is repaired from zero health without a false revival.
func _check_broken_repair() -> void:
	var registry: MachineDatabase = _build_repair_registry()
	_sim_set_registry(registry)
	_sim_new_game()
	var state: SimState = _sim_state()
	state.tick = 12
	state.set_resource(SimState.ENERGY, 5.0)
	var machine: MachineState = _sim_machine(SimState.MACHINE_LIGHTS)
	machine.health = 0.0
	machine.powered = false
	_expect(machine.is_broken(), "repair broken: the setup machine must be broken")
	_expect(
		_sim_can_repair(SimState.MACHINE_LIGHTS),
		"repair broken: a broken machine with energy must be repairable"
	)
	_expect(
		_sim_start_repair(SimState.MACHINE_LIGHTS),
		"repair broken: start_repair must accept a broken machine"
	)
	_expect(
		machine.repair_ticks_total == 4,
		"repair broken: the sheet divisions must be queued (got %d)"
		% machine.repair_ticks_total
	)
	_sim_advance_tick()
	_expect(
		machine.health == 0.0,
		"repair broken: the first tick must not revive the machine (got %f)"
		% machine.health
	)
	_expect(
		not machine.powered,
		"repair broken: the unfinished repair must keep the machine unpowered"
	)
	_expect(
		is_equal_approx(machine.repair_work_done, 1.0),
		"repair broken: the first tick must add one division (got %f)"
		% machine.repair_work_done
	)
	_expect(
		_event_count(LogEntry.Type.REPAIR) == 0,
		"repair broken: an unfinished repair must not emit REPAIR"
	)

	for i: int in range(3):
		_sim_advance_tick()
	_expect(
		is_equal_approx(machine.health, MachineState.MAX_HEALTH),
		"repair broken: completion must restore full health (got %f)" % machine.health
	)
	_expect(
		machine.powered,
		"repair broken: completion must power the machine again"
	)
	_expect(
		not machine.is_repairing(),
		"repair broken: completion must clear the repair state"
	)
	_expect(
		_event_count(LogEntry.Type.REPAIR) == 1,
		"repair broken: exactly one REPAIR fact must be logged (got %d)"
		% _event_count(LogEntry.Type.REPAIR)
	)
	var entries: Array[LogEntry] = _event_entries(LogEntry.Type.REPAIR)
	if entries.size() == 1:
		_expect(
			entries[0].payload.get(&"machine") == SimState.MACHINE_LIGHTS,
			"repair broken: the REPAIR payload must carry the machine id"
		)
	_sim_advance_tick()
	_expect(
		_event_count(LogEntry.Type.REPAIR) == 1,
		"repair broken: a finished repair must not emit a second REPAIR"
	)
	print("machines_smoke: 3b) broken machine repair")


## 4) Every invalid repair request is rejected without charging energy.
func _check_repair_rejections() -> void:
	var registry: MachineDatabase = _build_repair_registry()
	_sim_set_registry(registry)
	_sim_new_game()
	var state: SimState = _sim_state()
	state.set_resource(SimState.ENERGY, 5.0)
	_expect(
		not _sim_can_repair(SimState.MACHINE_LIGHTS),
		"repair reject: a healthy machine must not be repairable"
	)
	_expect(
		not _sim_start_repair(SimState.MACHINE_LIGHTS),
		"repair reject: start_repair must refuse a healthy machine"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 5.0),
		"repair reject: a healthy machine must charge nothing (got %f)"
		% state.get_resource(SimState.ENERGY)
	)

	var machine: MachineState = _sim_machine(SimState.MACHINE_LIGHTS)
	machine.health = 40.0
	_expect(
		_sim_start_repair(SimState.MACHINE_LIGHTS),
		"repair reject: the setup repair must start"
	)
	var energy_after_start: float = state.get_resource(SimState.ENERGY)
	_expect(
		not _sim_can_repair(SimState.MACHINE_LIGHTS),
		"repair reject: a machine already under repair must be blocked"
	)
	_expect(
		not _sim_start_repair(SimState.MACHINE_LIGHTS),
		"repair reject: a second start must fail"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), energy_after_start),
		"repair reject: a rejected second start must charge nothing (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		machine.repair_ticks_total == 4 and is_zero_approx(machine.repair_work_done),
		"repair reject: a rejected start must not reset the repair"
	)
	_expect(
		_event_count(LogEntry.Type.REPAIR) == 0,
		"repair reject: a rejected start must not emit REPAIR"
	)

	_sim_new_game()
	state = _sim_state()
	state.set_resource(SimState.ENERGY, 1.0)
	machine = _sim_machine(SimState.MACHINE_LIGHTS)
	machine.health = 40.0
	_expect(
		not _sim_can_repair(SimState.MACHINE_LIGHTS),
		"repair reject: insufficient energy must block the repair"
	)
	_expect(
		not _sim_start_repair(SimState.MACHINE_LIGHTS),
		"repair reject: start_repair must refuse without energy"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 1.0),
		"repair reject: a refused repair must charge nothing (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		not _sim_is_repairing(SimState.MACHINE_LIGHTS),
		"repair reject: a refused repair must not start work"
	)

	_sim_new_game()
	state = _sim_state()
	state.set_resource(SimState.ENERGY, 5.0)
	_expect(
		not _sim_can_repair(&"not_a_machine"),
		"repair reject: an unknown machine must not be repairable"
	)
	_expect(
		not _sim_start_repair(&"not_a_machine"),
		"repair reject: start_repair must refuse an unknown machine"
	)
	_expect(
		not _sim_is_repairing(&"not_a_machine"),
		"repair reject: an unknown machine is never repairing"
	)
	_expect(
		_sim_repair_progress(&"not_a_machine") == 0.0,
		"repair reject: an unknown machine reports zero progress"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 5.0),
		"repair reject: an unknown machine must charge nothing (got %f)"
		% state.get_resource(SimState.ENERGY)
	)

	_sim_new_game()
	state = _sim_state()
	state.set_resource(SimState.ENERGY, 5.0)
	machine = _sim_machine(SimState.MACHINE_LIGHTS)
	machine.health = 40.0
	state.game_over = true
	_expect(
		not _sim_can_repair(SimState.MACHINE_LIGHTS),
		"repair reject: a finished run must not allow repairs"
	)
	_expect(
		not _sim_start_repair(SimState.MACHINE_LIGHTS),
		"repair reject: start_repair must refuse a finished run"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 5.0),
		"repair reject: a finished run must charge nothing (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	state.game_over = false
	print("machines_smoke: 4) repair rejections charge nothing")


## 5) Every upgrade effect stat lands on a supporting machine, exactly once.
func _check_upgrades() -> void:
	var registry: MachineDatabase = _build_upgrade_registry()
	_sim_set_registry(registry)
	_sim_new_game()
	var state: SimState = _sim_state()
	state.tick = 37
	state.set_resource(SimState.ENERGY, 20.0)

	_apply_checked(SimState.MACHINE_LIGHTS, &"power_draw")
	_apply_checked(SimState.MACHINE_SOLAR_ARRAY, &"solar_output")
	_apply_checked(SimState.MACHINE_HYDROPONICS, &"food_output")
	_apply_checked(SimState.MACHINE_HYDROPONICS, &"oxygen_output")
	_apply_checked(SimState.MACHINE_WATER_RECYCLER, &"water_output")
	_apply_checked(SimState.MACHINE_LIGHTS, &"degradation")
	_apply_checked(SimState.MACHINE_LIGHTS, &"repair_speed")
	_apply_checked(SimState.MACHINE_LIGHTS, &"move_speed")
	_apply_checked(SimState.MACHINE_LIGHTS, &"hunger_max")
	_apply_checked(SimState.MACHINE_LIGHTS, &"thirst_max")

	var lights: MachineState = _sim_machine(SimState.MACHINE_LIGHTS)
	var solar: MachineState = _sim_machine(SimState.MACHINE_SOLAR_ARRAY)
	var hydroponics: MachineState = _sim_machine(SimState.MACHINE_HYDROPONICS)
	var recycler: MachineState = _sim_machine(SimState.MACHINE_WATER_RECYCLER)

	_expect(
		is_equal_approx(lights.power_delta, -0.1),
		"upgrade: POWER_DRAW must land on power_delta (got %f)" % lights.power_delta
	)
	_expect(
		is_equal_approx(solar.output_deltas.get(SimState.ENERGY, 0.0), 0.5),
		"upgrade: SOLAR_OUTPUT must land on the solar energy output"
	)
	_expect(
		is_equal_approx(hydroponics.output_deltas.get(SimState.FOOD, 0.0), 0.2),
		"upgrade: FOOD_OUTPUT must land on the hydroponics food output"
	)
	_expect(
		is_equal_approx(hydroponics.output_deltas.get(SimState.OXYGEN, 0.0), 0.2),
		"upgrade: OXYGEN_OUTPUT must land on the hydroponics oxygen output"
	)
	_expect(
		is_equal_approx(recycler.output_deltas.get(SimState.WATER, 0.0), 0.2),
		"upgrade: WATER_OUTPUT must land on the recycler water output"
	)
	_expect(
		is_equal_approx(lights.degradation_delta, -0.01),
		"upgrade: DEGRADATION must land on degradation_delta (got %f)"
		% lights.degradation_delta
	)
	_expect(
		is_equal_approx(state.player.repair_speed_multiplier, 1.25),
		"upgrade: REPAIR_SPEED must raise the player multiplier (got %f)"
		% state.player.repair_speed_multiplier
	)
	_expect(
		is_equal_approx(state.player.move_speed_multiplier, 1.5),
		"upgrade: MOVE_SPEED must raise the player multiplier (got %f)"
		% state.player.move_speed_multiplier
	)
	_expect(
		is_equal_approx(state.player.max_hunger, 120.0),
		"upgrade: HUNGER_MAX must raise the maximum (got %f)"
		% state.player.max_hunger
	)
	_expect(
		is_equal_approx(state.hunger, 120.0),
		"upgrade: HUNGER_MAX must raise the current reserve too (got %f)"
		% state.hunger
	)
	_expect(
		is_equal_approx(state.player.max_thirst, 70.0),
		"upgrade: THIRST_MAX must lower the maximum (got %f)"
		% state.player.max_thirst
	)
	_expect(
		is_equal_approx(state.thirst, 70.0),
		"upgrade: THIRST_MAX must clamp the reserve to the new maximum (got %f)"
		% state.thirst
	)
	var lights_ids: Array[StringName] = [
		&"power_draw", &"degradation", &"repair_speed", &"move_speed",
		&"hunger_max", &"thirst_max",
	]
	_expect(
		lights.applied_upgrades == lights_ids,
		"upgrade: every lights upgrade id must be recorded in order (got %s)"
		% str(lights.applied_upgrades)
	)
	_expect(
		lights.upgrade_level == lights_ids.size(),
		"upgrade: lights level must count its applied upgrades (got %d)"
		% lights.upgrade_level
	)
	_expect(
		solar.applied_upgrades.size() == 1 and solar.upgrade_level == 1,
		"upgrade: solar_array must record its single upgrade"
	)
	_expect(
		hydroponics.applied_upgrades.size() == 2 and hydroponics.upgrade_level == 2,
		"upgrade: hydroponics must record its two upgrades"
	)
	_expect(
		recycler.applied_upgrades.size() == 1 and recycler.upgrade_level == 1,
		"upgrade: water_recycler must record its single upgrade"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 15.0),
		"upgrade: ten costs of 0.5 must leave 15.0 energy (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		_event_count(LogEntry.Type.UPGRADE) == 10,
		"upgrade: one UPGRADE fact per application (got %d)"
		% _event_count(LogEntry.Type.UPGRADE)
	)
	_expect(
		state.tick == 37,
		"upgrade: applying an upgrade must not advance the clock (got %d)" % state.tick
	)

	var expected_machine: Dictionary[StringName, StringName] = {
		&"power_draw": SimState.MACHINE_LIGHTS,
		&"solar_output": SimState.MACHINE_SOLAR_ARRAY,
		&"food_output": SimState.MACHINE_HYDROPONICS,
		&"oxygen_output": SimState.MACHINE_HYDROPONICS,
		&"water_output": SimState.MACHINE_WATER_RECYCLER,
		&"degradation": SimState.MACHINE_LIGHTS,
		&"repair_speed": SimState.MACHINE_LIGHTS,
		&"move_speed": SimState.MACHINE_LIGHTS,
		&"hunger_max": SimState.MACHINE_LIGHTS,
		&"thirst_max": SimState.MACHINE_LIGHTS,
	}
	var upgrade_entries: Array[LogEntry] = _event_entries(LogEntry.Type.UPGRADE)
	var seen: Dictionary[StringName, int] = {}
	var payloads_ok: bool = true
	var ticks_ok: bool = true
	for entry: LogEntry in upgrade_entries:
		var raw_machine: Variant = entry.payload.get(&"machine")
		var machine_name: StringName = raw_machine
		var raw_upgrade: Variant = entry.payload.get(&"upgrade")
		var upgrade_name: StringName = raw_upgrade
		if not expected_machine.has(upgrade_name):
			payloads_ok = false
			continue
		if expected_machine[upgrade_name] != machine_name:
			payloads_ok = false
		seen[upgrade_name] = seen.get(upgrade_name, 0) + 1
		if entry.tick != 37:
			ticks_ok = false
	if seen.size() != expected_machine.size():
		payloads_ok = false
	for upgrade_name: Variant in expected_machine.keys():
		var upgrade_key: StringName = upgrade_name
		if seen.get(upgrade_key, 0) != 1:
			payloads_ok = false
	_expect(payloads_ok, "upgrade: each UPGRADE payload must be unique and well formed")
	_expect(
		ticks_ok,
		"upgrade: every UPGRADE fact must carry the state tick at apply time (expected 37)"
	)

	state.set_resource(SimState.ENERGY, 10.0)
	_expect(
		not _sim_can_upgrade(SimState.MACHINE_LIGHTS, &"repair_speed"),
		"upgrade: a repeated upgrade must be blocked"
	)
	_expect(
		not _sim_apply_upgrade(SimState.MACHINE_LIGHTS, &"repair_speed"),
		"upgrade: a repeated application must fail"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 10.0),
		"upgrade: a refused application must charge nothing (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		is_equal_approx(state.player.repair_speed_multiplier, 1.25),
		"upgrade: a repeated upgrade must not stack (got %f)"
		% state.player.repair_speed_multiplier
	)
	_expect(
		lights.upgrade_level == lights_ids.size()
		and lights.applied_upgrades.size() == lights_ids.size(),
		"upgrade: a repeated upgrade must not change the counters"
	)
	_expect(
		_event_count(LogEntry.Type.UPGRADE) == 10,
		"upgrade: a refused application must not log a fact"
	)
	print("machines_smoke: 5) upgrade effects and single application")


## 5b) Broken machines, empty energy and unknown ids reject upgrades without cost.
func _check_upgrade_rejections() -> void:
	var registry: MachineDatabase = _build_upgrade_registry()
	_sim_set_registry(registry)
	_sim_new_game()
	var state: SimState = _sim_state()
	state.set_resource(SimState.ENERGY, 10.0)
	var machine: MachineState = _sim_machine(SimState.MACHINE_LIGHTS)
	machine.health = 0.0
	_expect(
		not _sim_can_upgrade(SimState.MACHINE_LIGHTS, &"repair_speed"),
		"upgrade reject: a broken machine must not take upgrades"
	)
	_expect(
		not _sim_apply_upgrade(SimState.MACHINE_LIGHTS, &"repair_speed"),
		"upgrade reject: applying on a broken machine must fail"
	)
	_expect(
		machine.applied_upgrades.is_empty(),
		"upgrade reject: a refused upgrade must not be recorded"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 10.0),
		"upgrade reject: a broken machine must charge nothing (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		_event_count(LogEntry.Type.UPGRADE) == 0,
		"upgrade reject: a broken machine must not log an UPGRADE"
	)

	_sim_new_game()
	state = _sim_state()
	state.set_resource(SimState.ENERGY, 0.1)
	machine = _sim_machine(SimState.MACHINE_LIGHTS)
	_expect(
		not _sim_can_upgrade(SimState.MACHINE_LIGHTS, &"repair_speed"),
		"upgrade reject: insufficient energy must block the upgrade"
	)
	_expect(
		not _sim_apply_upgrade(SimState.MACHINE_LIGHTS, &"repair_speed"),
		"upgrade reject: applying without energy must fail"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 0.1),
		"upgrade reject: an unaffordable upgrade must charge nothing (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		machine.applied_upgrades.is_empty(),
		"upgrade reject: an unaffordable upgrade must not be recorded"
	)
	_expect(
		_event_count(LogEntry.Type.UPGRADE) == 0,
		"upgrade reject: an unaffordable upgrade must not log a fact"
	)

	_sim_new_game()
	state = _sim_state()
	state.set_resource(SimState.ENERGY, 10.0)
	_expect(
		not _sim_can_upgrade(&"not_a_machine", &"repair_speed"),
		"upgrade reject: an unknown machine must not take upgrades"
	)
	_expect(
		not _sim_apply_upgrade(&"not_a_machine", &"repair_speed"),
		"upgrade reject: applying on an unknown machine must fail"
	)
	_expect(
		not _sim_can_upgrade(SimState.MACHINE_LIGHTS, &"not_an_upgrade"),
		"upgrade reject: an unknown upgrade must be rejected"
	)
	_expect(
		not _sim_apply_upgrade(SimState.MACHINE_LIGHTS, &"not_an_upgrade"),
		"upgrade reject: applying an unknown upgrade must fail"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 10.0),
		"upgrade reject: unknown ids must charge nothing (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		_event_count(LogEntry.Type.UPGRADE) == 0,
		"upgrade reject: unknown ids must not log a fact"
	)

	state.game_over = true
	_expect(
		not _sim_can_upgrade(SimState.MACHINE_LIGHTS, &"repair_speed"),
		"upgrade reject: a finished run must not allow upgrades"
	)
	_expect(
		not _sim_apply_upgrade(SimState.MACHINE_LIGHTS, &"repair_speed"),
		"upgrade reject: applying after game over must fail"
	)
	state.game_over = false

	# v1.1: an effect the machine cannot express is rejected without cost.
	_sim_set_registry(_build_incompatible_upgrade_registry())
	_sim_new_game()
	state = _sim_state()
	state.set_resource(SimState.ENERGY, 10.0)
	machine = _sim_machine(SimState.MACHINE_LIGHTS)
	_expect(
		not _sim_can_upgrade(SimState.MACHINE_LIGHTS, &"solar_output"),
		"upgrade reject: an incompatible effect must be blocked"
	)
	_expect(
		not _sim_apply_upgrade(SimState.MACHINE_LIGHTS, &"solar_output"),
		"upgrade reject: applying an incompatible effect must fail"
	)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), 10.0),
		"upgrade reject: an incompatible effect must charge nothing (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		machine.applied_upgrades.is_empty(),
		"upgrade reject: an incompatible effect must not be recorded"
	)
	_expect(
		machine.output_deltas.is_empty(),
		"upgrade reject: an incompatible effect must not land a delta"
	)
	_expect(
		_event_count(LogEntry.Type.UPGRADE) == 0,
		"upgrade reject: an incompatible effect must not log a fact"
	)
	print("machines_smoke: 5b) upgrade rejections charge nothing")


## 5d) Validators report invalid ids, resources, effects and zero deltas.
func _check_validators() -> void:
	var bad_consumption: MachineConsumption = MachineConsumption.new()
	bad_consumption.resource = &"plasma"
	bad_consumption.amount_per_tick = -1.0
	var consumption_problems: Array[String] = bad_consumption.validate()
	_expect(
		consumption_problems.size() >= 2,
		"validators: an unknown resource and a negative amount must be reported (got %s)"
		% str(consumption_problems)
	)
	_expect(
		_has_message(consumption_problems, "resource"),
		"validators: the consumption resource problem must be reported"
	)
	_expect(
		_has_message(consumption_problems, "amount_per_tick"),
		"validators: the negative amount problem must be reported"
	)

	var bad_upgrade: UpgradeData = UpgradeData.new()
	bad_upgrade.delta = 0.0
	bad_upgrade.energy_cost = -1.0
	var upgrade_problems: Array[String] = bad_upgrade.validate()
	_expect(
		upgrade_problems.size() >= 3,
		"validators: an empty id, a zero delta and a negative cost must be reported (got %s)"
		% str(upgrade_problems)
	)
	_expect(
		_has_message(upgrade_problems, "id is empty"),
		"validators: the empty upgrade id must be reported"
	)
	_expect(
		_has_message(upgrade_problems, "delta must not be zero"),
		"validators: the zero upgrade delta must be reported"
	)
	_expect(
		_has_message(upgrade_problems, "energy_cost"),
		"validators: the negative upgrade cost must be reported"
	)

	var lights: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 1, 0.0)
	var solar: MachineData = _machine_sheet(SimState.MACHINE_SOLAR_ARRAY, 1, 0.0)
	var hydroponics: MachineData = _machine_sheet(SimState.MACHINE_HYDROPONICS, 1, 0.0)
	var recycler: MachineData = _machine_sheet(SimState.MACHINE_WATER_RECYCLER, 1, 0.0)
	_expect(
		lights.supports_effect(UpgradeData.EffectStat.POWER_DRAW)
		and lights.supports_effect(UpgradeData.EffectStat.DEGRADATION)
		and lights.supports_effect(UpgradeData.EffectStat.REPAIR_SPEED),
		"validators: any machine must support power, degradation and player effects"
	)
	_expect(
		not lights.supports_effect(UpgradeData.EffectStat.SOLAR_OUTPUT)
		and not lights.supports_effect(UpgradeData.EffectStat.FOOD_OUTPUT)
		and not lights.supports_effect(UpgradeData.EffectStat.OXYGEN_OUTPUT)
		and not lights.supports_effect(UpgradeData.EffectStat.WATER_OUTPUT),
		"validators: lights must not support an output effect"
	)
	_expect(
		solar.supports_effect(UpgradeData.EffectStat.SOLAR_OUTPUT)
		and not solar.supports_effect(UpgradeData.EffectStat.FOOD_OUTPUT),
		"validators: solar_array must only support the solar output"
	)
	_expect(
		hydroponics.supports_effect(UpgradeData.EffectStat.FOOD_OUTPUT)
		and hydroponics.supports_effect(UpgradeData.EffectStat.OXYGEN_OUTPUT)
		and not hydroponics.supports_effect(UpgradeData.EffectStat.SOLAR_OUTPUT)
		and not hydroponics.supports_effect(UpgradeData.EffectStat.WATER_OUTPUT),
		"validators: hydroponics must support food and oxygen only"
	)
	_expect(
		recycler.supports_effect(UpgradeData.EffectStat.WATER_OUTPUT)
		and not recycler.supports_effect(UpgradeData.EffectStat.FOOD_OUTPUT),
		"validators: water_recycler must only support the water output"
	)

	var database: MachineDatabase = MachineDatabase.new()
	database.machines.append(null)
	var empty_id: MachineData = MachineData.new()
	empty_id.display_name_key = &"empty"
	database.machines.append(empty_id)
	database.machines.append(_machine_sheet(SimState.MACHINE_LIGHTS, 1, 0.0))
	database.machines.append(_machine_sheet(SimState.MACHINE_LIGHTS, 1, 0.0))
	var duplicate_resource: MachineData = _machine_sheet(
		SimState.MACHINE_HYDROPONICS, 1, 0.0
	)
	_add_consumption(duplicate_resource, SimState.OXYGEN, 0.1)
	_add_consumption(duplicate_resource, SimState.OXYGEN, 0.2)
	database.machines.append(duplicate_resource)
	var incompatible: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 1, 0.0)
	_add_upgrade(
		incompatible,
		&"solar_output",
		UpgradeData.EffectStat.SOLAR_OUTPUT,
		1.0,
		0.0
	)
	database.machines.append(incompatible)
	var zero_delta: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 1, 0.0)
	_add_upgrade(zero_delta, &"zero", UpgradeData.EffectStat.REPAIR_SPEED, 0.0, 0.0)
	database.machines.append(zero_delta)

	var messages: Array[String] = database.validate()
	_expect(
		not messages.is_empty(),
		"validators: an invalid database must report messages"
	)
	_expect(
		messages.size() >= 7,
		"validators: every invalid row must report a problem (got %d)" % messages.size()
	)
	_expect(
		_has_message(messages, "row is null"),
		"validators: a null row must be reported"
	)
	_expect(
		_has_message(messages, "id is empty"),
		"validators: an empty machine id must be reported"
	)
	_expect(
		_has_message(messages, "id is duplicated"),
		"validators: a duplicated machine id must be reported"
	)
	_expect(
		_has_message(messages, "resource 'oxygen' is duplicated"),
		"validators: a duplicated consumption resource must be reported"
	)
	_expect(
		_has_message(messages, "is not supported by this machine"),
		"validators: an incompatible effect must be reported"
	)
	_expect(
		_has_message(messages, "delta must not be zero"),
		"validators: a zero upgrade delta must be reported"
	)
	print("machines_smoke: 5d) invalid-data validators report messages")


## 5c) Upgrades applied through the API feed the real tick values.
func _check_effective_tick() -> void:
	var registry: MachineDatabase = _build_effect_registry()
	_sim_set_registry(registry)
	_sim_new_game()
	var state: SimState = _sim_state()
	state.set_resource(SimState.ENERGY, 5.0)
	state.set_resource(SimState.FOOD, 5.0)
	state.set_resource(SimState.OXYGEN, 5.0)
	state.set_resource(SimState.WATER, 5.0)
	_expect(
		_sim_apply_upgrade(SimState.MACHINE_SOLAR_ARRAY, &"solar_plus"),
		"effective: the solar upgrade must be applied"
	)
	_expect(
		_sim_apply_upgrade(SimState.MACHINE_HYDROPONICS, &"food_plus"),
		"effective: the food upgrade must be applied"
	)
	_expect(
		_sim_apply_upgrade(SimState.MACHINE_HYDROPONICS, &"oxygen_plus"),
		"effective: the oxygen upgrade must be applied"
	)
	_expect(
		_sim_apply_upgrade(SimState.MACHINE_WATER_RECYCLER, &"water_plus"),
		"effective: the water upgrade must be applied"
	)
	_expect(
		_sim_apply_upgrade(SimState.MACHINE_LIGHTS, &"power_minus"),
		"effective: the power upgrade must be applied"
	)
	_expect(
		_sim_apply_upgrade(SimState.MACHINE_LIGHTS, &"degrade_less"),
		"effective: the degradation upgrade must be applied"
	)

	_sim_advance_tick()

	var solar_base: float = _economy.get_value(&"solar_output_per_tick", 0.0)
	var food_base: float = _economy.get_value(&"hydroponics_food_output_per_tick", 0.0)
	var oxygen_base: float = _economy.get_value(&"hydroponics_oxygen_output_per_tick", 0.0)
	var water_base: float = _economy.get_value(&"water_recycler_output_per_tick", 0.0)
	var crew_food: float = _economy.get_value(&"food_consumption_per_tick", 0.0)
	var crew_oxygen: float = _economy.get_value(&"oxygen_consumption_per_tick", 0.0)
	var crew_water: float = _economy.get_value(&"water_consumption_per_tick", 0.0)
	var base_wear: float = _economy.get_value(&"machine_lights_degradation_per_tick", 0.0)

	_expect(
		is_equal_approx(
			state.get_resource(SimState.ENERGY), 5.0 + solar_base + 0.5 - 0.1
		),
		"effective: solar output and reduced power draw must reach the tick (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		is_equal_approx(
			state.get_resource(SimState.FOOD), 5.0 + food_base + 0.2 - crew_food
		),
		"effective: the food output delta must reach the tick (got %f)"
		% state.get_resource(SimState.FOOD)
	)
	_expect(
		is_equal_approx(
			state.get_resource(SimState.OXYGEN), 5.0 + oxygen_base + 0.2 - crew_oxygen
		),
		"effective: the oxygen output delta must reach the tick (got %f)"
		% state.get_resource(SimState.OXYGEN)
	)
	_expect(
		is_equal_approx(
			state.get_resource(SimState.WATER), 5.0 + water_base + 0.2 - crew_water
		),
		"effective: the water output delta must reach the tick (got %f)"
		% state.get_resource(SimState.WATER)
	)
	var lights: MachineState = _sim_machine(SimState.MACHINE_LIGHTS)
	_expect(
		is_equal_approx(
			lights.health, MachineState.MAX_HEALTH - maxf(0.0, base_wear - 0.01)
		),
		"effective: the reduced wear must reach the tick (got %f)" % lights.health
	)
	print("machines_smoke: 5c) upgrades feed the effective tick values")


## 6) A new run clears repairs, upgrades and player statistics from any machine.
func _check_restart() -> void:
	var registry: MachineDatabase = _build_upgrade_registry()
	_sim_set_registry(registry)
	_sim_new_game()
	var state: SimState = _sim_state()
	state.tick = 12
	state.set_resource(SimState.ENERGY, 10.0)
	var lights: MachineState = _sim_machine(SimState.MACHINE_LIGHTS)
	lights.health = 40.0
	_expect(
		_sim_start_repair(SimState.MACHINE_LIGHTS),
		"restart: the setup repair must start"
	)
	_expect(
		_sim_apply_upgrade(SimState.MACHINE_LIGHTS, &"repair_speed"),
		"restart: the setup upgrade must be applied"
	)
	_sim_advance_tick()

	for id: StringName in SimState.MACHINE_IDS:
		var machine: MachineState = _machine_of(state, id)
		machine.health = 1.0
		machine.powered = false
		machine.upgrade_level = 3
		machine.repair_ticks_total = 2
		machine.repair_work_done = 1.0
		machine.applied_upgrades.append(&"dirty")
		machine.power_delta = 1.0
		machine.degradation_delta = 1.0
		machine.output_deltas[SimState.ENERGY] = 1.0
	state.player.repair_speed_multiplier = 3.0
	state.player.move_speed_multiplier = 3.0
	state.player.max_hunger = 250.0
	state.player.max_thirst = 250.0
	state.hunger = 200.0
	state.thirst = 200.0
	state.tick = 99
	state.game_over = true
	state.death_cause = &"dirty"

	_sim_new_game()
	state = _sim_state()
	var expected_repair: float = maxf(
		0.1, _economy.get_value(&"player_repair_speed_multiplier", 1.0)
	)
	var expected_move: float = maxf(
		0.1, _economy.get_value(&"player_move_speed_multiplier", 1.0)
	)
	var expected_hunger: float = maxf(
		1.0, _economy.get_value(&"player_max_hunger", 100.0)
	)
	var expected_thirst: float = maxf(
		1.0, _economy.get_value(&"player_max_thirst", 100.0)
	)
	_expect(
		is_equal_approx(state.player.repair_speed_multiplier, expected_repair),
		"restart: repair speed must return to base (got %f)"
		% state.player.repair_speed_multiplier
	)
	_expect(
		is_equal_approx(state.player.move_speed_multiplier, expected_move),
		"restart: move speed must return to base (got %f)"
		% state.player.move_speed_multiplier
	)
	_expect(
		is_equal_approx(state.player.max_hunger, expected_hunger),
		"restart: max hunger must return to base (got %f)"
		% state.player.max_hunger
	)
	_expect(
		is_equal_approx(state.player.max_thirst, expected_thirst),
		"restart: max thirst must return to base (got %f)"
		% state.player.max_thirst
	)
	_expect(
		is_equal_approx(
			state.hunger,
			clampf(
				_economy.get_value(&"initial_hunger", 100.0), 0.0, expected_hunger
			)
		),
		"restart: hunger must return to the clamped initial row (got %f)"
		% state.hunger
	)
	_expect(
		is_equal_approx(
			state.thirst,
			clampf(
				_economy.get_value(&"initial_thirst", 100.0), 0.0, expected_thirst
			)
		),
		"restart: thirst must return to the clamped initial row (got %f)"
		% state.thirst
	)

	for id: StringName in SimState.MACHINE_IDS:
		var machine: MachineState = _machine_of(state, id)
		var expected_health: float = clampf(
			_economy.get_value(
				StringName("machine_" + String(id) + "_initial_health"),
				100.0
			),
			0.0,
			MachineState.MAX_HEALTH
		)
		_expect(
			is_equal_approx(machine.health, expected_health),
			"restart: %s health must return to its initial row (got %f)"
			% [id, machine.health]
		)
		_expect(machine.powered, "restart: %s must be powered" % id)
		_expect(machine.upgrade_level == 0, "restart: %s level must be zero" % id)
		_expect(
			machine.repair_ticks_total == 0,
			"restart: %s must have no repair divisions" % id
		)
		_expect(
			is_zero_approx(machine.repair_work_done),
			"restart: %s must have no repair work" % id
		)
		_expect(
			machine.applied_upgrades.is_empty(),
			"restart: %s must have no applied upgrades" % id
		)
		_expect(
			is_zero_approx(machine.power_delta)
			and is_zero_approx(machine.degradation_delta)
			and machine.output_deltas.is_empty(),
			"restart: %s must have no upgrade deltas" % id
		)
		_expect(
			not machine.is_repairing(),
			"restart: %s must not report an active repair" % id
		)
	_expect(state.tick == 0, "restart: the tick must be zero (got %d)" % state.tick)
	_expect(not state.game_over, "restart: the run must be alive again")
	_expect(
		_event_count(LogEntry.Type.REPAIR) == 0
		and _event_count(LogEntry.Type.UPGRADE) == 0,
		"restart: the ledger must be empty again"
	)
	print("machines_smoke: 6) new_game restores machines and player stats")


## 7) The real tick consumes from the registry, directly and through GameSim.
func _check_integration() -> void:
	_sim_set_registry(_real_registry)
	_sim_new_game()
	var state: SimState = _sim_state()
	state.tick = 12
	state.set_resource(SimState.ENERGY, 5.0)
	_sim_advance_tick()
	var expected: float = 5.0 - _total_energy_draw(_real_registry)
	_expect(
		is_equal_approx(state.get_resource(SimState.ENERGY), expected),
		"integration: GameSim.advance_tick must use the real registry (got %f)"
		% state.get_resource(SimState.ENERGY)
	)
	_expect(
		state.tick == 13,
		"integration: GameSim.advance_tick must advance the clock (got %d)" % state.tick
	)

	var direct: SimState = _fresh_state()
	direct.tick = 12
	direct.set_resource(SimState.ENERGY, 5.0)
	var facts: Array[LogEntry] = SimTick.step(direct, _economy, _real_registry)
	_expect(
		facts != null,
		"integration: SimTick.step must return a fact array"
	)
	_expect(
		is_equal_approx(direct.get_resource(SimState.ENERGY), expected),
		"integration: SimTick.step with the real registry must match (got %f)"
		% direct.get_resource(SimState.ENERGY)
	)
	_expect(
		is_equal_approx(
			direct.get_resource(SimState.ENERGY), state.get_resource(SimState.ENERGY)
		),
		"integration: direct and GameSim ticks must agree"
	)
	_expect(
		direct.tick == 13,
		"integration: SimTick.step must advance the clock (got %d)" % direct.tick
	)
	print("machines_smoke: 7) tick integration with the real registry")


## Fresh state seeded from the real economy database.
func _fresh_state() -> SimState:
	var state: SimState = SimState.new()
	state.reset_from_economy(_economy)
	return state


## Machine state by id; the caller guarantees the machine exists.
func _machine_of(state: SimState, id: StringName) -> MachineState:
	var machine: MachineState = state.machines[id]
	return machine


## Typed single-id list for _operate_only.
func _only(id: StringName) -> Array[StringName]:
	var ids: Array[StringName] = [id]
	return ids


## Powers off every machine.
func _operate_none(state: SimState) -> void:
	for id: StringName in SimState.MACHINE_IDS:
		_machine_of(state, id).powered = false


## Powers off every machine except the listed ids.
func _operate_only(state: SimState, ids: Array[StringName]) -> void:
	for id: StringName in SimState.MACHINE_IDS:
		_machine_of(state, id).powered = ids.has(id)


## Energy the machine sheet declares per tick; 0 when there is no energy entry.
func _energy_draw(registry: MachineDatabase, id: StringName) -> float:
	var data: MachineData = registry.get_machine(id)
	if data == null:
		return 0.0
	var total: float = 0.0
	for entry: MachineConsumption in data.consumption:
		if entry != null and entry.resource == SimState.ENERGY:
			total += entry.amount_per_tick
	return total


## Sum of the energy entries of every sheet in the registry.
func _total_energy_draw(registry: MachineDatabase) -> float:
	var total: float = 0.0
	for data: MachineData in registry.machines:
		if data == null:
			continue
		for entry: MachineConsumption in data.consumption:
			if entry != null and entry.resource == SimState.ENERGY:
				total += entry.amount_per_tick
	return total


## Blank valid sheet with the given repair parameters.
func _machine_sheet(id: StringName, repair_ticks: int, repair_cost: float) -> MachineData:
	var data: MachineData = MachineData.new()
	data.id = id
	data.display_name_key = id
	data.repair_ticks = repair_ticks
	data.repair_energy_cost = repair_cost
	return data


## Appends one consumption entry to a sheet.
func _add_consumption(
	data: MachineData, resource_id: StringName, amount: float
) -> void:
	var entry: MachineConsumption = MachineConsumption.new()
	entry.resource = resource_id
	entry.amount_per_tick = amount
	data.consumption.append(entry)


## Appends one upgrade entry to a sheet.
func _add_upgrade(
	data: MachineData,
	upgrade_id: StringName,
	stat: UpgradeData.EffectStat,
	delta: float,
	energy_cost: float
) -> void:
	var upgrade: UpgradeData = UpgradeData.new()
	upgrade.id = upgrade_id
	upgrade.effect_stat = stat
	upgrade.delta = delta
	upgrade.energy_cost = energy_cost
	data.upgrades.append(upgrade)


## Four-division repair sheet that charges 1.5 energy.
func _build_repair_registry() -> MachineDatabase:
	var lights: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 4, 1.5)
	var registry: MachineDatabase = MachineDatabase.new()
	registry.machines.append(lights)
	return registry


## Sheets with every upgrade effect on a machine that supports it; each costs 0.5.
func _build_upgrade_registry() -> MachineDatabase:
	var registry: MachineDatabase = MachineDatabase.new()

	var lights: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 4, 1.5)
	_add_upgrade(lights, &"power_draw", UpgradeData.EffectStat.POWER_DRAW, -0.1, 0.5)
	_add_upgrade(lights, &"degradation", UpgradeData.EffectStat.DEGRADATION, -0.01, 0.5)
	_add_upgrade(lights, &"repair_speed", UpgradeData.EffectStat.REPAIR_SPEED, 0.25, 0.5)
	_add_upgrade(lights, &"move_speed", UpgradeData.EffectStat.MOVE_SPEED, 0.5, 0.5)
	_add_upgrade(lights, &"hunger_max", UpgradeData.EffectStat.HUNGER_MAX, 20.0, 0.5)
	_add_upgrade(lights, &"thirst_max", UpgradeData.EffectStat.THIRST_MAX, -30.0, 0.5)
	registry.machines.append(lights)

	var solar: MachineData = _machine_sheet(SimState.MACHINE_SOLAR_ARRAY, 1, 1.0)
	_add_upgrade(solar, &"solar_output", UpgradeData.EffectStat.SOLAR_OUTPUT, 0.5, 0.5)
	registry.machines.append(solar)

	var hydroponics: MachineData = _machine_sheet(SimState.MACHINE_HYDROPONICS, 1, 1.0)
	_add_upgrade(hydroponics, &"food_output", UpgradeData.EffectStat.FOOD_OUTPUT, 0.2, 0.5)
	_add_upgrade(
		hydroponics, &"oxygen_output", UpgradeData.EffectStat.OXYGEN_OUTPUT, 0.2, 0.5
	)
	registry.machines.append(hydroponics)

	var recycler: MachineData = _machine_sheet(SimState.MACHINE_WATER_RECYCLER, 1, 1.0)
	_add_upgrade(recycler, &"water_output", UpgradeData.EffectStat.WATER_OUTPUT, 0.2, 0.5)
	registry.machines.append(recycler)

	return registry


## Lights sheet with an incompatible solar upgrade, used by the rejection checks.
func _build_incompatible_upgrade_registry() -> MachineDatabase:
	var lights: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 1, 1.0)
	_add_upgrade(
		lights, &"solar_output", UpgradeData.EffectStat.SOLAR_OUTPUT, 1.0, 0.5
	)
	var registry: MachineDatabase = MachineDatabase.new()
	registry.machines.append(lights)
	return registry


## Lights sheet with one consumption entry of the given resource and amount.
func _build_single_consumption_registry(
	resource_id: StringName, amount: float
) -> MachineDatabase:
	var lights: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 1, 1.0)
	_add_consumption(lights, resource_id, amount)
	var registry: MachineDatabase = MachineDatabase.new()
	registry.machines.append(lights)
	return registry


## Lights sheet with two energy entries; only the first one may count.
func _build_duplicate_energy_registry() -> MachineDatabase:
	var lights: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 1, 1.0)
	_add_consumption(lights, SimState.ENERGY, 0.2)
	_add_consumption(lights, SimState.ENERGY, 0.2)
	var registry: MachineDatabase = MachineDatabase.new()
	registry.machines.append(lights)
	return registry


## Lights sheet that consumes food and oxygen, used by the consumption checks.
func _build_non_energy_registry() -> MachineDatabase:
	var lights: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 1, 1.0)
	_add_consumption(lights, SimState.FOOD, 0.5)
	_add_consumption(lights, SimState.OXYGEN, 0.3)
	var registry: MachineDatabase = MachineDatabase.new()
	registry.machines.append(lights)
	return registry


## One sheet per producing machine, each with the upgrade that changes its output.
func _build_effect_registry() -> MachineDatabase:
	var registry: MachineDatabase = MachineDatabase.new()

	var solar: MachineData = _machine_sheet(SimState.MACHINE_SOLAR_ARRAY, 1, 1.0)
	_add_upgrade(solar, &"solar_plus", UpgradeData.EffectStat.SOLAR_OUTPUT, 0.5, 0.0)
	registry.machines.append(solar)

	var hydroponics: MachineData = _machine_sheet(SimState.MACHINE_HYDROPONICS, 1, 1.0)
	_add_upgrade(hydroponics, &"food_plus", UpgradeData.EffectStat.FOOD_OUTPUT, 0.2, 0.0)
	_add_upgrade(hydroponics, &"oxygen_plus", UpgradeData.EffectStat.OXYGEN_OUTPUT, 0.2, 0.0)
	registry.machines.append(hydroponics)

	var recycler: MachineData = _machine_sheet(SimState.MACHINE_WATER_RECYCLER, 1, 1.0)
	_add_upgrade(recycler, &"water_plus", UpgradeData.EffectStat.WATER_OUTPUT, 0.2, 0.0)
	registry.machines.append(recycler)

	var lights: MachineData = _machine_sheet(SimState.MACHINE_LIGHTS, 1, 1.0)
	_add_consumption(lights, SimState.ENERGY, 0.2)
	_add_upgrade(lights, &"power_minus", UpgradeData.EffectStat.POWER_DRAW, -0.1, 0.0)
	_add_upgrade(lights, &"degrade_less", UpgradeData.EffectStat.DEGRADATION, -0.01, 0.0)
	registry.machines.append(lights)

	return registry


## Asserts that an upgrade is applicable and applies it through GameSim.
func _apply_checked(machine_id: StringName, upgrade_id: StringName) -> void:
	_expect(
		_sim_can_upgrade(machine_id, upgrade_id),
		"upgrade: %s/%s must be applicable" % [machine_id, upgrade_id]
	)
	_expect(
		_sim_apply_upgrade(machine_id, upgrade_id),
		"upgrade: %s/%s must be applied" % [machine_id, upgrade_id]
	)


## True when any message contains the given fragment.
func _has_message(messages: Array[String], needle: String) -> bool:
	for message: String in messages:
		if message.contains(needle):
			return true
	return false


## Injects a registry into the live GameSim autoload.
func _sim_set_registry(registry: MachineDatabase) -> void:
	_game_sim.set(&"_machines", registry)


## Current GameSim state, typed.
func _sim_state() -> SimState:
	var state_value: Variant = _game_sim.get(&"state")
	return state_value as SimState


## Starts a clean run through the GameSim API.
func _sim_new_game() -> void:
	_game_sim.call(&"new_game")


## Machine sheet through the GameSim API.
func _sim_machine_data(id: StringName) -> MachineData:
	return _game_sim.call(&"get_machine_data", id) as MachineData


## Machine state through the GameSim API.
func _sim_machine(id: StringName) -> MachineState:
	return _game_sim.call(&"get_machine_state", id) as MachineState


func _sim_can_repair(id: StringName) -> bool:
	return bool(_game_sim.call(&"can_start_repair", id))


func _sim_start_repair(id: StringName) -> bool:
	return bool(_game_sim.call(&"start_repair", id))


func _sim_is_repairing(id: StringName) -> bool:
	return bool(_game_sim.call(&"is_repairing", id))


func _sim_repair_progress(id: StringName) -> float:
	return float(_game_sim.call(&"repair_progress", id))


func _sim_can_upgrade(id: StringName, upgrade_id: StringName) -> bool:
	return bool(_game_sim.call(&"can_apply_upgrade", id, upgrade_id))


func _sim_apply_upgrade(id: StringName, upgrade_id: StringName) -> bool:
	return bool(_game_sim.call(&"apply_upgrade", id, upgrade_id))


func _sim_advance_tick() -> void:
	_game_sim.call(&"advance_tick")


## Count of ledger entries of one type.
func _event_count(type: LogEntry.Type) -> int:
	var count: Variant = _event_log.call(&"get_count", type)
	return int(count)


## Copies of the ledger entries of one type, typed.
func _event_entries(type: LogEntry.Type) -> Array[LogEntry]:
	var result: Array[LogEntry] = []
	var raw: Variant = _event_log.call(&"get_entries_by_type", type)
	if typeof(raw) != TYPE_ARRAY:
		return result
	for item: Variant in raw:
		var entry: LogEntry = item as LogEntry
		if entry != null:
			result.append(entry)
	return result


## Restores the real registry, reports the counters and quits with the result.
func _finish() -> void:
	if _game_sim != null and _real_registry != null:
		_game_sim.set(&"_machines", _real_registry)
	print(
		"machines_smoke: %d checks, %d failures, %s"
		% [_checks, _failures, "OK" if _failures == 0 else "FAIL"]
	)
	quit(1 if _failures > 0 else 0)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		return
	_failures += 1
	push_error("machines_smoke FAILED: " + message)
