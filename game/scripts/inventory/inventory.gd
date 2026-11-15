class_name Inventory
extends RefCounted

## Fixed-size, slot-by-slot inventory. It knows nothing about nodes or input: the
## HUD renders it and decides what a click means. Every mutation notifies the
## view with the affected index.

signal slot_changed(index: int, item: ItemData)
signal selection_changed(index: int)

const DEFAULT_SLOT_COUNT: int = 5

var _items: Array[ItemData] = []
var _selected_index: int = 0


func _init(slot_count: int = DEFAULT_SLOT_COUNT) -> void:
	_items.resize(maxi(slot_count, 1))


func get_slot_count() -> int:
	return _items.size()


func get_selected_index() -> int:
	return _selected_index


func get_selected_item() -> ItemData:
	return get_item(_selected_index)


func is_valid_index(index: int) -> bool:
	return index >= 0 and index < _items.size()


func get_item(index: int) -> ItemData:
	if not is_valid_index(index):
		return null
	return _items[index]


func is_empty(index: int) -> bool:
	return get_item(index) == null


## Puts an item in a slot. A null item clears it; an item without id is rejected.
## Returns true when the slot changed.
func set_item(index: int, item: ItemData) -> bool:
	if not is_valid_index(index):
		return false
	if item != null and not item.is_valid():
		return false
	if _items[index] == item:
		return false
	_items[index] = item
	slot_changed.emit(index, item)
	return true


## Removes and returns the item of a slot. Returns null when the slot is empty.
func take_item(index: int) -> ItemData:
	var item: ItemData = get_item(index)
	if item == null:
		return null
	_items[index] = null
	slot_changed.emit(index, null)
	return item


## Swaps two slots. Moving an empty slot is a no-op.
func move_item(from_index: int, to_index: int) -> bool:
	if not is_valid_index(from_index) or not is_valid_index(to_index):
		return false
	if from_index == to_index:
		return false
	var from_item: ItemData = _items[from_index]
	if from_item == null:
		return false
	var to_item: ItemData = _items[to_index]
	_items[from_index] = to_item
	_items[to_index] = from_item
	slot_changed.emit(from_index, _items[from_index])
	slot_changed.emit(to_index, _items[to_index])
	return true


## First free slot, or -1 when the inventory is full.
func find_first_empty() -> int:
	for index: int in range(_items.size()):
		if _items[index] == null:
			return index
	return -1


## Stores an item in the first free slot. Returns that index or -1.
func add_item(item: ItemData) -> int:
	if item == null or not item.is_valid():
		return -1
	var index: int = find_first_empty()
	if index < 0:
		return -1
	_items[index] = item
	slot_changed.emit(index, item)
	return index


## Empties every slot and selects the first one. Used when a run starts over.
func reset() -> void:
	for index: int in range(_items.size()):
		if _items[index] != null:
			_items[index] = null
			slot_changed.emit(index, null)
	select(0)


## Selects an active slot. Returns true only when the selection changed.
func select(index: int) -> bool:
	if not is_valid_index(index) or index == _selected_index:
		return false
	_selected_index = index
	selection_changed.emit(index)
	return true


## Moves the selection by `step`, wrapping around the ends.
func cycle_selection(step: int) -> void:
	select(posmod(_selected_index + step, _items.size()))
