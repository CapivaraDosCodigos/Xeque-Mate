extends Sprite2D
class_name Select2D

const COLOR_ATTACK: Color = Color(0.714, 0.45, 0.533, 0.35)
const COLOR_MOVE: Color = Color(1.0, 1.0, 1.0, 0.35)

signal pressed_attack(enemy: Enemy2D)
signal pressed_move(pos: Vector2)

var necessary_selections: PackedVector2Array = []

enum State { NONE, MOVE, ATTACK }

var state: State = State.NONE
var _enemy: Enemy2D


func _ready() -> void:
	hide()


func check_and_show() -> void:
	if CombatManager.there_is_wall(global_position):
		state = State.NONE
		return

	for select: Vector2 in necessary_selections:
		var select_position: Vector2 = global_position - position
		select_position += select * 32.0

		if CombatManager.there_is_wall(select_position):
			state = State.NONE
			return

		if CombatManager.enemies.has(select_position):
			state = State.NONE
			return


	show()

	if CombatManager.enemies.has(global_position):
		state = State.ATTACK
		self_modulate = COLOR_ATTACK
		_enemy = CombatManager.enemies[global_position]
		return

	state = State.MOVE
	self_modulate = COLOR_MOVE


func _pressed() -> void:
	match state:
		State.MOVE:
			pressed_move.emit(global_position)

		State.ATTACK:
			if is_instance_valid(_enemy):
				pressed_attack.emit(_enemy)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_rect().has_point(to_local(get_global_mouse_position())):
			if is_visible_in_tree():
				_pressed()
