class_name PowerGrid
extends RefCounted

## Builds the power networks of a run from the cable links stored in SimState.
##
## An empty link list means the base is pre-wired: a single network with every
## machine and every battery. Once the player places a cable, the links decide
## the topology and isolated nodes become their own network.


## Networks of the given state, in deterministic id order.
static func build(state: SimState) -> Array[PowerNetwork]:
	var nodes: Array[StringName] = _all_nodes(state)
	if nodes.is_empty():
		return []
	if state.power_links.is_empty():
		return [_single_network(state, nodes)]
	return _components(state, nodes)


## One network containing the whole base (the default pre-wired layout).
static func _single_network(state: SimState, nodes: Array[StringName]) -> PowerNetwork:
	var network: PowerNetwork = PowerNetwork.new()
	network.id = nodes[0]
	for node_id: StringName in nodes:
		network.nodes.append(node_id)
	for battery_id: StringName in state.get_battery_ids():
		if not network.batteries.has(battery_id):
			network.batteries.append(battery_id)
	return network


## Connected components of the link graph; unlinked nodes stand alone.
static func _components(state: SimState, nodes: Array[StringName]) -> Array[PowerNetwork]:
	var adjacency: Dictionary[StringName, PackedStringArray] = {}
	for node_id: StringName in nodes:
		adjacency[node_id] = PackedStringArray()
	for link: PowerLink in state.power_links:
		if link == null or not link.is_valid():
			continue
		if not adjacency.has(link.a) or not adjacency.has(link.b):
			continue
		var from_neighbours: PackedStringArray = adjacency[link.a]
		if not from_neighbours.has(String(link.b)):
			from_neighbours.append(String(link.b))
		adjacency[link.a] = from_neighbours
		var to_neighbours: PackedStringArray = adjacency[link.b]
		if not to_neighbours.has(String(link.a)):
			to_neighbours.append(String(link.a))
		adjacency[link.b] = to_neighbours

	var networks: Array[PowerNetwork] = []
	var visited: Dictionary[StringName, bool] = {}
	for start: StringName in nodes:
		if visited.has(start):
			continue
		var network: PowerNetwork = PowerNetwork.new()
		network.id = start
		var pending: Array[StringName] = [start]
		visited[start] = true
		while not pending.is_empty():
			var current: StringName = pending.pop_front()
			network.nodes.append(current)
			if state.batteries.has(current):
				network.batteries.append(current)
			var neighbours: PackedStringArray = adjacency[current]
			var sorted_neighbours: Array[StringName] = []
			for neighbour: String in neighbours:
				var neighbour_id: StringName = StringName(neighbour)
				if not visited.has(neighbour_id):
					sorted_neighbours.append(neighbour_id)
			sorted_neighbours.sort_custom(_id_before)
			for neighbour_id: StringName in sorted_neighbours:
				visited[neighbour_id] = true
				pending.append(neighbour_id)
		networks.append(network)
	return networks


## Every machine present in the run plus every known battery, sorted by id.
static func _all_nodes(state: SimState) -> Array[StringName]:
	var nodes: Array[StringName] = []
	for node_id: StringName in state.machines.keys():
		nodes.append(node_id)
	for battery_id: StringName in state.get_battery_ids():
		if not nodes.has(battery_id):
			nodes.append(battery_id)
	nodes.sort_custom(_id_before)
	return nodes


## Deterministic ordering used by sort_custom.
static func _id_before(first: StringName, second: StringName) -> bool:
	return String(first) < String(second)
