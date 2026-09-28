extends Node3D

const CLIP_AND_FOV_SHADER: Shader = preload("res://shaders/weapon_clip_and_fov_shader.gdshader")

@onready var view_model_container: Node3D = $ViewModel

func _ready() -> void:
	apply_clip_and_fov_shader_to_view_model(view_model_container, 54.0)

func apply_clip_and_fov_shader_to_view_model(node3d: Node3D, fov_or_negative_for_unchanged := -1.0) -> void:
	_apply_clip_and_fov_shader_to_node(node3d, fov_or_negative_for_unchanged)


func _apply_clip_and_fov_shader_to_node(node: Node, fov_or_negative_for_unchanged: float) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		for surface_index in mesh_instance.mesh.get_surface_count():
			var base_material := mesh_instance.get_active_material(surface_index)
			var shader_material := ShaderMaterial.new()
			shader_material.shader = CLIP_AND_FOV_SHADER

			if base_material is ShaderMaterial and base_material.shader == CLIP_AND_FOV_SHADER:
				shader_material = base_material.duplicate()
			else:
				if not base_material is BaseMaterial3D:
					base_material = StandardMaterial3D.new()

				shader_material.set_shader_parameter("albedo", base_material.albedo_color)
				shader_material.set_shader_parameter("metallic", base_material.metallic)
				shader_material.set_shader_parameter("roughness", base_material.roughness)
				var metallic_channel := Vector4(1.0, 0.0, 0.0, 0.0)
				match base_material.metallic_texture_channel:
					BaseMaterial3D.TEXTURE_CHANNEL_GREEN:
						metallic_channel = Vector4(0.0, 1.0, 0.0, 0.0)
					BaseMaterial3D.TEXTURE_CHANNEL_BLUE:
						metallic_channel = Vector4(0.0, 0.0, 1.0, 0.0)
					BaseMaterial3D.TEXTURE_CHANNEL_ALPHA:
						metallic_channel = Vector4(0.0, 0.0, 0.0, 1.0)
					BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE:
						metallic_channel = Vector4(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0, 0.0)
				shader_material.set_shader_parameter("metallic_texture_channel", metallic_channel)

				if base_material.albedo_texture != null:
					shader_material.set_shader_parameter("texture_albedo", base_material.albedo_texture)
				if base_material.metallic_texture != null:
					shader_material.set_shader_parameter("texture_metallic", base_material.metallic_texture)
				if base_material.roughness_texture != null:
					shader_material.set_shader_parameter("texture_roughness", base_material.roughness_texture)

			if fov_or_negative_for_unchanged >= 0.0:
				shader_material.set_shader_parameter("viewmodel_fov", fov_or_negative_for_unchanged)

			mesh_instance.set_surface_override_material(surface_index, shader_material)
		# A geometry-wide override would hide the new per-surface materials.
		mesh_instance.material_override = null

	for child in node.get_children():
		_apply_clip_and_fov_shader_to_node(child, fov_or_negative_for_unchanged)
