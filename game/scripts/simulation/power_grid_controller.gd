class_name PowerGridController
extends Node

## Collects every PowerCable in the scene and publishes their links to GameSim.
## Runs one frame after the scene is ready so all endpoints exist, and again on
## every new game (which clears the cable layout).


func _ready() -> void:
	add_to_group(&"power_controllers")
	await get_tree().process_frame
	rebuild()
	GameSim.game_reset.connect(rebuild)


## Rebuilds the whole cable layout from the cables in the scene tree.
func rebuild() -> void:
	var links: Array[PowerLink] = []
	for node: Node in get_tree().get_nodes_in_group(PowerCable.GROUP):
		var cable: PowerCable = node as PowerCable
		if cable == null:
			continue
		var link: PowerLink = cable.make_link()
		if link != null:
			links.append(link)
	GameSim.set_power_links(links)
