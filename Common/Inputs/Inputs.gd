class_name Inputs extends Object


static func get_input() -> Vector2:
	var input_x: float = Input.get_axis("ui_left", "ui_right")
	var input_y: float= Input.get_axis("ui_up", "ui_down")

	if !is_equal_approx(input_x, 0.0) and abs(input_x) > 0.3:
		input_x = abs(input_x) / input_x
	else:
		input_x = 0.0

	if !is_equal_approx(input_y, 0.0) and abs(input_y) > 0.3:
		input_y = abs(input_y) / input_y
	else:
		input_y = 0.0

	return Vector2(input_x, input_y)


static func is_input_horizontal() -> bool:
	var pressed: bool = Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left")
	var released: bool = Input.is_action_just_released("ui_right") or Input.is_action_just_released("ui_left")
	return pressed or released


static func is_input_vertical() -> bool:
	var pressed: bool = Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")
	var released: bool = Input.is_action_just_released("ui_up") or Input.is_action_just_released("ui_down")
	return pressed or released
