@tool
extends Node2D

const T: Texture2D = preload("uid://dfyq3c7tjk451")
const TILE_SIZE: float = 32.0

## Margem extra ao redor da área do mapa, em tiles de 32px.
@export var margin: int = 0:
	set(value):
		margin = maxi(value, 0)
		_schedule_update()

var _cells: Rect2i = Rect2i() # área a desenhar, em células de 32px
var _pending: bool = false


func _enter_tree() -> void:
	var parent: TileMapLayer = get_parent() as TileMapLayer

	if parent and not parent.changed.is_connected(_schedule_update):
		parent.changed.connect(_schedule_update)


func _exit_tree() -> void:
	var parent: TileMapLayer = get_parent() as TileMapLayer

	if parent and parent.changed.is_connected(_schedule_update):
		parent.changed.disconnect(_schedule_update)


func _ready() -> void:
	_schedule_update()


func _draw() -> void:
	for cy: int in range(_cells.position.y, _cells.end.y):
		# só as células de paridade par, pulando de 2 em 2
		var start_x: int = _cells.position.x + posmod(_cells.position.x + cy, 2)

		for cx: int in range(start_x, _cells.end.x, 2):
			draw_texture(T, Vector2(cx, cy) * TILE_SIZE)


## Agrupa várias mudanças seguidas do tilemap em uma única atualização.
func _schedule_update() -> void:
	if _pending or not is_inside_tree():
		return

	_pending = true
	_update_cells.call_deferred()


func _update_cells() -> void:
	_pending = false

	var map: TileMapLayer = get_parent() as TileMapLayer

	if map == null or map.tile_set == null:
		return

	var used: Rect2i = map.get_used_rect()
	var cells: Rect2i = Rect2i()

	if used.has_area():
		var tile: Vector2 = Vector2(map.tile_set.tile_size)

		# arredonda para fora, na grade de 32px
		var first: Vector2i = Vector2i((Vector2(used.position) * tile / TILE_SIZE).floor())
		var last: Vector2i = Vector2i((Vector2(used.end) * tile / TILE_SIZE).ceil())

		first -= Vector2i.ONE * margin
		last += Vector2i.ONE * margin

		cells = Rect2i(first, last - first)

	if cells == _cells:
		return # nada mudou, não redesenha

	_cells = cells
	queue_redraw()
