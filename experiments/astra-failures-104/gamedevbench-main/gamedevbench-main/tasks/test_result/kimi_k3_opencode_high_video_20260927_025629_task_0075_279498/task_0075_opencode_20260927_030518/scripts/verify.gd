extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load("res://scenes/main.tscn")
	if scene == null:
		print("FAIL: could not load scene")
		quit(1)
		return
	var root = scene.instantiate()
	var we = root.get_node("WorldEnvironment")
	print("WorldEnvironment ok: ", we != null)
	print("  bg mode: ", we.environment.background_mode == Environment.BG_SKY)
	print("  sky: ", we.environment.sky != null, " proc: ", we.environment.sky.sky_material is ProceduralSkyMaterial)
	print("  glow: ", we.environment.glow_enabled)
	var light = root.get_node("DirectionalLight3D")
	print("Light shadows: ", light.shadow_enabled)
	var water = root.get_node("Water")
	print("Water mesh: ", water.mesh is PlaneMesh, " size=", water.mesh.size, " subd_w=", water.mesh.subdivide_width, " subd_d=", water.mesh.subdivide_depth)
	var mat = water.get_surface_override_material(0)
	if mat == null:
		mat = water.mesh.surface_get_material(0)
	print("Water material ShaderMaterial: ", mat is ShaderMaterial, " shader path: ", mat.shader.resource_path)
	var bg = root.get_node("Background")
	print("Background children: ", bg.get_child_count())
	for c in bg.get_children():
		var om = c.get_surface_override_material(0)
		print("  ", c.name, " pos=", c.position, " sphere=", c.mesh is SphereMesh, " green_mat=", om is StandardMaterial3D and om.albedo_color == Color(0,1,0,1))
	var cam = root.get_node("Camera3D")
	print("Camera pos=", cam.position, " fov=", cam.fov)
	# Visibility check of all spheres (add to tree to update camera)
	if not cam.is_current():
		cam.current = true
	get_root().add_child(root)
	await process_frame
	await process_frame
	for c in bg.get_children():
		print("  ", c.name, " behind? ", cam.is_position_behind(c.position), " in_frustum=", cam.is_position_in_frustum(c.position))
	quit(0)
