class_name InventorySlot
extends Control

## One hotbar slot. It only draws an item and reports input; the HUD owns the
## inventory and decides what a click or a drop means.

signal slot_clicked(index: int)
signal slot_right_clicked(index: int)
signal slot_dropped(from_index: int, to_index: int)

const DRAG_PREVIEW_SIZE: float = 16.0
## A release farther than this from the press is a drag, not a click.
const CLICK_MAX_DISTANCE: float = 8.0


## Typed payload for Godot's drag and drop. Using a small object instead of an
## untyped Dictionary keeps the drop side explicit.
class DragPayload:
	extends RefCounted

	var index: int = -1
	var item: ItemData = null


@onready var _selected: TextureRect = $Selected
@onready var _icon: TextureRect = $Icon

var slot_index: int = -1
var item: ItemData = null
var _pressed: bool = false
var _press_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_selected.visible = false
	_icon.visible = false


func configure(index: int) -> void:
	slot_index = index


func get_slot_index() -> int:
	return slot_index


func set_item(new_item: ItemData) -> void:
	item = new_item
	var has_icon: bool = item != null and item.icon != null
	_icon.texture = item.icon if item != null else null
	_icon.visible = has_icon
	tooltip_text = item.display_name if item != null else ""


func set_selected(selected: bool) -> void:
	_selected.visible = selected


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	# Act on release, not press: pressing and moving starts a drag, and the item
	# must still be in the slot when Godot asks for the drag data.
	# Act on release, not press: pressing and moving starts a drag, and the item
	# must still be in the slot when Godot asks for the drag data.
	if mouse_event.pressed:
		_pressed = true
		_press_position = mouse_event.position
		return
	if not _pressed:
		return
	_pressed = false
	# The release that ends a drag lands far from the press: not a click.
	if mouse_event.position.distance_to(_press_position) > CLICK_MAX_DISTANCE:
		accept_event()
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(slot_index)
		accept_event()
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		slot_right_clicked.emit(slot_index)
		accept_event()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null or item.icon == null:
		return null
	var preview: TextureRect = TextureRect.new()
	preview.texture = item.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(DRAG_PREVIEW_SIZE, DRAG_PREVIEW_SIZE)
	preview.size = Vector2(DRAG_PREVIEW_SIZE, DRAG_PREVIEW_SIZE)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)
	var payload: DragPayload = DragPayload.new()
	payload.index = slot_index
	payload.item = item
	return payload


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is DragPayload:
		return false
	var payload: DragPayload = data as DragPayload
	return payload.item != null


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is DragPayload:
		return
	var payload: DragPayload = data as DragPayload
	if payload.index < 0 or payload.index == slot_index:
		return
	slot_dropped.emit(payload.index, slot_index)
