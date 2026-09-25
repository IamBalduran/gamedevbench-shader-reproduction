extends SceneTree

func _initialize() -> void:
	call_deferred("_probe")

func _probe() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		print("AUDIT: main scene failed to load")
		quit(2)
		return
	var main := packed.instantiate()
	get_root().add_child(main)
	await process_frame
	var unit_a := main.get_node_or_null("UnitA")
	var unit_b := main.get_node_or_null("UnitB")
	if unit_a != null and unit_b != null:
		var sprite_a := unit_a.get_node_or_null("Sprite2D") as Sprite2D
		var sprite_b := unit_b.get_node_or_null("Sprite2D") as Sprite2D
		print("AUDIT: unit_scene_path=", unit_a.scene_file_path)
		print("AUDIT: separate_materials=", sprite_a != null and sprite_b != null and sprite_a.material != sprite_b.material)
		if sprite_a != null and sprite_a.material is ShaderMaterial:
			unit_a.set("selected", true)
			print("AUDIT: selected_width=", sprite_a.material.get_shader_parameter("aura_width"))
			unit_a.set("selected", false)
			print("AUDIT: deselected_width=", sprite_a.material.get_shader_parameter("aura_width"))
		quit(0)
		return
	var knife := main.get_node_or_null("WeaponManager/ViewModel/Knife") as MeshInstance3D
	if knife != null:
		var active := knife.get_active_material(0)
		var stored := knife.mesh.surface_get_material(0)
		var override_mat := knife.get_surface_override_material(0)
		print("AUDIT: active=", active.get_class() if active != null else "null")
		print("AUDIT: mesh_surface=", stored.get_class() if stored != null else "null")
		print("AUDIT: surface_override=", override_mat.get_class() if override_mat != null else "null")
		if active is ShaderMaterial:
			print("AUDIT: shader_path=", active.shader.resource_path)
			print("AUDIT: fov=", active.get_shader_parameter("viewmodel_fov"))
			if stored is BaseMaterial3D:
				print("AUDIT: albedo_copied=", active.get_shader_parameter("albedo") == stored.albedo_color)
				print("AUDIT: metallic_copied=", is_equal_approx(float(active.get_shader_parameter("metallic")), stored.metallic))
				print("AUDIT: roughness_copied=", is_equal_approx(float(active.get_shader_parameter("roughness")), stored.roughness))
		quit(0)
		return
	var preview := main.get_node_or_null("DistortionPreview") as TextureRect
	if preview != null:
		var mat := preview.material as ShaderMaterial
		print("AUDIT: visual_shader=", mat != null and mat.shader is VisualShader)
		if mat != null and mat.shader != null:
			var code := mat.shader.code
			print("AUDIT: includes_distortion=", code.contains("distortionUV.gdshaderinc"))
			print("AUDIT: constants_five_decimals=", code.contains("7.00000") and code.contains("5.00000") and code.contains("0.10000"))
			print("AUDIT: constants_six_decimals=", code.contains("7.000000") and code.contains("5.000000") and code.contains("0.100000"))
			for line in code.split("\n"):
				if line.contains("n_in2p"):
					print("AUDIT: generated_line=", line.strip_edges())
			if mat.shader is VisualShader:
				var visual := mat.shader as VisualShader
				var custom := visual.get_node(VisualShader.TYPE_FRAGMENT, 2)
				if custom != null:
					for port in range(1, 5):
							print("AUDIT: port_", port, "=", custom.get_input_port_default_value(port))
		quit(0)
		return
	print("AUDIT: target nodes absent")
	quit(3)
