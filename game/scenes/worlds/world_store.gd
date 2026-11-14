class_name WorldStore
extends RefCounted
## Saved world persistence.
##
## Worlds live in `user://worlds.json` as a list with `id`, `name` and
## `created_at`. No autoload: a static class any scene can call.

const SAVE_PATH: String = "user://worlds.json"

## Maximum length of the visible name.
const MAX_NAME_LENGTH: int = 24

## World chosen in the last selection. The next scene reads it.
static var selected: World = null


## Reads the saved worlds. Returns an empty list when there is no file.
static func list_worlds() -> Array[World]:
	var result: Array[World] = []
	if not FileAccess.file_exists(SAVE_PATH):
		return result

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("WorldStore: could not open %s" % SAVE_PATH)
		return result
	var raw: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("WorldStore: %s is not a valid JSON object" % SAVE_PATH)
		return result

	var entries: Variant = (parsed as Dictionary).get("worlds", [])
	if typeof(entries) != TYPE_ARRAY:
		return result

	for entry: Variant in (entries as Array):
		var world: World = World.from_variant(entry)
		if not world.name.is_empty():
			result.append(world)
	return result


## Checks the name and returns an error message, or "" when it is valid.
static func validate_name(display_name: String, existing: Array[World]) -> String:
	var clean: String = display_name.strip_edges()
	if clean.is_empty():
		return "Write a name."
	if clean.length() > MAX_NAME_LENGTH:
		return "Max %d characters." % MAX_NAME_LENGTH
	for world: World in existing:
		if world.name.to_lower() == clean.to_lower():
			return "A world with that name already exists."
	return ""


## Creates the world, saves it and leaves it selected.
## Returns the created world, or `null` when it could not be saved.
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


## Deletes the world with that id. Returns true when the change was saved.
static func delete_world(world_id: String) -> bool:
	var remaining: Array[World] = []
	for world: World in list_worlds():
		if world.id != world_id:
			remaining.append(world)
	if selected != null and selected.id == world_id:
		selected = null
	return _write(remaining)


## Marks a world as chosen without creating anything.
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
		push_warning("WorldStore: could not write %s" % SAVE_PATH)
		return false
	var serialized: Array[Variant] = []
	for world: World in worlds:
		serialized.append(world.to_dictionary())
	file.store_string(JSON.stringify({"worlds": serialized}, "\t"))
	file.close()
	return true
