extends Node2D

## Playable outpost: places the shelter ring, the eight machine stations and the
## power network on the generated lunar map.
##
## The scene is authored around its own origin and moved onto the map spawn tile
## during _ready(), once the sibling LunarMapWorld has generated its map. Cables
## are painted after that move because their endpoints entered the tree earlier.
## Station validation never aborts the boot: a duplicated or unknown id only
## leaves a development warning.

const STATIONS_PATH: NodePath = ^"Stations"
const MAP_WORLD_PATH: NodePath = ^"LunarMapWorld"

## Ratio of a tile added to its top-left corner to reach its centre.
const TILE_CENTER_RATIO: float = 0.5


func _ready() -> void:
	_place_on_spawn_tile()
	_repaint_cables()
	_validate_stations()
	GameSim.game_reset.connect(_on_game_reset)


## Moves the whole outpost to the centre of the spawn tile of the sibling lunar
## world. Without a map the outpost keeps its authored origin so the scene still
## opens for inspection.
func _place_on_spawn_tile() -> void:
	var world: LunarMapWorld = (
		get_parent().get_node_or_null(MAP_WORLD_PATH) as LunarMapWorld
	)
	if world == null:
		push_warning("Outpost: no LunarMapWorld sibling; keeping the scene origin.")
		return
	var map: LunarMap = world.get_map()
	if map == null:
		push_warning("Outpost: LunarMapWorld has no map; keeping the scene origin.")
		return
	var tile_extent: Vector2 = Vector2(float(map.tile_size), float(map.tile_size))
	global_position = map.tile_to_world(map.spawn_tile) + tile_extent * TILE_CENTER_RATIO


## Repaints every cable after the outpost moved. Cables are painted on _ready(),
## which happens before this node resolves its final position.
func _repaint_cables() -> void:
	for node: Node in get_tree().get_nodes_in_group(PowerCable.GROUP):
		var cable: PowerCable = node as PowerCable
		if cable != null:
			cable.repaint()


## Warns about duplicated or unknown station ids without stopping the boot. A
## broken id only means that station will not find its simulation state. The
## battery is skipped on purpose: its id names a storage unit, not a core
## machine, so it is not part of SimState.MACHINE_IDS.
func _validate_stations() -> void:
	var stations: Node = get_node_or_null(STATIONS_PATH)
	if stations == null:
		push_warning("Outpost: the scene has no Stations node.")
		return
	var seen: Dictionary[StringName, bool] = {}
	for child: Node in stations.get_children():
		var station: MachineBase = child as MachineBase
		if station == null or station is Battery:
			continue
		var machine_id: StringName = station.machine_id
		if seen.has(machine_id):
			push_warning(
				"Outpost: duplicated station id '%s'." % String(machine_id)
			)
		seen[machine_id] = true
		if not SimState.MACHINE_IDS.has(machine_id):
			push_warning(
				"Outpost: station id '%s' is not a core machine id."
				% String(machine_id)
			)


## A new run brings a fresh simulation state: validate the stations again and
## refresh each one. Positions are left untouched; the outpost never moves on a
## reset.
func _on_game_reset() -> void:
	_validate_stations()
	var stations: Node = get_node_or_null(STATIONS_PATH)
	if stations == null:
		return
	for child: Node in stations.get_children():
		var station: MachineBase = child as MachineBase
		if station != null:
			station.refresh_from_state()
