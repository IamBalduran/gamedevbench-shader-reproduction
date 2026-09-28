extends Node3D

@onready var view_model_container: Node3D = $ViewModel

func _ready() -> void:
	apply_clip_and_fov_shader_to_view_model(view_model_container, 54.0)

func apply_clip_and_fov_shader_to_view_model(node3d: Node3D, fov_or_negative_for_unchanged := -1.0) -> void:
	var shader := load("res://shaders/weapon_clip_and_fov_shader.gdshader") as Shader
	var mesh_instances: Array[MeshInstance3D] = []
	_collect_mesh_instances(node3d, mesh_instances)

	for mesh_instance in mesh_instances:
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue

		var material_count: int = max(mesh_instance.get_surface_override_material_count(), mesh.get_surface_count())

		for surface_index in material_count:
			var base_material: Material = null
			if surface_index < mesh_instance.get_surface_override_material_count():
				var override_material := mesh_instance.get_surface_override_material(surface_index)
				if override_material != null:
					base_material = override_material
			if base_material == null and surface_index < mesh.get_surface_count():
				base_material = mesh.surface_get_material(surface_index)
			if base_material == null:
				continue

			var shader_material := ShaderMaterial.new()
			shader_material.shader = shader
			_copy_material_parameters(base_material, shader_material)

			if fov_or_negative_for_unchanged >= 0.0:
				shader_material.set_shader_parameter("viewmodel_fov", fov_or_negative_for_unchanged)

			mesh_instance.set_surface_override_material(surface_index, shader_material)
			mesh_instance.set_instance_shader_parameter("viewmodel_fov", fov_or_negative_for_unchanged)

func _collect_mesh_instances(node: Node, results: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		results.append(node)
	for child in node.get_children():
		_collect_mesh_instances(child, results)

func _copy_material_parameters(base_material: Material, shader_material: ShaderMaterial) -> void:
	if base_material is StandardMaterial3D:
		var standard := base_material as StandardMaterial3D
		shader_material.set_shader_parameter("albedo", standard.albedo_color)
		shader_material.set_shader_parameter("metallic", standard.metallic)
		shader_material.set_shader_parameter("roughness", standard.roughness)
		shader_material.set_shader_parameter("specular", 0.5)
		if standard.albedo_texture != null:
			shader_material.set_shader_parameter("texture_albedo", standard.albedo_texture)
			var albedo := standard.albedo_color
			albedo.a = 1.0
			shader_material.set_shader_parameter("albedo", albedo)
		if standard.metallic_texture != null:
			shader_material.set_shader_parameter("texture_metallic", standard.metallic_texture)
			shader_material.set_shader_parameter("metallic_texture_channel", Vector4(float(standard.metallic_texture_channel == 0), float(standard.metallic_texture_channel == 1), float(standard.metallic_texture_channel == 2), float(standard.metallic_texture_channel == 3)))
		if standard.roughness_texture != null:
			shader_material.set_shader_parameter("texture_roughness", standard.roughness_texture)
		if standard.normal_texture != null:
			shader_material.set_shader_parameter("texture_normal", standard.normal_texture)
			shader_material.set_shader_parameter("normal_scale", standard.normal_scale)
		shader_material.set_shader_parameter("uv1_scale", standard.uv1_scale)
		shader_material.set_shader_parameter("uv1_offset", standard.uv1_offset)
		if standard.uv2_scale != null:
			shader_material.set_shader_parameter("uv2_scale", standard.uv2_scale)
		if standard.uv2_offset != null:
			shader_material.set_shader_parameter("uv2_offset", standard.uv2_offset)
	elif base_material is ShaderMaterial:
		var source := base_material as ShaderMaterial
		for param_name in ["albedo", "metallic", "roughness", "specular", "texture_albedo", "texture_metallic", "metallic_texture_channel", "texture_roughness", "texture_normal", "normal_scale", "uv1_scale", "uv1_offset", "uv2_scale", "uv2_offset"]:
			var value: Variant = source.get_shader_parameter(param_name)
			if value != null:
				shader_material.set_shader_parameter(param_name, value)
		if source.shader != null and source.shader == shader_material.shader:
			var fov: Variant = source.get_shader_parameter("viewmodel_fov")
			if fov != null:
				shader_material.set_shader_parameter("viewmodel_fov", fov)
