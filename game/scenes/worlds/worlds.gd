extends Control
## World selection: lists the saved ones or asks for a name when there are none.
##
## With no worlds the screen goes straight to the form. With worlds, each row
## can enter or delete; deleting asks for confirmation in the button itself.
## The chosen world stays in `WorldStore.selected` for the next scene.

const WELCOME_SCENE: String = "res://scenes/welcome/welcome.tscn"
const INTRO_SCENE: String = "res://scenes/intro/intro.tscn"

const TOAST_HOLD_SECONDS: float = 2.0
const TOAST_FADE_SECONDS: float = 0.4

## Seconds the delete button waits for the second press.
const DELETE_CONFIRM_SECONDS: float = 3.0

@onready var _subtitle: Label = %Subtitle
@onready var _list_scroll: ScrollContainer = %ListScroll
@onready var _list: VBoxContainer = %List
@onready var _create_button: Button = %CreateButton
@onready var _form: VBoxContainer = %Form
@onready var _name_edit: LineEdit = %NameEdit
@onready var _confirm_button: Button = %ConfirmButton
@onready var _error: Label = %Error
@onready var _back_button: Button = %BackButton
@onready var _toast: Label = %Toast

var _worlds: Array[World] = []
var _toast_tween: Tween = null


func _ready() -> void:
	_worlds = WorldStore.list_worlds()
	_toast.modulate.a = 0.0
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	var has_worlds: bool = not _worlds.is_empty()
	_list_scroll.visible = has_worlds
	_create_button.visible = has_worlds
	_form.visible = not has_worlds
	_subtitle.text = "Choose a world" if has_worlds else "Name your world"
	_error.text = ""

	if has_worlds:
		for world: World in _worlds:
			_list.add_child(_make_row(world))
		_create_button.grab_focus()
	else:
		_name_edit.text = ""
		_name_edit.grab_focus()


## Row: the name enters the world, the button on the right deletes.
func _make_row(world: World) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var play: Button = Button.new()
	play.text = world.name
	play.custom_minimum_size = Vector2(0, 44)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.pressed.connect(_on_world_pressed.bind(world))
	row.add_child(play)

	var remove: Button = Button.new()
	remove.text = "Delete"
	remove.custom_minimum_size = Vector2(96, 44)
	remove.set_meta("confirming", false)
	remove.pressed.connect(_on_delete_pressed.bind(world, remove))
	row.add_child(remove)

	return row


func _on_world_pressed(world: World) -> void:
	WorldStore.select(world)
	_world_ready(world)


func _on_delete_pressed(world: World, button: Button) -> void:
	if not is_instance_valid(button):
		return
	if not bool(button.get_meta("confirming", false)):
		button.set_meta("confirming", true)
		button.text = "Sure?"
		get_tree().create_timer(DELETE_CONFIRM_SECONDS).timeout.connect(
			_reset_delete_button.bind(button)
		)
		return

	if not WorldStore.delete_world(world.id):
		_show_toast("Could not delete the world.")
		return

	_worlds = WorldStore.list_worlds()
	_show_toast("World deleted: %s" % world.name)
	_refresh()


func _reset_delete_button(button: Button) -> void:
	if not is_instance_valid(button):
		return
	button.set_meta("confirming", false)
	button.text = "Delete"


func _on_create_button_pressed() -> void:
	_list_scroll.visible = false
	_create_button.visible = false
	_form.visible = true
	_error.text = ""
	_name_edit.text = ""
	_name_edit.grab_focus()


func _on_confirm_button_pressed() -> void:
	var message: String = WorldStore.validate_name(_name_edit.text, _worlds)
	if not message.is_empty():
		_error.text = message
		_name_edit.grab_focus()
		return

	var world: World = WorldStore.create_world(_name_edit.text)
	if world == null:
		_error.text = "Could not save the world."
		return

	_world_ready(world)


func _on_name_submitted(_text: String) -> void:
	_on_confirm_button_pressed()


func _on_name_changed(_text: String) -> void:
	if not _error.text.is_empty():
		_error.text = ""


func _on_back_pressed() -> void:
	_go_back()


## Enters the chosen world: the intro first.
func _world_ready(world: World) -> void:
	get_tree().change_scene_to_file(INTRO_SCENE)


func _go_back() -> void:
	get_tree().change_scene_to_file(WELCOME_SCENE)


func _show_toast(message: String) -> void:
	_toast.text = message
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_HOLD_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, TOAST_FADE_SECONDS)
