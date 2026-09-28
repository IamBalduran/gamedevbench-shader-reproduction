class_name FlashlightPoint
extends Marker3D

## Priority levels for flashlight points.
enum Priority {
	low,	## Low priority.
	medium,	## Medium priority.
	high,	## High priority.
}

## The priority of this flashlight point.
@export var priority: Priority = Priority.low

## Whether this point has already been targeted.
var has_been_targeted: bool = false


## Resets the targeting state of this point back to untargeted.
func reset_target_state() -> void:
	has_been_targeted = false
