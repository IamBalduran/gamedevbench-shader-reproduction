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
	if debug_enabled:
		update_debug({
			"velocity": velocity,
			"desired_velocity": scaled_desired_velocity,
			"steering_force": steering_adjustment,
		})
	return velocity + steering_adjustment

func update_debug(dict: Dictionary) -> void:
	for key in dict:
		debug[key] = dict[key]

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	pass
