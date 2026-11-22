@tool
extends Node2D
class_name Enemy2D

const TILE_SIZE: float = 32.0
const MOVE_DURATION: float = 0.4
const FREEZE_TIME_DURATION: float = 0.15

const DEBUG_TEXTURE: Texture2D = preload("uid://bip8x8ux8o4nv")

const COLOR_ATTACK: Color = Color(0.553, 0.317, 0.502, 0.35)

enum State { NONE, MOVE, ATTACK }

@export_group("AStarGrid2D", "star")
@export var star_diagonal_mode: AStarGrid2D.DiagonalMode = AStarGrid2D.DiagonalMode.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
@export var star_jumping_enabled: bool = false

@export var selections: Dictionary[Vector2i, PackedVector2Array] = {}:
	set(value):
		selections = value
		queue_redraw()

@export_group("Status")
@export var health: HealthComponent = HealthComponent.new()
@export var damage: int = 100

@export_category("DEBUG")
@export var line: Line2D

var options: Array[MoveOption] = []
var path: PackedVector2Array = []

var star: AStarGridSearch2D
var state: State = State.NONE

var last_position: Vector2
var target_position: Vector2

var is_stunned: bool = false

@onready var sprite: Sprite2D = $Sprite
@onready var particles: GPUParticles2D = $Sprite/HitParticles
@onready var draw_moves: CanvasDrawing = $Moves


func _draw() -> void:
	_draw_debug()


func _draw_debug() -> void:
	if not Engine.is_editor_hint() or is_instance_valid(owner):
		return

	for offset: Vector2i in selections:
		draw_texture(DEBUG_TEXTURE, Vector2(offset) * TILE_SIZE - Vector2.ONE * 8.0, Color.RED)

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * 0.5)

		for required: Vector2 in selections[offset]:
			draw_texture(DEBUG_TEXTURE, Vector2(offset) * 64.0 - Vector2.ONE * 8.0 - required * 16.0, Color.AQUA)

		draw_set_transform(Vector2.ZERO)


func _process(_delta: float) -> void:
	if not is_instance_valid(line) or Engine.is_editor_hint():
		return

	var player: Player2D = CombatManager.player

	if not is_instance_valid(player):
		return

	path = star.get_path(global_position, player.global_position)

	if path.size() < 2:
		return


	line.points = path


func _exit_tree() -> void:
	CombatManager.enemies.erase(last_position)
	if line:
		line.queue_free()


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	CombatManager.hide_moves_enemies.connect(draw_moves.hide)
	CombatManager.remove_stun_from_enemies.connect(self.set.bind("is_stunned", false))
	CombatManager.player_turn.connect(_show_moves)

	CombatManager.enemies[global_position] = self
	last_position = global_position

	_build_options()

	_build_star.call_deferred()
	_show_moves.call_deferred()


func _show_moves() -> void:
	var player: Player2D = CombatManager.player

	if not is_instance_valid(player):
		return

	draw_moves.show()
	draw_moves.draws.clear()

	for option: MoveOption in options:
		option.check(global_position, player.global_position)

		if option.state == MoveOption.State.NONE:
			continue

		draw_moves.drawing(
			DEBUG_TEXTURE,
			Vector2(option.position) / 2.0 - Vector2(8.0, 8.0),
			COLOR_ATTACK)

	draw_moves.queue_redraw()


func _build_star() -> void:
	star = AStarGridSearch2D.new(
		CombatManager.region_map,
		CombatManager.counts,
		star_diagonal_mode,
		star_jumping_enabled
		)


func _build_options() -> void:
	if selections.is_empty():
		push_warning("%s: 'selections' está vazio, o inimigo nunca vai se mover." % name)

	for option_position: Vector2i in selections:
		var option: MoveOption = MoveOption.new(option_position * TILE_SIZE)
		options.append(option)
		option.necessary_options = selections[option_position]


func analyze_options(player_position: Vector2) -> Vector2:
	state = State.NONE
	target_position = global_position

	var can_attack: bool = false
	var can_move: bool = false

	for option: MoveOption in options:
		option.check(global_position, player_position)

		can_attack = can_attack or (option.is_attack() and not is_stunned)
		can_move = can_move or option.is_move()

	if can_attack:
		state = State.ATTACK

	elif can_move:
		if not is_stunned:
			target_position = star.best_position(global_position, player_position, options)
		else:
			target_position = star.worse_position(global_position, player_position, options)

		if not target_position.is_equal_approx(global_position):
			state = State.MOVE

	return target_position


func turn(player: Player2D) -> void:
	match state:
		State.ATTACK:
			await turn_attack(player)
		State.MOVE:
			turn_move()


func turn_attack(player: Player2D) -> void:
	var original_position: Vector2 = global_position
	var target: Vector2 = player.global_position
	var direction: Vector2 = global_position.direction_to(target)

	z_index = 2

	if not is_zero_approx(direction.x):
		sprite.flip_h = direction.x < 0.0

	var tween_in: Tween = create_tween()
	tween_in.tween_property(sprite, "global_position", target, 0.3) \
		.set_ease(Tween.EASE_OUT_IN) \
		.set_trans(Tween.TRANS_EXPO)

	await tween_in.finished

	HitAnimation.hit_player(damage, global_position, player)

	await Global.freeze_time(FREEZE_TIME_DURATION)

	var tween_out: Tween = create_tween()

	tween_out.tween_property(sprite, "global_position", original_position, 0.2) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CIRC)

	await tween_out.finished
	z_index = 0


func turn_move() -> void:
	if target_position == global_position:
		return

	CombatManager.enemies.erase(last_position)
	var direction: Vector2 = global_position.direction_to(target_position)

	if not is_zero_approx(direction.x):
		sprite.flip_h = direction.x < 0.0

	var tween: Tween = create_tween()

	tween.tween_property(self, "global_position", target_position, MOVE_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_EXPO) \
		.set_delay(0.1)

	tween.tween_callback(func() -> void:
		CombatManager.enemies[global_position] = self;
		last_position = global_position)
