extends RefCounted
class_name MoveOption


enum State { NONE, MOVE, ATTACK }

const TILE_SIZE: float = 32.0
var state: State = State.NONE
var position: Vector2 = Vector2.ZERO

var necessary_options: PackedVector2Array = []


func _init(pos: Vector2) -> void:
	position = pos


func check(center: Vector2, player: Vector2) -> void:
	var global_position: Vector2 = center + position

	if CombatManager.there_is_wall(global_position):
		state = State.NONE
		return

	for select: Vector2 in necessary_options:
		var select_position: Vector2 = center + (select * 32.0)
		if CombatManager.there_is_wall(select_position):
			state = State.NONE
			return

	if CombatManager.attack_positions.has(global_position):
		state = State.NONE
		return

	if CombatManager.enemies.has(global_position):
		state = State.NONE
		return

	if player.is_equal_approx(global_position):
		state = State.ATTACK
		return

	state = State.MOVE


func is_move() -> bool:
	return state == State.MOVE


func is_attack() -> bool:
	return state == State.ATTACK
