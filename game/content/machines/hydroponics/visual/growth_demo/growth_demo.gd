extends Node2D

## Small rack preview of the hydroponics machine. It sows all twelve cells as
## soon as the demo loads and keeps growing them with its own cultivation state,
## fed by a local tick accumulator: no wall clock and no global RNG here.

const INTERFACE_SCENE: String = "res://content/machines/hydroponics/visual/growth_interface/growth_interface.tscn"
const VITRINE_RECT: Rect2 = Rect2(281, 144, 288, 192)
const TEX_STAGE_1: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_1_seed.png")
const TEX_STAGE_2: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_2_sprout.png")
const TEX_STAGE_3: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_3_young.png")
const TEX_STAGE_4: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_4_mature.png")

## Real seconds per simulation tick of the demo.
const TICK_SECONDS: float = 0.5
const DEMO_RUN_SEED: int = 1
## Ticks advanced before the first frame, so the rack never shows up empty.
const WARMUP_TICKS: int = 9

@onready var plants: Node2D = $Scaled/Plants

var stages: Array[Texture2D] = []
var cells: Array[Sprite2D] = []
var hovering: bool = false

## Own cultivation state of the demo: it advances on its own timer and never
## shares cells with a running game.
var _state: HydroponicsState = HydroponicsState.new(DEMO_RUN_SEED)
var _tick_accumulator: float = 0.0


func _ready() -> void:
	_state.reset()
	stages = [TEX_STAGE_1, TEX_STAGE_2, TEX_STAGE_3, TEX_STAGE_4]
	for child: Node in plants.get_children():
		var sprite: Sprite2D = child as Sprite2D
		if sprite != null:
			cells.append(sprite)
	for index: int in range(mini(cells.size(), HydroponicsState.CELL_COUNT)):
		_state.plant(index)
	for _step: int in range(WARMUP_TICKS):
		_advance_one_tick()
	_apply_cells()


func _process(delta: float) -> void:
	_tick_accumulator += delta
	while _tick_accumulator >= TICK_SECONDS:
		_tick_accumulator -= TICK_SECONDS
		_advance_one_tick()
	_apply_cells()

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


## Draws the current stage of every cell on the rack sprites.
func _apply_cells() -> void:
	for index: int in range(cells.size()):
		var stage: int = _state.stage_of(index)
		cells[index].visible = stage > 0
		if stage > 0:
			cells[index].texture = stages[stage - 1]


func _advance_one_tick() -> void:
	var _changed: bool = _state.advance_tick()
