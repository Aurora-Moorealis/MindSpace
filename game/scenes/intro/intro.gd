extends Control
## Intro: salida de la Tierra, travesía a la Luna y la historia por partes.
##
## Primero se reproduce la animación (lanzamiento y viaje), después la historia
## avanza con la acción de continuar y al final se acepta la misión. El nombre del mundo
## elegido en la pantalla anterior sustituye a {nombre} en los textos.

const WORLDS_SCENE: String = "res://scenes/worlds/worlds.tscn"

const TITLES: Array[String] = [
	"Notice",
	"A question from Earth",
	"Your mission",
	"Preparations",
	"A travel companion",
	"Arrival",
	"The first step",
]

const BODIES: Array[String] = [
	"This is an imagined future mission. We use real science and simplify some processes so you can play.",
	"For years, our probes and astronauts have explored the Moon. They have shown us craters, seas of dark rock and clues to its history. But we still have much to learn: what would it take to stay there and keep a base running?",
	"That is why we need your help, {name}. Your mission is to build a small research base, make use of some lunar resources and tell us what works, what fails and what we should improve.",
	"You will not travel unprepared. Your module carries air, water, food, tools and a workshop. It also carries parts we cannot make on the Moon yet. These supplies will give you time to start, but you will have to learn to manage them.",
	"Well, hello there, {name}! I am Aurora, your mission assistant. I keep maps, instructions and scientific data. I will help you read the base signals. You make the decisions.",
	"After a journey of a few days, you land near a crater chosen for its possible resources. The module becomes your first shelter. Outside, rocks, deposits to study and a grey landscape still full of questions are waiting for you.",
	"Start by checking your supplies and switching on the solar panel. Then you can explore, collect materials and expand the base. Every discovery will help Earth understand how to prepare future missions. All set? Your first day on the Moon starts now.",
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
	_accept_title.text = "Accept the mission, %s?" % _world_name
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
	_story_body.text = BODIES[index].replace("{name}", _world_name)
	_next.text = "Continue" if index < TITLES.size() - 1 else "Accept mission"
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
	_accept_note.text = "Mission accepted. The base arrives in the next step."


func _go_back() -> void:
	get_tree().change_scene_to_file(WORLDS_SCENE)
