extends Node

const DIRECTIONS: PackedVector2Array = [
	Vector2(-1, -1),
	Vector2(1, -1),
	Vector2(-1, 1),
	Vector2(1, 1)
	]

signal player_turn
signal enemy_turn
signal hide_moves_enemies
signal remove_stun_from_enemies

var enemies: Dictionary[Vector2, Enemy2D] = {}
var counts: Dictionary[Vector2i, int] = {}

var attack_positions: Array[Vector2] = []

var player: Player2D
var tile_map: TileMapLayer
var region_map: Rect2i


func _ready() -> void:
	enemy_turn.connect(_on_enemy_turn)

	_set_map.call_deferred()


func _set_map() -> void:
	tile_map = get_tree().get_first_node_in_group("TileMap")

	if not is_instance_valid(tile_map):
		push_warning("Não existe TileMap")
		return

	var min_id: Vector2i = Vector2i.MAX
	var max_id: Vector2i = Vector2i.MIN

	for cell: Vector2i in tile_map.get_used_cells():
		var world: Vector2 = tile_map.to_global(tile_map.map_to_local(cell))
		var id: Vector2i = AStarGridSearch2D.world_to_id(world)

		counts[id] = counts.get(id, 0) + 1
		min_id = min_id.min(id)
		max_id = max_id.max(id)

	region_map = Rect2i(min_id, max_id - min_id + Vector2i.ONE)


func _on_enemy_turn() -> void:
	if enemies.is_empty():
		player_turn.emit()
		return

	hide_moves_enemies.emit()

	if not is_instance_valid(player):
		return

	attack_positions.clear()

	var active: Array[Enemy2D] = []

	for enemy: Enemy2D in enemies.values():
		attack_positions.append(enemy.analyze_options(player.global_position))
		active.append(enemy)

	for enemy: Enemy2D in active:
		if not is_instance_valid(player):
			return

		await enemy.turn(player)

	await create_tween().tween_interval(0.8).finished

	attack_positions.clear()
	player_turn.emit()
	remove_stun_from_enemies.emit()


func there_is_wall(global_pos: Vector2) -> bool:
	if not is_instance_valid(tile_map):
		return false

	var half: Vector2 = Vector2(tile_map.tile_set.tile_size) / 2.0
	var local: Vector2 = tile_map.to_local(global_pos)

	for dir: Vector2 in DIRECTIONS:
		var cell: Vector2i = tile_map.local_to_map(local + dir * half)

		if tile_map.get_cell_source_id(cell) != -1:
			return true

	return false
