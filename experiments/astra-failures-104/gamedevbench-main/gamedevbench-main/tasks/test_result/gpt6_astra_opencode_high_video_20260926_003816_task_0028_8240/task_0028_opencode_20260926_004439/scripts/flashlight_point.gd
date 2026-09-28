class_name FlashlightPoint
extends Marker3D

enum Priority { low, medium, high }

@export var priority: Priority = Priority.low
@export var has_been_targeted: bool = false


func reset_target_state() -> void:
	has_been_targeted = false
