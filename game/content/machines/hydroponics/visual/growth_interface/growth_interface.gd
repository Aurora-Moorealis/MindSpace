extends Node2D

## Full-screen cultivation interface of the greenhouse. It can run in two modes:
##
## - Standalone demo: it owns a [HydroponicsState] and feeds it ticks from its own
##   accumulator, so the visual demo grows on its own.
## - Bound to a station: [method bind_station] swaps the own state for the
##   station one, the simulation tick grows the cells through the station and
##   every action goes through it, so power and health rules still apply.
##
## Closing the interface while it is bound emits [signal closed]; the demo keeps
## its old jump to the demo scene.

## Emitted when the player closes the interface while it is bound to a station.
signal closed()

const TEX_REAR_CAP: Texture2D = preload("res://content/machines/hydroponics/art/interaction/hydroponics_zoom_rear_cap.png")
const TEX_BACK: Texture2D = preload("res://content/machines/hydroponics/art/interaction/hydroponics_zoom_back_empty.png")
const TEX_COVER: Texture2D = preload("res://content/machines/hydroponics/art/interaction/hydroponics_zoom_cover.png")
const TEX_FRONT_CAP: Texture2D = preload("res://content/machines/hydroponics/art/interaction/hydroponics_zoom_front_cap.png")
const TEX_HOVER: Texture2D = preload("res://content/machines/hydroponics/art/interaction/hover_cell_big.png")
const TEX_STAGE_1: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_1_seed.png")
const TEX_STAGE_2: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_2_sprout.png")
const TEX_STAGE_3: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_3_young.png")
const TEX_STAGE_4: Texture2D = preload("res://content/map/greenhouse/art/growth/cells_v4/cell_v4_stage_4_mature.png")
const FONT: Font = preload("res://assets/fonts/silkscreen/Silkscreen-Regular.ttf")
const SMALL_SCENE: String = "res://content/machines/hydroponics/visual/growth_demo/growth_demo.tscn"

const CELL_W: float = 36.0
const CELL_H: float = 34.0

## Real seconds per simulation tick of the demo. The state never reads the wall
## clock: this panel only feeds it ticks from its own accumulator.
const TICK_SECONDS: float = 0.5
const DEMO_RUN_SEED: int = 1

const COL_X: Array[float] = [83.0, 129.0, 175.0, 219.0]
const ROW_Y: Array[float] = [36.0, 82.0, 128.0]
const ROW_LETTERS: Array[String] = ["A", "B", "C"]

const BACK_RECT: Rect2 = Rect2(628.0, 256.0, 140.0, 26.0)
const HINT_DEMO: String = "CLICK AN EMPTY CELL TO SOW   CLICK A PLANT FOR OPTIONS"
const HINT_PAUSED: String = "GROWTH PAUSED - REPAIR OR POWER THE MACHINE"
const NOTICE_SECONDS: float = 3.0

const COLOR_BG: Color = Color("0f1626")
const COLOR_PANEL: Color = Color("111827")
const COLOR_BORDER: Color = Color("3d495e")
const COLOR_BAR: Color = Color("232d42")
const COLOR_DIM: Color = Color("7d8ca3")
const COLOR_TEXT: Color = Color("d8e2f0")
const COLOR_ACCENT: Color = Color("f4c25a")
const COLOR_CYAN: Color = Color("5fb6da")
const COLOR_GREEN: Color = Color("6d9257")
const COLOR_ORANGE: Color = Color("e8763a")
const COLOR_DARK: Color = Color("111827")

var vitrine: Node2D
var stages: Array[Texture2D] = []
var zoom_cells: Array[Sprite2D] = []

var status_label: Label
var hover: Sprite2D
var hint_label: Label

## Own cultivation state of the demo. Each visual scene keeps its own copy, so
## opening the demo never mutates a running game. It is replaced by the station
## state while the interface is bound.
var _state: HydroponicsState = HydroponicsState.new(DEMO_RUN_SEED)
var _tick_accumulator: float = 0.0
## Station this interface is showing, or null while it runs as a standalone demo.
var _station: HydroponicsStation = null
## Short message shown in the hint line after a rejected action.
var _notice: String = ""
var _notice_seconds: float = 0.0

