extends Resource
class_name HealthComponent

signal hit

@export_range(1, 1, 1, "or_greater") var max_value: int = 300

var value: int = 300:
	set(new_value):
		if new_value < value:
			hit.emit()

		value = clampi(new_value, 0, max_value)


func _init() -> void:
	_update_health.call_deferred()


func _update_health() -> void:
	value = max_value



func is_life() -> bool:
	return value > 0
