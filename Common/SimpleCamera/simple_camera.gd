extends Camera2D
class_name SimpleCamera2D

const SHAKE_INTERVAL: int = 5
const SHAKE_INTERVAL_RANGE: float = 100.0

var _shake_tween: Tween


func shake(magnitude: float = 5.0, duration: float = 0.5) -> void:
	ignore_rotation = false

	var original_rotation: float = rotation

	rotation = deg_to_rad([-10.0, 10.0].pick_random() as float)

	_shake_tween = create_tween().set_parallel(true)

	_shake_tween.tween_property(self, "rotation", original_rotation, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

	_shake_tween.tween_method(_set_shake_offset.bind(magnitude), 0.0, 1.0, duration)

	_shake_tween.tween_callback(func() -> void: position = Vector2.ZERO)


func _set_shake_offset(value: float, magnitude: float = 10.0) -> void:
	if int(value * SHAKE_INTERVAL_RANGE) % SHAKE_INTERVAL:
		position = Vector2(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude))
