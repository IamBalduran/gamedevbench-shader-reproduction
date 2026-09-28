class_name FlashlightPoint
extends Node3D

enum Priority { LOW, MEDIUM, HIGH }

@export var priority: Priority = Priority.MEDIUM
@export var has_been_targeted: bool = false

func _ready() -> void:
	add_to_group("FlashlightPoints")

func reset_target_state() -> void:
	has_been_targeted = false