var popup_index: int = -1
var popup_stage: int = -1
var popup_nodes: Array[Node] = []
var popup_harvest_rect: Rect2 = Rect2()
var popup_remove_rect: Rect2 = Rect2()
var popup_close_rect: Rect2 = Rect2()


func _ready() -> void:
	if _station == null:
		_state.reset()
	stages = [TEX_STAGE_1, TEX_STAGE_2, TEX_STAGE_3, TEX_STAGE_4]
	_build_background()
	vitrine = Node2D.new()
	vitrine.name = "Vitrine"
	add_child(vitrine)
	_build_vitrine()
	_build_sidebar()
	_sync_cells()


## Binds the interface to the station that owns the cultivation state. While
## bound, the simulation tick grows the cells through the station and every
## action asks the station again, so a machine that broke with the interface
## open cannot be planted or harvested. The local tick accumulator is dropped
## because the station already receives the ticks from [GameSim].
func bind_station(station: HydroponicsStation) -> void:
	_station = station
	_tick_accumulator = 0.0
	_notice = ""
	_notice_seconds = 0.0
	if station != null and station.cultivation != null:
		_state = station.cultivation
	_clear_popup()
	_sync_cells()


## Station this interface is bound to, or null while it runs as a demo.
func get_station() -> HydroponicsStation:
	return _station


func _rect(pos: Vector2, size: Vector2, color: Color, z: int = 0) -> ColorRect:
	var r: ColorRect = ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.z_index = z
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _label(pos: Vector2, text: String, size: int, color: Color, z: int = 0) -> Label:
	var l: Label = Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.z_index = z
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _meter(meter_name: String, value: int, color: Color, y: float) -> void:
	_label(Vector2(628, y - 8), meter_name, 8, COLOR_DIM)
	_rect(Vector2(712, y), Vector2(96, 8), Color("0a1728"))
	_rect(Vector2(712, y), Vector2(96.0 * float(value) / 100.0, 8), color)
	_label(Vector2(812, y - 6), "%d%%" % value, 8, COLOR_TEXT)


func _sprite(tex: Texture2D, pos: Vector2, scale_factor: float, z: int, parent: Node) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	s.scale = Vector2(scale_factor, scale_factor)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = z
	parent.add_child(s)
	return s


func _build_background() -> void:
	_rect(Vector2.ZERO, Vector2(850, 480), COLOR_BG)
	_rect(Vector2(8, 8), Vector2(834, 464), COLOR_BORDER)
	_rect(Vector2(10, 10), Vector2(830, 460), COLOR_PANEL)
	_rect(Vector2(10, 10), Vector2(830, 48), COLOR_BAR)
	_rect(Vector2(10, 58), Vector2(830, 1), COLOR_BORDER)
	_rect(Vector2(14, 58), Vector2(600, 392), COLOR_BORDER)
	_rect(Vector2(15, 59), Vector2(598, 390), Color("0a1728"))
	_label(Vector2(28, 26), "HYDROPONICS", 16, COLOR_TEXT)
	_label(Vector2(224, 34), "VITRINE v4  ZOOM MODE", 8, COLOR_DIM)
	hint_label = _label(Vector2(20, 452), HINT_DEMO, 8, COLOR_DIM)


