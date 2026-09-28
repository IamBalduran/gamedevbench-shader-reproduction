extends Node3D

@onready var view_model_container: Node3D = $ViewModel

func _ready() -> void:
	apply_clip_and_fov_shader_to_view_model(view_model_container, 54.0)

func apply_clip_and_fov_shader_to_view_model(node3d: Node3D, fov_or_negative_for_unchanged := -1.0) -> void:
	var shader := load("res://shaders/weapon_clip_and_fov_shader.gdshader") as Shader
	if shader == null:
		return

	for mi in _find_mesh_instance_3d_nodes(node3d):
		for surface_idx in mi.mesh.get_surface_count():
			var shader_material := ShaderMaterial.new()
			shader_material.shader = shader

			var original_material := mi.get_surface_override_material(surface_idx)
			if original_material == null:
				original_material = mi.mesh.surface_get_material(surface_idx)

			if original_material is BaseMaterial3D:
				shader_material.set_shader_parameter("albedo", original_material.albedo_color)
				shader_material.set_shader_parameter("metallic", original_material.metallic)
				shader_material.set_shader_parameter("roughness", original_material.roughness)

			if fov_or_negative_for_unchanged >= 0.0:
				shader_material.set_shader_parameter("viewmodel_fov", fov_or_negative_for_unchanged)

			mi.set_surface_override_material(surface_idx, shader_material)

static func _find_mesh_instance_3d_nodes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_mesh_instance_3d_nodes(child))
	return result
