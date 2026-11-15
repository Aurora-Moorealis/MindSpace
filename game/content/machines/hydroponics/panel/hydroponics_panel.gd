class_name HydroponicsPanel
extends Control

## Cultivation screen of the hydroponics machine. It shows the twelve cells in a
## 3x4 grid with the growth stage of each one and performs the single action the
## cell admits: sow an empty cell, harvest a mature plant or pull out a growing
## one.
##
## The panel never owns the state: the station does. Every action asks the
## station again, so a machine that broke while the panel was open cannot be
## planted or harvested by a stale button.

signal closed()

const STAGES: Array[Texture2D] = [
	preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_1_seed.png"),
	preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_2_sprout.png"),
	preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_3_young.png"),
	preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_4_mature.png"),
]
const STAGE_NAMES: Array[String] = ["Empty", "Seed", "Sprout", "Young", "Mature"]

const CELL_SIZE: Vector2 = Vector2(72.0, 64.0)
const CELL_TEXTURE_MARGIN: int = 6
const ROW_LETTERS: Array[String] = ["A", "B", "C"]

const COLOR_CELL: Color = Color("#182338")
const COLOR_CELL_HOVER: Color = Color("#2A3A55")
const COLOR_CELL_BORDER: Color = Color("#3D495E")
const COLOR_ACCENT: Color = Color("#57C8CC")
const COLOR_MUTED: Color = Color("#93A0B4")
const COLOR_DIM: Color = Color(0.62, 0.68, 0.76, 1.0)

@onready var _grid: GridContainer = $Grid
@onready var _status_label: Label = $Status
@onready var _harvested_label: Label = $Harvested
@onready var _back_button: Button = $BackButton

var _station: HydroponicsStation = null
var _cells: Array[Button] = []
var _plants: Array[TextureRect] = []
var _normal_style: StyleBoxFlat = null
var _hover_style: StyleBoxFlat = null


func _ready() -> void:
	_build_styles()
	_build_cells()
	_back_button.pressed.connect(_on_back_pressed)
	if not GameSim.tick_advanced.is_connected(_on_tick_advanced):
		GameSim.tick_advanced.connect(_on_tick_advanced)
	if not GameSim.game_reset.is_connected(_on_game_reset):
		GameSim.game_reset.connect(_on_game_reset)
	_refresh()


## Binds the station that owns the cultivation state. The machine panel calls it
## right after instantiating the scene.
func setup(station: HydroponicsStation) -> void:
	_station = station
	if is_node_ready():
		_refresh()


## Station this panel is showing, or null before setup.
func get_station() -> HydroponicsStation:
	return _station


func _build_styles() -> void:
	_normal_style = _make_cell_style(COLOR_CELL, COLOR_CELL_BORDER)
	_hover_style = _make_cell_style(COLOR_CELL_HOVER, COLOR_ACCENT)


func _make_cell_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style


func _build_cells() -> void:
	for index: int in range(HydroponicsState.CELL_COUNT):
		var button: Button = Button.new()
		button.name = "Cell%s" % _cell_id(index)
		button.custom_minimum_size = CELL_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override(&"normal", _normal_style)
		button.add_theme_stylebox_override(&"hover", _hover_style)
		button.add_theme_stylebox_override(&"pressed", _hover_style)
		button.add_theme_stylebox_override(&"disabled", _normal_style)
		button.pressed.connect(_on_cell_pressed.bind(index))
		var plant: TextureRect = TextureRect.new()
		plant.name = "Plant"
		plant.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, CELL_TEXTURE_MARGIN
		)
		plant.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plant.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plant.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(plant)
		_grid.add_child(button)
		_cells.append(button)
		_plants.append(plant)


## One click does whatever the cell admits right now. The station validates the
## action again, so a disabled machine rejects planting and harvesting.
func _on_cell_pressed(index: int) -> void:
	if _station == null or _station.cultivation == null:
		return
	var stage: int = _station.cultivation.stage_of(index)
	if stage == 0:
		_station.plant_cell(index)
	elif stage >= HydroponicsState.STAGE_COUNT:
		_station.harvest_cell(index)
	else:
		_station.remove_cell(index)
	_refresh()


func _on_tick_advanced(_tick: int) -> void:
	_refresh()


func _on_game_reset() -> void:
	_refresh()


func _on_back_pressed() -> void:
	closed.emit()


func _refresh() -> void:
	if _grid == null:
		return
	var running: bool = _station != null and _station.can_cultivate()
	_status_label.text = "Growth running" if running else "Growth paused"
	_status_label.add_theme_color_override(&"font_color", COLOR_ACCENT if running else COLOR_MUTED)
	_harvested_label.text = "Harvested: %d" % _harvested_count()
	for index: int in range(_cells.size()):
		var stage: int = _stage_of(index)
		_plants[index].texture = STAGES[stage - 1] if stage > 0 else null
		_cells[index].tooltip_text = "%s: %s" % [_cell_id(index), STAGE_NAMES[stage]]
		var actionable: bool = running or (stage > 0 and stage < HydroponicsState.STAGE_COUNT)
		_cells[index].modulate = Color.WHITE if actionable else COLOR_DIM


func _stage_of(index: int) -> int:
	if _station == null or _station.cultivation == null:
		return 0
	return _station.cultivation.stage_of(index)


func _harvested_count() -> int:
	if _station == null or _station.cultivation == null:
		return 0
	return _station.cultivation.harvested


func _cell_id(index: int) -> String:
	var row: int = int(index / HydroponicsState.COLUMNS)
	var column: int = index % HydroponicsState.COLUMNS
	return "%s%d" % [ROW_LETTERS[row], column + 1]
