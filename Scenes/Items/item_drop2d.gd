extends Sprite2D
class_name ItemDrop2D

@export var item_scene: PackedScene

func _ready() -> void:
	CombatManager.items[global_position] = self
