extends Node

const REQUIRED_RESOURCE := "res://assets/clouds/tutorial_clouds_settings.tres"
const REQUIRED_CAMERA_FAR := 400000.0
const REQUIRED_COVERAGE := 0.874
const REQUIRED_ATMOSPHERIC_DENSITY := 0.617977
const REQUIRED_AMBIENT_TINT := Color(0.131626, 0.201524, 0.241773, 1)
const REQUIRED_ATMOSPHERE_COLOR := Color(0.696127, 0.832325, 0.989334, 1)

func _ready():
	run_validation()

func run_validation():
	var main = get_node_or_null("Main")
	if main == null:
		_fail("Main scene missing")
		return

	var camera = main.get_node_or_null("Camera3D")
	if camera == null or not (camera is Camera3D):
		_fail("Camera3D node missing")
		return
	if camera.far < REQUIRED_CAMERA_FAR - 0.5:
		_fail("Camera far plane must be set to 400000")
		return

	var world_env = main.get_node_or_null("WorldEnvironment")
	if world_env == null or not (world_env is WorldEnvironment):
		_fail("WorldEnvironment node missing")
		return
	if world_env.compositor == null:
		_fail("WorldEnvironment.compositor not assigned")
		return
	if world_env.compositor.compositor_effects.size() != 1:
		_fail("WorldEnvironment must have exactly one compositor effect")
		return

	var driver = main.get_node_or_null("SunshineCloudsDriver")
	if driver == null:
		_fail("SunshineCloudsDriver node missing")
		return
	var driver_script = driver.get_script()
	if driver_script == null or not driver_script.resource_path.ends_with("SunshineCloudsDriver.gd"):
		_fail("SunshineCloudsDriver must use addons/SunshineClouds2/SunshineCloudsDriver.gd")
		return

	if not driver.update_continuously:
		_fail("SunshineCloudsDriver must update continuously")
		return

	var clouds_resource = driver.get("clouds_resource")
	if clouds_resource == null:
		_fail("clouds_resource not assigned")
		return
	if clouds_resource.resource_path != REQUIRED_RESOURCE:
		_fail("Driver must reference " + REQUIRED_RESOURCE)
		return

	if world_env.compositor.compositor_effects[0] != clouds_resource:
		_fail("WorldEnvironment compositor must reuse the same clouds resource")
		return

	if driver.ambience_sample_environment != world_env.environment:
		_fail("Driver ambience_sample_environment must point to the WorldEnvironment resource")
		return

	if not _array_has_reference(driver.get("tracked_directional_lights"), "../DirectionalLight3D", driver):
		_fail("Directional light is not registered on the driver")
		return

	var shadow_steps = driver.get("tracked_directional_light_shadow_steps")
	if shadow_steps.size() != 1 or shadow_steps[0] != 32:
		_fail("Directional light shadow steps must contain a single entry set to 32")
		return

	if not _array_has_reference(driver.get("tracked_point_lights"), "../OmniLight3D", driver):
		_fail("Omni light is not wired to the driver")
		return

	var omni = main.get_node_or_null("OmniLight3D")
	if omni == null or not (omni is OmniLight3D):
		_fail("OmniLight3D missing from scene")
		return
	if omni.omni_range < 20000.0:
		_fail("OmniLight3D range must be at least 20000 to match the tutorial example")
		return

	if not _is_equal_approx(clouds_resource.clouds_coverage, REQUIRED_COVERAGE, 0.001):
		_fail("Cloud coverage must be set to " + str(REQUIRED_COVERAGE))
		return
	if not _is_equal_approx(clouds_resource.atmospheric_density, REQUIRED_ATMOSPHERIC_DENSITY, 0.001):
		_fail("Atmospheric density must be lowered to ~0.618")
		return

	if clouds_resource.cloud_ambient_color != Color(1, 1, 1, 1):
		_fail("Cloud ambient color must be pure white")
		return
	if not _is_color_close(clouds_resource.cloud_ambient_tint, REQUIRED_AMBIENT_TINT, 0.01):
		_fail("Cloud ambient tint must match the darker blue tint from the resource guide")
		return
	if not _is_color_close(clouds_resource.atmosphere_color, REQUIRED_ATMOSPHERE_COLOR, 0.01):
		_fail("Atmosphere color must be the cooler blue tone from the tutorial settings")
		return

	if clouds_resource.mask_width_km < 400.0:
		_fail("Mask width should remain large to cover the play space")
		return

	print("VALIDATION_PASSED: Sunshine Clouds driver and lighting configured")
	get_tree().quit()

func _array_has_reference(arr: Array, path: String, driver: Node) -> bool:
	var expected_path = NodePath(path)
	for entry in arr:
		match typeof(entry):
			TYPE_NODE_PATH:
				if NodePath(entry).get_concatenated_names() == expected_path.get_concatenated_names():
					return true
			TYPE_OBJECT:
				if entry is Node:
					var node = driver.get_node_or_null(expected_path)
					if node != null and entry == node:
						return true
	return false

func _is_equal_approx(a: float, b: float, tolerance: float) -> bool:
	return abs(a - b) <= tolerance

func _is_color_close(a: Color, b: Color, tolerance: float) -> bool:
	return abs(a.r - b.r) <= tolerance and abs(a.g - b.g) <= tolerance and abs(a.b - b.b) <= tolerance

func _fail(message: String) -> void:
	print("VALIDATION_FAILED: " + message)
	get_tree().quit(1)