func _build_vitrine() -> void:
	vitrine.position = Vector2(20, 60)
	vitrine.scale = Vector2(2, 2)
	vitrine.z_index = 10
	_sprite(TEX_REAR_CAP, Vector2.ZERO, 1.0, -6, vitrine)
	_sprite(TEX_BACK, Vector2.ZERO, 1.0, -5, vitrine)
	var plants: Node2D = Node2D.new()
	plants.name = "Plants"
	plants.z_index = 0
	vitrine.add_child(plants)
	for row: int in range(3):
		for col: int in range(4):
			var pos: Vector2 = Vector2(COL_X[col], ROW_Y[row] - 2.0)
			var cell: Sprite2D = _sprite(TEX_STAGE_1, pos, 3.0, 0, plants)
			cell.visible = false
			zoom_cells.append(cell)
	_sprite(TEX_COVER, Vector2.ZERO, 1.0, 1, vitrine)
	_sprite(TEX_FRONT_CAP, Vector2.ZERO, 1.0, 2, vitrine)
	hover = _sprite(TEX_HOVER, Vector2.ZERO, 1.0, 3, vitrine)
	hover.visible = false


func _build_sidebar() -> void:
	_label(Vector2(628, 80), "STATUS", 16, COLOR_TEXT)
	status_label = _label(
		Vector2(628, 110), "SOWN 0/12\nMATURE 0/12\nHARVESTED 0", 8, COLOR_ACCENT
	)
	_meter("WATER", 78, COLOR_CYAN, 154)
	_meter("NUTRIENTS", 62, COLOR_GREEN, 178)
	_meter("LIGHT", 90, COLOR_ACCENT, 202)
	_meter("RADIATION", 12, COLOR_ORANGE, 226)
	_rect(BACK_RECT.position, BACK_RECT.size, COLOR_BORDER)
	_label(BACK_RECT.position + Vector2(12, 8), "Back", 8, COLOR_TEXT)


func _sync_cells() -> void:
	for i: int in range(zoom_cells.size()):
		var stage: int = _state.stage_of(i)
		zoom_cells[i].visible = stage > 0
		if stage > 0:
			zoom_cells[i].texture = stages[stage - 1]


## Sows one cell. Bound to a station the planting goes through it, so a machine
## that is broken, unpowered or inside a finished run rejects the sow; the demo
## keeps planting its own state.
func _plant(index: int) -> bool:
	var accepted: bool = false
	if _station != null:
		accepted = _station.plant_cell(index)
	else:
		accepted = _state.plant(index)
	if not accepted:
		AudioManager.play(AudioManager.Sfx.UI_DENY)
		return false
	AudioManager.play(AudioManager.Sfx.PLANT)
	zoom_cells[index].texture = stages[0]
	zoom_cells[index].visible = true
	return true


## Pulls out one cell. Hides the cell sprite only when the state accepted the
## removal; otherwise the next frame would make it visible again.
func _clear(index: int) -> bool:
	var removed: bool = false
	if _station != null:
		removed = _station.remove_cell(index)
	else:
		removed = _state.remove(index)
	if removed:
		AudioManager.play(AudioManager.Sfx.REMOVE)
		zoom_cells[index].visible = false
	else:
		AudioManager.play(AudioManager.Sfx.UI_DENY)
	return removed


## Collects one mature cell. Only the station adds food and only on success, so
## a rejected harvest never pays out.
func _harvest(index: int) -> bool:
	var collected: bool = false
	if _station != null:
		collected = _station.harvest_cell(index)
	else:
		collected = _state.harvest(index)
	if collected:
		AudioManager.play(AudioManager.Sfx.HARVEST)
		zoom_cells[index].visible = false
	else:
		AudioManager.play(AudioManager.Sfx.UI_DENY)
	return collected


func _cell_id(index: int) -> String:
	var row: int = int(index / 4)
	var col: int = index % 4
	return "%s%d" % [ROW_LETTERS[row], col + 1]


func _clear_popup() -> void:
	for node: Node in popup_nodes:
		node.queue_free()
	popup_nodes.clear()
	popup_index = -1
	popup_stage = -1
	popup_harvest_rect = Rect2()
	popup_remove_rect = Rect2()
	popup_close_rect = Rect2()


