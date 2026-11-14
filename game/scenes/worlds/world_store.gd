class_name WorldStore
extends RefCounted
## Persistencia de mundos guardados.
##
## Los mundos viven en `user://worlds.json` como una lista con `id`, `name` y
## `created_at`. Sin autoload: es una clase estática que cualquier escena llama.

const SAVE_PATH: String = "user://worlds.json"

## Longitud máxima del nombre visible.
const MAX_NAME_LENGTH: int = 24

## Mundo elegido en la última selección. La lee la escena siguiente.
static var selected: World = null


## Lee la lista de mundos guardados. Devuelve una lista vacía si no hay archivo.
static func list_worlds() -> Array[World]:
	var result: Array[World] = []
	if not FileAccess.file_exists(SAVE_PATH):
		return result

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("WorldStore: no se pudo abrir %s" % SAVE_PATH)
		return result
	var raw: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("WorldStore: %s no es un objeto JSON válido" % SAVE_PATH)
		return result

	var entries: Variant = (parsed as Dictionary).get("worlds", [])
	if typeof(entries) != TYPE_ARRAY:
		return result

	for entry: Variant in (entries as Array):
		var world: World = World.from_variant(entry)
		if not world.name.is_empty():
			result.append(world)
	return result


## Comprueba el nombre y devuelve un mensaje de error, o "" si es válido.
static func validate_name(display_name: String, existing: Array[World]) -> String:
	var clean: String = display_name.strip_edges()
	if clean.is_empty():
		return "Escribe un nombre."
	if clean.length() > MAX_NAME_LENGTH:
		return "Máximo %d caracteres." % MAX_NAME_LENGTH
	for world: World in existing:
		if world.name.to_lower() == clean.to_lower():
			return "Ya existe un mundo con ese nombre."
	return ""


## Crea el mundo, lo guarda y lo deja como seleccionado.
## Devuelve el mundo creado, o `null` si no se pudo guardar.
static func create_world(display_name: String) -> World:
	var clean: String = display_name.strip_edges()
	var worlds: Array[World] = list_worlds()

	var world: World = World.new()
	world.id = "%s-%d" % [_slug(clean), int(Time.get_unix_time_from_system())]
	world.name = clean
	world.created_at = Time.get_datetime_string_from_system(true)

	worlds.append(world)
	if not _write(worlds):
		return null
	selected = world
	return world


## Borra el mundo con ese id. Devuelve true si se guardó el cambio.
static func delete_world(world_id: String) -> bool:
	var remaining: Array[World] = []
	for world: World in list_worlds():
		if world.id != world_id:
			remaining.append(world)
	if selected != null and selected.id == world_id:
		selected = null
	return _write(remaining)


## Marca un mundo como elegido sin crear nada.
static func select(world: World) -> void:
	selected = world


static func _slug(text: String) -> String:
	var out: String = ""
	for i: int in text.length():
		var c: String = text[i].to_lower()
		if c == " ":
			out += "-"
		elif c.is_valid_identifier() or c.is_valid_int() or c == "-" or c == "_":
			out += c
	if out.is_empty():
		out = "mundo"
	return out


static func _write(worlds: Array[World]) -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("WorldStore: no se pudo escribir %s" % SAVE_PATH)
		return false
	var serialized: Array[Variant] = []
	for world: World in worlds:
		serialized.append(world.to_dictionary())
	file.store_string(JSON.stringify({"worlds": serialized}, "\t"))
	file.close()
	return true
