extends SceneTree


func _init() -> void:
	var root := Node3D.new()
	root.name = "Main"

	# --- WorldEnvironment: procedural sky + glow ---
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.glow_enabled = true
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	world_env.environment = env
	root.add_child(world_env)
	world_env.owner = root

	# --- DirectionalLight3D with shadows ---
	var sun := DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	sun.rotation_degrees = Vector3(-40.0, -30.0, 0.0)
	sun.shadow_enabled = true
	root.add_child(sun)
	sun.owner = root

	# --- Water: 10x10 PlaneMesh subdivided 20x20 with WaterShader material ---
	var water := MeshInstance3D.new()
	water.name = "Water"
	var plane := PlaneMesh.new()
	plane.size = Vector2(10.0, 10.0)
	plane.subdivide_width = 20
	plane.subdivide_depth = 20
	water.mesh = plane
	var water_mat := ShaderMaterial.new()
	water_mat.shader = load("res://scenes/WaterShader.tres")
	water.material_override = water_mat
	root.add_child(water)
	water.owner = root

	# --- Background with 5 green spheres ---
	var background := Node3D.new()
	background.name = "Background"
	root.add_child(background)
	background.owner = root

	var sphere_data := [
		["Sphere", Vector3(-3.800, 0.300, 1.200)],
		["Sphere2", Vector3(-4.400, -0.500, -0.600)],
		["Sphere3", Vector3(-3.200, 0.100, -2.400)],
		["Sphere4", Vector3(-2.600, -0.700, 2.800)],
		["Sphere5", Vector3(-4.100, 0.400, 3.500)],
	]
	var green_mat := StandardMaterial3D.new()
	green_mat.albedo_color = Color(0.0, 0.8, 0.0, 1.0)
	for data in sphere_data:
		var sphere := MeshInstance3D.new()
		sphere.name = data[0]
		sphere.mesh = SphereMesh.new()
		sphere.position = data[1]
		sphere.material_override = green_mat
		background.add_child(sphere)
		sphere.owner = root

	# --- Camera3D aimed at the sphere cluster ---
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.position = Vector3(-0.194, 0.600, 0.048)
	cam.fov = 110.0
	root.add_child(cam)
	cam.owner = root
	# Aim at the centroid of the sphere cluster, slightly below waterline.
	cam.look_at_from_position(cam.position, Vector3(-3.62, -0.25, 0.9), Vector3.UP)
	cam.current = true

	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, "res://scenes/main.tscn")
	print("Saved main.tscn, error: ", err)

	# Verify all sphere centers are inside the camera frustum.
	var cam_xform := cam.global_transform
	for data in sphere_data:
		var to_pt: Vector3 = (data[1] - cam.position)
		var fwd := -cam_xform.basis.z
		var right := cam_xform.basis.x
		var upv := cam_xform.basis.y
		var along := to_pt.dot(fwd)
		var half_v := tan(deg_to_rad(cam.fov / 2.0)) * along
		var aspect := 1152.0 / 648.0
		var half_h := half_v * aspect
		var off_v := to_pt.dot(upv)
		var off_h := to_pt.dot(right)
		print(data[0], " along=", along,
			" v_ratio=", absf(off_v / half_v),
			" h_ratio=", absf(off_h / half_h))

	quit()
