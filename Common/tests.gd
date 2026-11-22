@tool
extends EditorScript


func _run() -> void:
	var s: String = "var s: String = %s
print(s % s)"
	print(s % s)
	print(snappedf(32, 32))
