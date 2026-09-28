extends CharacterBody2D
class_name Mob

signal removed(object: Node2D)

@export_enum("mob", "alert") var minimap_icon: String = "mob"


func _exit_tree() -> void:
	removed.emit(self)
