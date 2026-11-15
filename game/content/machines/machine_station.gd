class_name MachineStation
extends MachineBase

## Generic station for the machines that have no scene of their own: a flat
## silhouette drawn in code plus the humanized machine name underneath it.
## Interaction, power identity and the cable port all come from MachineBase.

const BODY_SIZE: Vector2 = Vector2(112, 72)
const BODY_COLOR: Color = Color("#1F3152")
const BORDER_COLOR: Color = Color("#14192B")
const PORT_COLOR: Color = Color("#6A7684")
const TEXT_COLOR: Color = Color("#D8E2F0")
const TEXT_BROKEN_COLOR: Color = Color("#F08A8A")
const TEXT_UNPOWERED_COLOR: Color = Color("#93A0B4")

const BORDER_WIDTH: float = 2.0
const TOP_STRIPE_HEIGHT: float = 8.0
const TOP_STRIPE_MARGIN: float = 4.0
const PORT_RADIUS: float = 4.0
const LABEL_GAP: float = 6.0
const LABEL_HEIGHT: float = 20.0
const LABEL_FONT_SIZE: int = 10

@export var accent_color: Color = Color("#57C8CC")

var _name_label: Label = null


func _ready() -> void:
	# The base calls refresh_from_state() from _ready(), so the label has to
	# exist before that call or the first refresh would find it missing.
	_build_name_label()
	super._ready()


## Colors the name label like the sprite: red when broken, grey when unpowered
## and neutral otherwise. The silhouette itself is painted by _draw().
func refresh_from_state() -> void:
	super.refresh_from_state()
	if _name_label == null:
		return
	var machine: MachineState = machine_state()
	if machine == null:
		_name_label.text = UiText.UNKNOWN_MACHINE
		_set_label_color(TEXT_COLOR)
		return
	if machine.is_broken():
		_set_label_color(TEXT_BROKEN_COLOR)
	elif not machine.powered:
		_set_label_color(TEXT_UNPOWERED_COLOR)
	else:
		_set_label_color(TEXT_COLOR)
	# Keeps the text in sync when an instance assigns machine_id after the node
	# is already in the tree.
	_name_label.text = UiText.display_name(GameSim.get_machine_data(machine_id))


## Draws the code-made silhouette of the scene: body, border, top stripe in the
## accent color and the cable port plug.
func _draw() -> void:
	var body: Rect2 = Rect2(-BODY_SIZE * 0.5, BODY_SIZE)
	draw_rect(body, BODY_COLOR)
	draw_rect(body, BORDER_COLOR, false, BORDER_WIDTH)
	var stripe: Rect2 = Rect2(
		body.position + Vector2(TOP_STRIPE_MARGIN, TOP_STRIPE_MARGIN),
		Vector2(BODY_SIZE.x - TOP_STRIPE_MARGIN * 2.0, TOP_STRIPE_HEIGHT)
	)
	draw_rect(stripe, accent_color)
	draw_circle(port_offset, PORT_RADIUS, PORT_COLOR)


func _build_name_label() -> void:
	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	_set_label_color(TEXT_COLOR)
	add_child(_name_label)
	# Text and size are set after the label enters the tree: the theme lookup
	# resolves to the project default font size before that, and its taller
	# minimum size would clamp the 112x20 box.
	_name_label.text = UiText.display_name(GameSim.get_machine_data(machine_id))
	_name_label.position = Vector2(-BODY_SIZE.x * 0.5, BODY_SIZE.y * 0.5 + LABEL_GAP)
	_name_label.size = Vector2(BODY_SIZE.x, LABEL_HEIGHT)


func _set_label_color(color: Color) -> void:
	_name_label.add_theme_color_override("font_color", color)
