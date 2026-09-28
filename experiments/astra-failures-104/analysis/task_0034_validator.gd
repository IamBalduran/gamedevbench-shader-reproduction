extends Node

func _ready():
	run_validation()

func run_validation():
	var main_node = get_node("Main")
	if not main_node:
		return _fail("Main node not found")

	var fish = main_node.get_node("Fish")
	if not fish:
		return _fail("Fish node not found under Main")

	var steer_component = fish.get_node("SteerComponent")
	if not steer_component:
		return _fail("SteerComponent node missing")

	if not steer_component.has_method("steer"):
		return _fail("SteerComponent is missing steer() method")

	steer_component.debug_enabled = true
	steer_component.debug.clear()

	var velocity = Vector2(20, -10)
	var origin = Vector2(12, 32)
	var target = Vector2(92, -4)
	var max_speed = 80.0
	var mass = 40.0
	var result = steer_component.steer(velocity, origin, target, max_speed, mass)

	var desired = target - origin
	var scaled = desired
	if desired != Vector2.ZERO:
		scaled = desired.normalized() * max_speed
	else:
		scaled = Vector2.ZERO
	var steer_delta = (scaled - velocity) / mass
	var expected_velocity = velocity + steer_delta

	if not _vectors_close(result, expected_velocity):
		return _fail("steer() returned %s but expected %s" % [result, expected_velocity])

	var debug_dict = steer_component.debug
	for key in ["velocity", "scaled_desired_velocity", "steer"]:
		if not debug_dict.has(key):
			return _fail("debug dictionary missing %s entry" % key)

	if not _vectors_close(debug_dict["velocity"], velocity):
		return _fail("debug velocity entry incorrect")
	if not _vectors_close(debug_dict["scaled_desired_velocity"], scaled):
		return _fail("debug scaled_desired_velocity incorrect")
	if not _vectors_close(debug_dict["steer"], steer_delta):
		return _fail("debug steer entry incorrect")

	var script_text = FileAccess.get_file_as_string("res://scripts/steer_component.gd")
	if script_text.find("queue_redraw") == -1:
		return _fail("queue_redraw() call missing from steer_component.gd")

	print("VALIDATION_PASSED: Steering debug data recorded correctly")
	get_tree().quit()

func _vectors_close(a: Vector2, b: Vector2, tolerance: float = 0.05) -> bool:
	return a.distance_to(b) <= tolerance

func _fail(msg: String):
	print("VALIDATION_FAILED: %s" % msg)
	get_tree().quit(1)
