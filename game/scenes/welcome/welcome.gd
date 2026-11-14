extends Control
## Menú de entrada del juego.
##
## Pantalla de título con las acciones principales. Forma parte del punto 20 del
## diseño formal (`docs/designs/junior-astronauta-outpost-lunar.md`), que todavía
## prevé añadir aquí el selector de misión: 1 misión jugable y 2 filas grises
## "coming soon" (ver `docs/future/selector-mision.md`).

## Escena a la que lleva "Iniciar juego" cuando exista.
const START_SCENE: String = "res://scenes/worlds/worlds.tscn"

## Escena a la que lleva "Configuración" cuando exista.
const SETTINGS_SCENE: String = "res://scenes/settings/settings.tscn"

## Segundos que el aviso permanece visible antes de desvanecerse.
const TOAST_HOLD_SECONDS: float = 2.0

## Segundos que tarda el aviso en desaparecer.
const TOAST_FADE_SECONDS: float = 0.4

@onready var _play_button: Button = %PlayButton
@onready var _toast: Label = %Toast

var _toast_tween: Tween = null


func _ready() -> void:
	_toast.modulate.a = 0.0
	_play_button.grab_focus()


func _on_play_pressed() -> void:
	if not ResourceLoader.exists(START_SCENE):
		_show_toast("Cannot find the worlds screen (%s)." % START_SCENE)
		return
	var error: Error = get_tree().change_scene_to_file(START_SCENE)
	if error != OK:
		_show_toast("Could not open the worlds screen (error %d)." % error)


func _on_options_pressed() -> void:
	if ResourceLoader.exists(SETTINGS_SCENE):
		get_tree().change_scene_to_file(SETTINGS_SCENE)
		return
	_show_toast("Settings: coming soon.")


## Muestra un aviso temporal en la parte baja del menú.
func _show_toast(message: String) -> void:
	_toast.text = message
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_HOLD_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, TOAST_FADE_SECONDS)
