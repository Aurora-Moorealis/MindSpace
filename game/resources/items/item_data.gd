class_name ItemData
extends Resource

## One inventory item. The icon is optional so a test or a prototype can create
## items before their art exists.

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D = null
@export_multiline var description: String = ""


## An item is usable only when it can be identified. Display name and icon are
## presentation, not identity.
func is_valid() -> bool:
	return not id.is_empty()
