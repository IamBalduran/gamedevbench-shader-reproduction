extends Area2D
class_name Crate

signal removed(object: Node)

@export var minimap_icon: StringName = &"alert"


func _exit_tree() -> void:
	removed.emit(self)
