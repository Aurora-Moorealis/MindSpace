class_name World
extends Resource
## Saved world.
##
## Stored as three strings; `WorldStore` handles persistence.

@export var id: String = ""
@export var name: String = ""
@export var created_at: String = ""


## Builds a world from the Variant returned by `JSON.parse_string`.
static func from_variant(data: Variant) -> World:
	var world: World = World.new()
	if typeof(data) != TYPE_DICTIONARY:
		return world
	world.id = str((data as Dictionary).get("id", ""))
	world.name = str((data as Dictionary).get("name", ""))
	world.created_at = str((data as Dictionary).get("created_at", ""))
	return world


func to_dictionary() -> Dictionary[String, String]:
	return {"id": id, "name": name, "created_at": created_at}
