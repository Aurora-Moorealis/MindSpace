extends Node2D

const INTERFACE_SCENE: String = "res://content/machines/hydroponics/visual/growth_interface/growth_interface.tscn"
const VITRINE_RECT: Rect2 = Rect2(281, 144, 288, 192)
const TEX_STAGE_1: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_1_seed.png")
const TEX_STAGE_2: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_2_sprout.png")
const TEX_STAGE_3: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_3_young.png")
const TEX_STAGE_4: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_4_mature.png")

@onready var plants: Node2D = $Scaled/Plants

var stages: Array[Texture2D] = []
var cells: Array[Sprite2D] = []
var hovering: bool = false


func _ready() -> void:
	HydroponicsState.ensure_initialized()
	stages = [TEX_STAGE_1, TEX_STAGE_2, TEX_STAGE_3, TEX_STAGE_4]
	for child: Node in plants.get_children():
		var sprite: Sprite2D = child as Sprite2D
		if sprite != null:
			cells.append(sprite)


func _process(_delta: float) -> void:
	for i: int in range(cells.size()):
		var stage: int = HydroponicsState.stage_of(i)
		cells[i].visible = stage > 0
		if stage > 0:
			cells[i].texture = stages[stage - 1]

	var inside: bool = VITRINE_RECT.has_point(get_viewport().get_mouse_position())
	if inside != hovering:
		hovering = inside
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if inside else Input.CURSOR_ARROW)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click: InputEventMouseButton = event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT and VITRINE_RECT.has_point(click.position):
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			get_tree().change_scene_to_file(INTERFACE_SCENE)
