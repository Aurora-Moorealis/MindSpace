extends Control
## Intro: salida de la Tierra, travesía a la Luna y la historia por partes.
##
## Primero se reproduce la animación (lanzamiento y viaje), después la historia
## avanza con "Continuar" y al final se acepta la misión. El nombre del mundo
## elegido en la pantalla anterior sustituye a {nombre} en los textos.

const WORLDS_SCENE: String = "res://scenes/worlds/worlds.tscn"

const TITLES: Array[String] = [
	"Aviso",
	"Una pregunta desde la Tierra",
	"Tu misión",
	"Preparativos",
	"Una compañera de viaje",
	"Llegada",
	"El primer paso",
]

const BODIES: Array[String] = [
	"Esta es una misión futura imaginada. Usamos ciencia real y simplificamos algunos procesos para jugar.",
	"Durante años, nuestras sondas y astronautas han explorado la Luna. Nos han mostrado cráteres, mares de roca oscura y pistas de su historia. Pero todavía tenemos mucho que aprender: ¿qué necesitaríamos para quedarnos allí y mantener una base funcionando?",
	"Por eso necesitamos tu ayuda, {nombre}. Tu misión será construir una pequeña base de investigación, aprovechar algunos recursos lunares y contarnos qué funciona, qué falla y qué debemos mejorar.",
	"No viajarás sin preparación. Tu módulo lleva aire, agua, comida, herramientas y un taller. También transporta piezas que todavía no podemos fabricar en la Luna. Estas reservas te darán tiempo para empezar, pero tendrás que aprender a administrarlas.",
	"¡Muuuy buenas, {nombre}! Soy Aurora, tu asistente de misión. Tengo guardados mapas, instrucciones y datos científicos. Yo te ayudaré a entender las señales de la base. Las decisiones las tomarás tú.",
	"Después de un viaje de pocos días, aterrizas cerca de un cráter elegido por sus posibles recursos. El módulo se convierte en tu primer refugio. Afuera te esperan rocas, depósitos por investigar y un paisaje gris que todavía guarda muchas preguntas.",
	"Empieza por revisar tus reservas y activar el panel solar. Después podrás explorar, recoger materiales y ampliar la base. Cada descubrimiento ayudará a la Tierra a comprender cómo preparar futuras misiones. ¿Todo listo? Tu primera jornada en la Luna comienza ahora.",
]

@onready var _space: Control = %Space
@onready var _earth: TextureRect = %Earth
@onready var _moon: TextureRect = %Moon
@onready var _ship_big: TextureRect = %ShipBig
@onready var _ship_small: TextureRect = %ShipSmall
@onready var _fade: ColorRect = %Fade
@onready var _story: Control = %Story
@onready var _story_title: Label = %StoryTitle
@onready var _story_body: Label = %StoryBody
@onready var _next: Button = %NextButton
@onready var _skip: Button = %SkipButton
@onready var _accept: Control = %Accept
@onready var _accept_title: Label = %AcceptTitle
@onready var _accept_note: Label = %AcceptNote
@onready var _accept_button: Button = %AcceptButton
@onready var _back_button: Button = %BackButton

var _world_name: String = "astronauta"
var _index: int = 0
var _skipped: bool = false


func _ready() -> void:
	var world: World = WorldStore.selected
	if world != null and not world.name.is_empty():
		_world_name = world.name

	_story.visible = false
	_accept.visible = false
	_ship_small.visible = false
	_moon.visible = false
	_accept_title.text = "¿Aceptas la misión, %s?" % _world_name
	_next.pressed.connect(_on_next_pressed)
	_skip.pressed.connect(_on_skip_pressed)
	_accept_button.pressed.connect(_on_accept_pressed)
	_back_button.pressed.connect(_go_back)

	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- animación
func _play_intro() -> void:
	_fade.color.a = 1.0
	await _fade_to(0.0, 0.4)
	if _skipped:
		_show_story()
		return

	await _play_launch()
	if _skipped:
		_show_story()
		return

	await _fade_to(1.0, 0.35)
	if _skipped:
		_show_story()
		return

	_prepare_travel()
	await _fade_to(0.0, 0.35)
	if _skipped:
		_show_story()
		return

	await _play_travel()
	_show_story()


## Salida: la Tierra abajo y el cohete subiendo en diagonal.
func _play_launch() -> void:
	_earth.position = Vector2(-60.0, 300.0)
	_ship_big.position = Vector2(140.0, 250.0)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_ship_big, "position", Vector2(360.0, -280.0), 2.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_earth, "position", Vector2(-60.0, 420.0), 2.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished


## Viaje: el cohete se aleja hacia la Luna, que se ve pequeña al fondo.
func _prepare_travel() -> void:
	_ship_big.visible = false
	_ship_small.visible = true
	_moon.visible = true
	_ship_small.position = Vector2(90.0, 400.0)


func _play_travel() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_ship_small, "position", Vector2(520.0, 150.0), 3.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _fade_to(alpha: float, seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", alpha, seconds)
	await tween.finished


# ---------------------------------------------------------------- historia
func _show_story() -> void:
	_fade.color.a = 0.0
	_space.modulate = Color(1.0, 1.0, 1.0, 0.45)
	_skip.visible = false
	_story.visible = true
	_story.modulate.a = 0.0
	create_tween().tween_property(_story, "modulate:a", 1.0, 0.3)
	_show_part(0)


func _show_part(index: int) -> void:
	_index = index
	_story_title.text = TITLES[index]
	_story_body.text = BODIES[index].replace("{nombre}", _world_name)
	_next.text = "Continuar" if index < TITLES.size() - 1 else "Aceptar la misión"
	_next.grab_focus()


func _on_next_pressed() -> void:
	if _index < TITLES.size() - 1:
		_show_part(_index + 1)
		return
	_show_accept()


func _on_skip_pressed() -> void:
	_skipped = true
	_show_story()


func _show_accept() -> void:
	_story.visible = false
	_accept.visible = true
	_accept.modulate.a = 0.0
	create_tween().tween_property(_accept, "modulate:a", 1.0, 0.25)
	_accept_button.grab_focus()


func _on_accept_pressed() -> void:
	_accept_button.disabled = true
	_accept_note.text = "Misión aceptada. La base llega en el siguiente paso."


func _go_back() -> void:
	get_tree().change_scene_to_file(WORLDS_SCENE)
