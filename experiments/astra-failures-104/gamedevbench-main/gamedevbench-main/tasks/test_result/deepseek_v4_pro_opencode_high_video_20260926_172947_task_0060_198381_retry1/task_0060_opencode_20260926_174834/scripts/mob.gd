extends CharacterBody2D
class_name Mob

signal removed

@export var minimap_icon: Texture2D

var _move_direction := 1.0

func _physics_process(delta):
	rotation += 0.5 * delta
	position += Vector2.RIGHT.rotated(rotation) * 40.0 * delta

func remove():
	removed.emit()
	queue_free()