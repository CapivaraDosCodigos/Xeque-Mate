extends AStarGrid2D
class_name AStarGridSearch2D

const TILE_SIZE: float = 32.0
const OFFSET: Vector2 = Vector2(-16.0, -16.0)
const MIN_TILES_TO_BLOCK: int = 2


func _init(region_map: Rect2i,
	counts: Dictionary[Vector2i, int],
	diagonal: DiagonalMode,
	jumping: bool) -> void:

	region = region_map

	diagonal_mode = diagonal
	jumping_enabled = jumping

	cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	offset = OFFSET
	update()

	for id: Vector2i in counts:
		if counts[id] >= MIN_TILES_TO_BLOCK:
			set_point_solid(id, true)


func get_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a: Vector2i = world_to_id(from)
	var b: Vector2i = world_to_id(to)

	if not is_in_boundsv(a) or not is_in_boundsv(b):
		push_warning("Fora da região")
		return PackedVector2Array()

	return get_point_path(a, b)


func best_position(from: Vector2, to: Vector2, options: Array[MoveOption]) -> Vector2:
	var moves: Array[Vector2] = []

	for option: MoveOption in options:
		if option.is_move():
			moves.append(from + option.position)

	if moves.is_empty():
		return from

	var path: PackedVector2Array = get_path(from, to)

	if path.size() <= 2:
		return moves.pick_random()

	for i: int in range(path.size() - 2, 0, -1): # Elimina o primeiro e último.
		for move: Vector2 in moves:
			if move.distance_squared_to(path[i]) < 1.0:
				return move

	var target: Vector2 = path[1]
	var best: Vector2 = from
	var best_distance: float = INF

	for move: Vector2 in moves:
		var distance: float = move.distance_squared_to(target)

		if distance < best_distance:
			best_distance = distance
			best = move

	return best


func worse_position(from: Vector2, to: Vector2, options: Array[MoveOption]) -> Vector2:
	var moves: Array[Vector2] = []

	for option: MoveOption in options:
		if option.is_move():
			moves.append(from + option.position)

	if moves.is_empty():
		return from

	var worse: Vector2 = from
	var worse_distance: float = 0.0

	for move: Vector2 in moves:
		var distance: float = move.distance_squared_to(to)

		if distance > worse_distance:
			worse_distance = distance
			worse = move

	return worse


static func world_to_id(world: Vector2) -> Vector2i:
	var half: Vector2 = Vector2.ONE * TILE_SIZE / 2.0

	return Vector2i(((world - OFFSET + half) / TILE_SIZE).floor())
