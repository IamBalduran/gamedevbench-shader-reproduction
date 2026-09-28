extends CharacterBody2D
class_name Mob

signal removed(object: Node)

@export var minimap_icon: StringName = &"mob"


func _exit_tree() -> void:
	removed.emit(self)