func _open_popup(index: int) -> void:
	AudioManager.play(AudioManager.Sfx.UI_CLICK)
	_clear_popup()
	popup_index = index
	popup_stage = _state.stage_of(index)
	var row: int = int(index / 4)
	var col: int = index % 4
	var cell_pos: Vector2 = Vector2(20.0 + COL_X[col] * 2.0, 60.0 + ROW_Y[row] * 2.0)
	var size: Vector2 = Vector2(160, 86)
	var pos: Vector2 = Vector2(cell_pos.x + 76.0, cell_pos.y)
	if pos.x + size.x > 600.0:
		pos.x = cell_pos.x - size.x - 6.0
	pos.x = clampf(pos.x, 20.0, 600.0 - size.x)
	pos.y = clampf(pos.y, 60.0, 444.0 - size.y)

	var panel: ColorRect = _rect(pos, size, COLOR_BORDER, 100)
	popup_nodes.append(panel)
	var inner: ColorRect = _rect(pos + Vector2(1, 1), size - Vector2(2, 2), COLOR_PANEL, 101)
	popup_nodes.append(inner)
	var close_pos: Vector2 = pos + Vector2(size.x - 22.0, 4.0)
	var close_bg: ColorRect = _rect(close_pos, Vector2(18, 18), COLOR_BORDER, 102)
	popup_nodes.append(close_bg)
	var close_label: Label = _label(close_pos + Vector2(5, 5), "X", 8, COLOR_TEXT, 103)
	popup_nodes.append(close_label)
	popup_close_rect = Rect2(close_pos, Vector2(18, 18))
	var title: Label = _label(pos + Vector2(10, 9), "CELL %s" % _cell_id(index), 8, COLOR_TEXT, 102)
	popup_nodes.append(title)
	var mature: bool = popup_stage == 4
	# A bound machine only offers harvest while it can actually cultivate; a
	# mature cell of a broken or unpowered machine still offers remove.
	var can_harvest: bool = mature and (_station == null or _station.can_cultivate())
	var stage_text: String = "MATURE" if mature else "GROWING"
	var stage_color: Color = COLOR_ACCENT if mature else COLOR_DIM
	var stage_label: Label = _label(pos + Vector2(10, 23), stage_text, 8, stage_color, 102)
	popup_nodes.append(stage_label)

	if can_harvest:
		var harvest_pos: Vector2 = pos + Vector2(8, 52)
		var harvest_bg: ColorRect = _rect(harvest_pos, Vector2(70, 24), COLOR_GREEN, 102)
		popup_nodes.append(harvest_bg)
		var harvest_label: Label = _label(harvest_pos + Vector2(10, 8), "Harvest", 8, COLOR_DARK, 103)
		popup_nodes.append(harvest_label)
		popup_harvest_rect = Rect2(harvest_pos, Vector2(70, 24))
		var remove_pos: Vector2 = pos + Vector2(82, 52)
		var remove_bg: ColorRect = _rect(remove_pos, Vector2(70, 24), COLOR_ORANGE, 102)
		popup_nodes.append(remove_bg)
		var remove_label: Label = _label(remove_pos + Vector2(12, 8), "Remove", 8, COLOR_DARK, 103)
		popup_nodes.append(remove_label)
		popup_remove_rect = Rect2(remove_pos, Vector2(70, 24))
	else:
		var remove_pos: Vector2 = pos + Vector2(8, 52)
		var remove_bg: ColorRect = _rect(remove_pos, Vector2(144, 24), COLOR_ORANGE, 102)
		popup_nodes.append(remove_bg)
		var remove_label: Label = _label(remove_pos + Vector2(52, 8), "Remove", 8, COLOR_DARK, 103)
		popup_nodes.append(remove_label)
		popup_remove_rect = Rect2(remove_pos, Vector2(144, 24))


func _hit_zoom(local: Vector2) -> int:
	for row: int in range(3):
		for col: int in range(4):
			var origin: Vector2 = Vector2(COL_X[col], ROW_Y[row])
			if Rect2(origin, Vector2(CELL_W, CELL_H)).has_point(local):
				return row * 4 + col
	return -1


