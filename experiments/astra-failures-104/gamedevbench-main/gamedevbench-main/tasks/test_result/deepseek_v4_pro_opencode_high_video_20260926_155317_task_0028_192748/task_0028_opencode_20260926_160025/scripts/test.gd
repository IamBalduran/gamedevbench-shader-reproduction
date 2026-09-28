extends Node

var flashlight_point_script: Script
var required_points := {
	"PillarPoint": {
		"priority": 1,
		"position": Vector3(8.36166, 1.81915, -12.0301)
	},
	"GatePoint": {
		"priority": 0,
		"position": Vector3(-16.6577, 2.41884, -39.9426)
	},
	"EnemyPoint": {
		"priority": 2,
		"position": Vector3(23.0185, 2.63927, -86.6948)
	}
}

func _ready():
	flashlight_point_script = load("res://scripts/flashlight_point.gd")
	if flashlight_point_script == null:
		_fail("scripts/flashlight_point.gd is missing")
		return
	run_validation()

func run_validation():
	var main := get_node_or_null("Main")
	if main == null:
		_fail("Main scene not instanced")
		return

	var camera := main.get_node_or_null("Camera3D")
	if camera == null or not (camera is Camera3D):
		_fail("Camera3D node missing or wrong type")
		return

	for point_name in required_points.keys():
		var node := main.get_node_or_null(point_name)
		if node == null:
			_fail(point_name + " node missing")
			return
		if not node.is_in_group("FlashlightPoints"):
			_fail(point_name + " is not in FlashlightPoints group")
			return
		if not (node is Marker3D):
			_fail(point_name + " is not a Marker3D")
			return
		if node.get_script() != flashlight_point_script:
			_fail(point_name + " is not using flashlight_point.gd")
			return

		if not node.has_method("reset_target_state"):
			_fail(point_name + " script missing reset_target_state() method")
			return

		var priority_value = node.get("priority")
		if typeof(priority_value) != TYPE_INT:
			_fail(point_name + " priority property missing")
			return
		var expected_priority: int = required_points[point_name]["priority"]
		if priority_value != expected_priority:
			_fail(point_name + " priority incorrect")
			return

		var targeted_value = node.get("has_been_targeted")
		if typeof(targeted_value) != TYPE_BOOL:
			_fail(point_name + " missing has_been_targeted flag")
			return
		if targeted_value:
			_fail(point_name + " should start un-targeted")
			return

		var expected_pos: Vector3 = required_points[point_name]["position"]
		if node.global_position.distance_to(expected_pos) > 0.05:
			_fail(point_name + " position mismatch: " + str(node.global_position))
			return

	print("VALIDATION_PASSED: Flashlight priority points configured")
	get_tree().quit()

func _fail(message: String) -> void:
	print("VALIDATION_FAILED: " + message)
	get_tree().quit(1)
