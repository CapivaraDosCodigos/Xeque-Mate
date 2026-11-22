extends Node2D
class_name Player2D

const SELECT_SCENE: PackedScene = preload("uid://cf3g6glncgoh7")

const TILE_SIZE: float = 32.0
const ROTATION_CAMERA: float = 5.0
const MOVE_DURATION: float = 0.4
const FREEZE_TIME_DURATION: float = 0.15

const STRETCH_VECTOR: Vector2 = Vector2(1.3, 0.7)

@onready var sprite: Sprite2D = $Sprite
@onready var particles: GPUParticles2D = $HitParticles
@onready var camera: SimpleCamera2D = $Camera

@export var health: HealthComponent = HealthComponent.new()
@export var item: Item2D:
	get():
		if is_instance_valid(item):
			return item

		for node in sprite.get_children():
			if node is Item2D:
				item = node
				break

		return item

var selects: Array[Select2D] = []

var in_battle: bool = false


func _init() -> void:
	CombatManager.player_turn.connect(_show_selects)
	CombatManager.player = self


func _ready() -> void:
	_create_selections()

	_show_selects.call_deferred()


func _physics_process(delta: float) -> void:
	if not in_battle:
		position += Inputs.get_input() * 100 * delta


func _create_selections() -> void:
	for select in selects:
		select.queue_free()

	selects.clear()

	var selections: Dictionary[Vector2i, PackedVector2Array] = item.selections

	if selections.is_empty():
		push_warning("%s: 'selections' está vazio, o player nunca vai se mover." % name)

	for select_position: Vector2i in selections.keys():
		var select: Select2D = SELECT_SCENE.instantiate()
		select.position = select_position * TILE_SIZE
		select.pressed_attack.connect(_on_pressed_attack)
		select.pressed_move.connect(_on_pressed_move)
		select.necessary_selections = selections[select_position]

		add_child(select)

		selects.append(select)


func _show_selects() -> void:
	for select: Select2D in selects:
		select.check_and_show()


func _hide_selects() -> void:
	CombatManager.hide_moves_enemies.emit()

	for select: Select2D in selects:
		select.hide()


func _on_pressed_move(pos: Vector2) -> void:
	_hide_selects()

	var tween_move: Tween = create_tween().set_parallel(true)

	tween_move.tween_property(self, "global_position", pos, MOVE_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_EXPO).set_delay(0.1)

	var direction: Vector2 = global_position.direction_to(pos)

	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0
		tween_move.tween_property(
				camera,
				"rotation",
				deg_to_rad(direction.x * ROTATION_CAMERA),
				MOVE_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)

	item.aim_at(direction, tween_move, MOVE_DURATION)

	await tween_move.finished

	CombatManager.enemy_turn.emit()


func _on_pressed_attack(enemy: Enemy2D) -> void:
	_hide_selects()

	var direction: Vector2 = global_position.direction_to(enemy.global_position)
	var distance: float = global_position.distance_to(enemy.global_position)
	var tween: Tween = create_tween().set_parallel(true)

	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0
		tween.tween_property(
				camera,
				"rotation",
				deg_to_rad(direction.x * ROTATION_CAMERA),
				MOVE_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)

	if item.aim_at(direction, tween, MOVE_DURATION):
		tween.tween_interval(0.2)

	await tween.finished

	tween = create_tween()

	tween.parallel().tween_property(item.sprite, "offset", Vector2(0.0, -distance + 8.0), 0.3) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(item.sprite_shadow, "offset", Vector2(0.0, -distance + 8.0), 0.3) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	await tween.finished

	HitAnimation.hit_enemy(item.damage, global_position, enemy)

	await Global.freeze_time(FREEZE_TIME_DURATION)

	tween = create_tween().set_parallel(true)

	tween.tween_property(item.sprite, "offset", Vector2.ZERO, 0.2) \
		.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(item.sprite_shadow, "offset", Vector2.ZERO, 0.2)\
		.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

	await tween.finished

	await create_tween().tween_interval(1.0).finished

	CombatManager.enemy_turn.emit()
