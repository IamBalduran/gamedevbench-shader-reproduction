extends Node3D

const WEAPON_CLIP_AND_FOV_SHADER: Shader = preload("res://shaders/weapon_clip_and_fov_shader.gdshader")

@onready var view_model_container: Node3D = $ViewModel

func _ready() -> void:
	apply_clip_and_fov_shader_to_view_model(view_model_container, 54.0)

func apply_clip_and_fov_shader_to_view_model(node3d: Node3D, fov_or_negative_for_unchanged := -1.0) -> void:
	for descendant in node3d.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := descendant as MeshInstance3D
		if mesh_instance.mesh == null:
			continue

		for surface_index in mesh_instance.mesh.get_surface_count():
			var base_material := mesh_instance.get_active_material(surface_index)
			var shader_material := ShaderMaterial.new()
			shader_material.shader = WEAPON_CLIP_AND_FOV_SHADER

			if base_material is BaseMaterial3D:
				shader_material.set_shader_parameter("albedo", base_material.albedo_color)
				shader_material.set_shader_parameter("texture_albedo", base_material.albedo_texture)
				shader_material.set_shader_parameter("metallic", base_material.metallic)
				shader_material.set_shader_parameter("texture_metallic", base_material.metallic_texture)
				shader_material.set_shader_parameter("roughness", base_material.roughness)
				shader_material.set_shader_parameter("texture_roughness", base_material.roughness_texture)

			if fov_or_negative_for_unchanged >= 0.0:
				shader_material.set_shader_parameter("viewmodel_fov", fov_or_negative_for_unchanged)

			mesh_instance.set_surface_override_material(surface_index, shader_material)
