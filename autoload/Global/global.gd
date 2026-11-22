extends Node


func freeze_time(time_sec: float) -> void:
	Engine.time_scale = 0.0

	await get_tree().create_timer(time_sec, true, false, true).timeout

	Engine.time_scale = 1.0