## Converts real time into simulation ticks for the demo. The state has no clock
## of its own, so this accumulator is the only place that measures time.
func _advance_ticks(delta: float) -> void:
	_tick_accumulator += delta
	while _tick_accumulator >= TICK_SECONDS:
		_tick_accumulator -= TICK_SECONDS
		_state.advance_tick()


func _process(delta: float) -> void:
	# Bound to a station the simulation owns the ticks: GameSim advances the
	# station, which grows this very state. Only the demo accumulates its own.
	if _station == null:
		_advance_ticks(delta)

	if _notice_seconds > 0.0:
		_notice_seconds = maxf(0.0, _notice_seconds - delta)
		if is_zero_approx(_notice_seconds):
			_notice = ""

	var sown: int = 0
	var mature: int = 0
	for i: int in range(zoom_cells.size()):
		var stage: int = _state.stage_of(i)
		if stage > 0:
			sown += 1
			zoom_cells[i].visible = true
			zoom_cells[i].texture = stages[stage - 1]
		else:
			zoom_cells[i].visible = false
		if stage == 4:
			mature += 1
	status_label.text = "SOWN %d/12\nMATURE %d/12\nHARVESTED %d" % [
		sown, mature, _state.harvested
	]
	var running: bool = _station == null or _station.can_cultivate()
	status_label.add_theme_color_override(
		&"font_color", COLOR_ACCENT if running else COLOR_DIM
	)
	hint_label.text = _hint_text()

	if popup_index >= 0:
		var current: int = _state.stage_of(popup_index)
		if current == 0:
			_clear_popup()
		elif current != popup_stage:
			_open_popup(popup_index)

	var local: Vector2 = vitrine.to_local(get_viewport().get_mouse_position())
	var index: int = _hit_zoom(local)
	var stage_hover: int = _state.stage_of(index) if index >= 0 else -1
	var can_click: bool = popup_index < 0 and stage_hover >= 0
	hover.visible = can_click
	if can_click:
		hover.position = Vector2(COL_X[index % 4], ROW_Y[int(index / 4)])
		hover.modulate = Color(1, 1, 1, 1) if stage_hover == 0 else Color(1.0, 0.55, 0.35, 1.0)


## Text of the hint line: the latest rejection, the paused reason of a bound
## machine or the demo instructions.
func _hint_text() -> String:
	if not _notice.is_empty():
		return _notice
	if _station != null and not _station.can_cultivate():
		return HINT_PAUSED
	return HINT_DEMO


## Shows a short message after a rejected action, so the player knows why the
## cell did not change.
func _set_notice(text: String) -> void:
	_notice = text
	_notice_seconds = NOTICE_SECONDS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if _station != null:
			# The closed signal releases this node from the tree, so the viewport
			# has to be captured before emitting.
			var viewport: Viewport = get_viewport()
			closed.emit()
			if viewport != null:
				viewport.set_input_as_handled()
		return
	if not (event is InputEventMouseButton):
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return

	if popup_index >= 0:
		if popup_close_rect.has_point(click.position):
			_clear_popup()
			return
		if popup_harvest_rect.has_point(click.position):
			if _harvest(popup_index):
				_clear_popup()
			else:
				_set_notice("HARVEST REJECTED - CHECK POWER AND REPAIR")
			return
		if popup_remove_rect.has_point(click.position):
			if _clear(popup_index):
				_clear_popup()
			else:
				_set_notice("REMOVE REJECTED - CELL IS EMPTY")
			return
		_clear_popup()
		return

	var index: int = _hit_zoom(vitrine.to_local(click.position))
	if index >= 0:
		if _state.stage_of(index) == 0:
			if not _plant(index):
				_set_notice("SOW REJECTED - REPAIR OR POWER THE MACHINE")
		else:
			_open_popup(index)
		return
	if BACK_RECT.has_point(click.position):
		if _station != null:
			closed.emit()
		else:
			get_tree().change_scene_to_file(SMALL_SCENE)
