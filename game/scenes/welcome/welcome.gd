extends Control
## Game's entry menu.
##
## Title screen with the main actions. It is part of item 20 of the formal
## design (`docs/designs/junior-astronauta-outpost-lunar.md`), which still plans
## to add the mission selector here: 1 playable mission and 2 grey "coming soon"
## rows (see `docs/future/selector-mision.md`).

## Scene the "Start game" button goes to once it exists.
const START_SCENE: String = "res://scenes/intro_stills/intro_stills.tscn"

## Scene the "Settings" button goes to once it exists.
const SETTINGS_SCENE: String = "res://scenes/settings/settings.tscn"

## Seconds the toast stays visible before fading out.
const TOAST_HOLD_SECONDS: float = 2.0

## Seconds the toast takes to disappear.
const TOAST_FADE_SECONDS: float = 0.4

@onready var _play_button: Button = %PlayButton
@onready var _toast: Label = %Toast

var _toast_tween: Tween = null


func _ready() -> void:
	_toast.modulate.a = 0.0
	_play_button.grab_focus()


func _on_play_pressed() -> void:
	if ResourceLoader.exists(START_SCENE):
		get_tree().change_scene_to_file(START_SCENE)
		return
	_show_toast("The intro does not exist yet. Next step: intro_stills.")


func _on_options_pressed() -> void:
	if ResourceLoader.exists(SETTINGS_SCENE):
		get_tree().change_scene_to_file(SETTINGS_SCENE)
		return
	_show_toast("Settings: coming soon.")


## Shows a temporary toast at the bottom of the menu.
func _show_toast(message: String) -> void:
	_toast.text = message
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_HOLD_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, TOAST_FADE_SECONDS)
