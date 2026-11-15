class_name HydroponicsStation
extends MachineStation

## Hydroponics machine in the world: owns the cultivation state of its twelve
## cells and advances it with the simulation tick, but only while the machine is
## healthy, powered and the run is still alive.
##
## The growth lives in HydroponicsState, not in the tick: the station is a
## subscriber, so the simulation core stays untouched and every station or demo
## owns an independent state.

const MACHINE_ID: StringName = &"hydroponics"
const HARVEST_FOOD_ROW: StringName = &"hydroponics_harvest_food"
const HARVEST_FOOD_FALLBACK: float = 2.5

## Panel shown by the machine panel as an extra screen (cultivation grid).
@export var extra_panel_scene: PackedScene

## Cultivation state of this station. It is created in _ready() before the base
## runs, because the first refresh of the base happens there.
var cultivation: HydroponicsState = null


func _ready() -> void:
	cultivation = HydroponicsState.new(GameSim.state.run_seed)
	machine_id = MACHINE_ID
	super._ready()
	GameSim.game_reset.connect(_on_game_reset)


## A new run starts with every cell empty and the harvest counter at zero.
func _on_game_reset() -> void:
	if cultivation == null:
		return
	cultivation.reset()


## One simulation tick: the base refreshes the silhouette and the cells grow
## only while the station can cultivate.
func _on_tick_advanced(tick: int) -> void:
	super._on_tick_advanced(tick)
	if not can_cultivate():
		return
	cultivation.advance_tick()


## True when the machine exists, is healthy, is powered and the run is alive.
func can_cultivate() -> bool:
	var machine: MachineState = machine_state()
	if machine == null:
		return false
	if machine.is_broken() or not machine.powered:
		return false
	return not GameSim.state.game_over


## Sows one cell. Requires an operational machine; the state rejects occupied or
## out-of-range cells.
func plant_cell(index: int) -> bool:
	if not can_cultivate():
		return false
	if cultivation == null:
		return false
	return cultivation.plant(index)


## Pulls out a growing plant. Allowed without power or health on purpose: the
## player must be able to clear a cell of a broken machine, and it produces no
## food.
func remove_cell(index: int) -> bool:
	if cultivation == null:
		return false
	return cultivation.remove(index)


## Collects one mature cell: the food is added before reporting success, clamped
## by the economy capacity. A cell that is not mature is left untouched.
func harvest_cell(index: int) -> bool:
	if not can_cultivate():
		return false
	if cultivation == null:
		return false
	if cultivation.stage_of(index) != HydroponicsState.STAGE_COUNT:
		return false
	if not cultivation.harvest(index):
		return false
	GameSim.add_resource_clamped(SimState.FOOD, harvest_food_amount())
	return true


## Food granted by one harvest, read from the economy so balance lives in data.
func harvest_food_amount() -> float:
	return GameSim.get_economy().get_value(HARVEST_FOOD_ROW, HARVEST_FOOD_FALLBACK)


## Cultivation panel offered to the machine panel as an extra screen.
func get_extra_panel_scene() -> PackedScene:
	return extra_panel_scene
