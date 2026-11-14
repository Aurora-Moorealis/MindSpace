extends Node2D
## Escena de muestra de los tilesets.
##
## Pinta un trozo de mapa con suelo, una sala de base y props (rocas y
## minerales) usando los tres TileSet. Es una referencia visual para comprobar
## que los tres encajan; no forma parte del flujo del juego.

const GROUND_VARIANTS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
]

const GROUND_TILE: Vector2i = Vector2i(0, 1)
const GROUND_PLATE: Vector2i = Vector2i(0, 0)
const GROUND_CORRIDOR: Vector2i = Vector2i(0, 2)
const GROUND_DOOR: Vector2i = Vector2i(3, 1)

const ROOM_LEFT: int = 3
const ROOM_RIGHT: int = 11
const ROOM_TOP: int = 3
const ROOM_BOTTOM: int = 10
const ROOM_CORRIDOR_X: int = 7

const COLS: int = 27
const ROWS: int = 15

@onready var _ground: TileMapLayer = $Ground
@onready var _base: TileMapLayer = $Base
@onready var _props: TileMapLayer = $Props


func _ready() -> void:
	_paint_ground()
	_paint_room()
	_paint_props()


func _paint_ground() -> void:
	for y: int in ROWS:
		for x: int in COLS:
			var index: int = (x * 7 + y * 13) % GROUND_VARIANTS.size()
			_ground.set_cell(Vector2i(x, y), 0, GROUND_VARIANTS[index])


func _paint_room() -> void:
	for y: int in range(ROOM_TOP, ROOM_BOTTOM + 1):
		for x: int in range(ROOM_LEFT, ROOM_RIGHT + 1):
			var cell: Vector2i = Vector2i(x, y)
			if y == ROOM_TOP:
				_base.set_cell(cell, 0, GROUND_TILE, 0)      # canto arriba
			elif y == ROOM_BOTTOM:
				_base.set_cell(cell, 0, GROUND_TILE, 3)      # canto abajo
			elif x == ROOM_LEFT:
				_base.set_cell(cell, 0, GROUND_TILE, 1)      # canto izquierda
			elif x == ROOM_RIGHT:
				_base.set_cell(cell, 0, GROUND_TILE, 2)      # canto derecha
			elif x == ROOM_CORRIDOR_X:
				_base.set_cell(cell, 0, GROUND_CORRIDOR)
			else:
				_base.set_cell(cell, 0, GROUND_PLATE)
	# puerta en el muro inferior
	_base.set_cell(Vector2i(ROOM_CORRIDOR_X, ROOM_BOTTOM), 0, GROUND_DOOR)


func _paint_props() -> void:
	# rocas: fila 0 del atlas de props
	var rocks: Array[Vector2i] = [
		Vector2i(1, 12), Vector2i(2, 2), Vector2i(14, 4), Vector2i(17, 12),
		Vector2i(20, 2), Vector2i(24, 11), Vector2i(5, 13),
	]
	for i: int in rocks.size():
		var atlas: Vector2i = Vector2i(i % 5, 0)
		_props.set_cell(rocks[i], 0, atlas)

	# minerales: fila 1 del atlas de props (0 ilmenita, 1 silice, 2 hielo, 3 basalto)
	# x e y son la celda; z es el mineral
	var deposits: Array[Vector3i] = [
		Vector3i(13, 7, 0), Vector3i(14, 7, 0), Vector3i(13, 8, 0),
		Vector3i(16, 8, 1), Vector3i(17, 7, 1),
		Vector3i(20, 12, 2), Vector3i(21, 12, 2), Vector3i(22, 13, 2),
		Vector3i(5, 1, 3), Vector3i(6, 1, 3),
	]
	for deposit: Vector3i in deposits:
		_props.set_cell(Vector2i(deposit.x, deposit.y), 0, Vector2i(deposit.z + 1, 1))
