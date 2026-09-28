extends Node2D

var debug_enabled: bool = false
var debug: Dictionary = {}

func steer(
	velocity: Vector2,
	global_position: Vector2,
	target_position: Vector2,
	max_speed: float = 200.0,
	mass: float = 20.0,
):
	var desired_velocity := target_position - global_position
	var scaled_desired_velocity := desired_velocity
	if desired_velocity != Vector2.ZERO:
		scaled_desired_velocity = desired_velocity.normalized() * max_speed
	else:
		scaled_desired_velocity = Vector2.ZERO

	var steering_adjustment := (scaled_desired_velocity - velocity) / mass
	return velocity + steering_adjustment

func update_debug(dict: Dictionary) -> void:
	for key in dict:
		debug[key] = dict[key]

func _process(_delta: float) -> void:
	pass

func _draw() -> void:
	pass
