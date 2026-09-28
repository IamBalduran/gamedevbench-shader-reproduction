extends Node

const WATER_SHADER_PATH := "res://scenes/WaterShader.tres"
const EXPECTED_CAMERA_POS := Vector3(0.195, 0.600, -0.042)
const EXPECTED_CAMERA_FOV := 110
const EXPECTED_SPHERE_POSITIONS := {
	"Sphere": Vector3(3.500, 0.200, -1.000),
	"Sphere2": Vector3(4.200, -0.400, 0.800),
	"Sphere3": Vector3(3.800, 0.000, 2.500),
	"Sphere4": Vector3(2.900, -0.600, -2.800),
	"Sphere5": Vector3(4.000, 0.400, -3.500)
}
const EXPECTED_SPHERE_COUNT := 5
const SPHERE_POS_TOLERANCE := 0.15
const WATER_HALF_EXTENT := 5.0

func _ready():
	run_validation()

func fail(msg: String) -> void:
	print("VALIDATION_FAILED: %s" % msg)
	get_tree().quit(1)

func pass_validation(msg: String) -> void:
	print("VALIDATION_PASSED: %s" % msg)
	get_tree().quit(0)

func approx_vec3(a: Vector3, b: Vector3, tolerance: float = 0.1) -> bool:
	return a.distance_to(b) <= tolerance

func is_greenish(color: Color) -> bool:
	# Green channel should be dominant (higher than red and blue)
	# and reasonably saturated
	return color.g > 0.5 and color.g > color.r and color.g > color.b

func is_point_visible(camera: Camera3D, point: Vector3) -> bool:
	var forward := -camera.global_transform.basis.z
	if (point - camera.global_transform.origin).dot(forward) <= 0.0:
		return false
	var screen_pos := camera.unproject_position(point)
	var rect := get_viewport().get_visible_rect()
	return rect.has_point(screen_pos)

func all_spheres_visible(camera: Camera3D, spheres: Array[MeshInstance3D]) -> bool:
	for sphere in spheres:
		if not is_point_visible(camera, sphere.global_transform.origin):
			return false
	return true

func run_validation() -> void:
	var main := get_node_or_null("Main")
	if main == null:
		fail("Main node missing")
		return

	var world_env := main.get_node_or_null("WorldEnvironment")
	if world_env == null or world_env.environment == null or world_env.environment.sky == null:
		fail("WorldEnvironment with procedural sky missing")
		return

	var dir_light := main.get_node_or_null("DirectionalLight3D")
	if dir_light == null or not dir_light.shadow_enabled:
		fail("DirectionalLight3D with shadows must exist")
		return

	var water := main.get_node_or_null("Water")
	if water == null or not (water is MeshInstance3D):
		fail("Water MeshInstance3D not found")
		return

	if water.mesh == null or not (water.mesh is PlaneMesh):
		fail("Water must use a PlaneMesh")
		return

	var plane_mesh: PlaneMesh = water.mesh
	if plane_mesh.size != Vector2(10, 10):
		fail("PlaneMesh must be 10x10 units")
		return

	if plane_mesh.subdivide_width != 20 or plane_mesh.subdivide_depth != 20:
		fail("PlaneMesh subdivisions must be 20x20")
		return

	# Check for material override (either material_override or surface_material_override)
	var override_material = water.material_override
	if override_material == null:
		override_material = water.get_surface_override_material(0)

	if override_material == null or not (override_material is ShaderMaterial):
		fail("Water requires a ShaderMaterial override (via material_override or surface_material_override)")
		return

	var shader: Shader = override_material.shader
	if shader == null or shader.resource_path != WATER_SHADER_PATH:
		fail("Shader must reference %s" % WATER_SHADER_PATH)
		return

	var background := main.get_node_or_null("Background")
	if background == null:
		fail("Background node missing")
		return

	# Count MeshInstance3D children under Background and collect sphere references
	var sphere_count := 0
	var spheres: Array[MeshInstance3D] = []
	var found := {}
	for child in background.get_children():
		if child is MeshInstance3D:
			sphere_count += 1
			var sphere := child as MeshInstance3D

			if not EXPECTED_SPHERE_POSITIONS.has(sphere.name):
				fail("Unexpected sphere '%s' found in Background" % sphere.name)
				return

			# Check that sphere has a mesh
			if sphere.mesh == null:
				fail("Sphere MeshInstance3D '%s' must have a mesh assigned" % sphere.name)
				return

			var expected_pos: Vector3 = EXPECTED_SPHERE_POSITIONS[sphere.name]
			if not approx_vec3(sphere.global_transform.origin, expected_pos, SPHERE_POS_TOLERANCE):
				fail("Sphere '%s' should be positioned at %s (found: %s)" % [sphere.name, expected_pos, sphere.global_transform.origin])
				return

			# Check that sphere is positioned within the water plane bounds
			if abs(expected_pos.x) > WATER_HALF_EXTENT or abs(expected_pos.z) > WATER_HALF_EXTENT:
				fail("Sphere '%s' should be within the 10x10 water plane (x/z within +/-%.1f)" % [sphere.name, WATER_HALF_EXTENT])
				return

			# Check that sphere is positioned in a reasonable range (near water surface)
			var pos := sphere.global_transform.origin
			if pos.y > 2.0 or pos.y < -2.0:
				fail("Sphere '%s' should be positioned near the water surface (y between -2 and 2)" % sphere.name)
				return

			found[sphere.name] = true
			# Store sphere reference for later visibility check
			spheres.append(sphere)

			# Check that sphere has a material override (either material_override or surface_material_override)
			var mat_override = sphere.material_override
			if mat_override == null:
				mat_override = sphere.get_surface_override_material(0)

			if mat_override == null or not (mat_override is StandardMaterial3D):
				fail("Sphere '%s' must have a StandardMaterial3D material override (via material_override or surface_material_override)")
				return

			# Check that the material is greenish
			var mat := mat_override as StandardMaterial3D
			if not is_greenish(mat.albedo_color):
				fail("Sphere '%s' material should be green (found: %s)" % [sphere.name, mat.albedo_color])
				return

	if sphere_count != EXPECTED_SPHERE_COUNT:
		fail("Background should contain exactly %d sphere MeshInstance3Ds (found: %d)" % [EXPECTED_SPHERE_COUNT, sphere_count])
		return

	for name in EXPECTED_SPHERE_POSITIONS.keys():
		if not found.has(name):
			fail("Missing expected sphere '%s' in Background" % name)
			return

	var camera := main.get_node_or_null("Camera3D")
	if camera == null or not (camera is Camera3D):
		fail("Camera3D missing")
		return

	camera.current = true

	# Check camera position
	if not approx_vec3(camera.transform.origin, EXPECTED_CAMERA_POS, 0.2):
		fail("Camera3D should be positioned at %s (found: %s)" % [EXPECTED_CAMERA_POS, camera.transform.origin])
		return

	# Check camera FOV
	if abs(camera.fov - EXPECTED_CAMERA_FOV) > 0.2:
		fail("Camera FOV must be close to %.1f (found: %.1f)" % [EXPECTED_CAMERA_FOV, camera.fov])
		return

	# Check that all spheres are visible within the camera view
	if not all_spheres_visible(camera, spheres):
		fail("Camera should be angled such that all spheres are visible")
		return

	pass_validation("Depth scene geometry matches tutorial setup")
