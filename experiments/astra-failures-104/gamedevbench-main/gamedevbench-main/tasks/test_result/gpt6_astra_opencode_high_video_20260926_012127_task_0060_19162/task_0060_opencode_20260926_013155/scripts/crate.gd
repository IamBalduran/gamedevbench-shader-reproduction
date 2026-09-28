extends Area2D
class_name Crate

signal removed(object: Node2D)

@export_enum("mob", "alert") var minimap_icon: String = "alert"


func _exit_tree() -> void:
	removed.emit(self)
