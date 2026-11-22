extends Node2D
class_name CanvasDrawing

var draws: Array[Callable]:
	set(value):
		draws = value

func _init() -> void:
	z_index = -2
	scale = Vector2.ONE * 2.0


func _draw() -> void:
	for i in draws:
		i.call()


func drawing(t: Texture2D, p: Vector2, m: Color = Color(1, 1, 1, 1)) -> void:
	draws.append(draw_texture.bind(t, p, m))
