class_name World
extends Resource
## Mundo guardado.
##
## Se guarda como tres cadenas; la persistencia la hace `WorldStore`.

@export var id: String = ""
@export var name: String = ""
@export var created_at: String = ""


## Construye un mundo desde el Variant que devuelve `JSON.parse_string`.
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
