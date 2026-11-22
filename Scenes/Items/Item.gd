@tool
extends Node2D
class_name Item2D

const T: Texture2D = preload("uid://r8sanljkd65h")

const ATTACK: StringName = "Attack"
const ATTACK_V: StringName = "Attack_V"

@onready var sprite: Sprite2D = $Sprite
@onready var sprite_shadow: Sprite2D = $SpriteShadow

@export var damage: int = 100
@export var selections: Dictionary[Vector2i, PackedVector2Array] = {}:
	set(value):
		selections = value
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or is_instance_valid(owner):
		return

	for pos: Vector2i in selections.keys():
		draw_texture(T, (pos * 32.0) - Vector2.ONE * 8.0)
		for pos_i in selections[pos]:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * 0.5)
			draw_texture(T, ((pos * 64.0) - Vector2.ONE * 8.0) - pos_i * 16.0, Color.AQUA)
			draw_set_transform(Vector2.ZERO)


func aim_at(direction: Vector2, tween: Tween, duration: float) -> bool:
	if direction.is_zero_approx():
		return false

	var target: float = rotation + angle_difference(rotation, direction.angle())

	tween.tween_property(self, "rotation", target, duration) \
		.set_ease(Tween.EASE_IN_OUT) \
		.set_trans(Tween.TRANS_BACK)
	return true
