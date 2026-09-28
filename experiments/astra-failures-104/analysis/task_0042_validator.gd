extends Node

func _ready():
	run_validation()

func fail(reason: String) -> void:
	print("VALIDATION_FAILED: %s" % reason)
	get_tree().quit(1)

func run_validation():
	var main_node = get_node_or_null("Main")
	if main_node == null:
		fail("Main node missing")
		return
	var camera = main_node.get_node_or_null("Camera2D")
	if camera == null:
		fail("Camera2D node missing")
		return
	if camera.get_script() == null or camera.get_script().resource_path != "res://scripts/Camera2D.gd":
		fail("Camera2D must use res://scripts/Camera2D.gd")
		return
	if not camera.has_method("shake"):
		fail("Camera2D script must expose shake()")
		return
	
	var pong_script = main_node.get_script()
	if pong_script == null:
		fail("Main node missing pong.gd script")
		return
	
	camera.displacement = 0.0
	camera.velocity = 0.0
	camera.position.x = 0.0
	
	main_node.reset_points()
	main_node._on_left_wall_right_point_up()
	if camera.velocity == 0.0:
		fail("new_ball must trigger camera shake velocity change")
		return
	
	camera._physics_process(0.016)
	if abs(camera.position.x) <= 0.01:
		fail("Camera shake must move camera position after physics process")
		return
	
	print("VALIDATION_PASSED")
	get_tree().quit(0)
