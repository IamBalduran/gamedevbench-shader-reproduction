extends Marker3D

enum Priority {
	LOW,
	MEDIUM,
	HIGH,
}

@export var priority: Priority = Priority.LOW
@export var has_been_targeted: bool = false


func reset_target_state() -> void:
	has_been_targeted = false
