extends Area2D
class_name Crate

signal removed

@export var minimap_icon: Texture2D

func remove():
	removed.emit()
	queue_free()