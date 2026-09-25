extends Node

const SHADER_PATH := "res://shaders/weapon_clip_and_fov_shader.gdshader"
const EXPECTED_FOV := 54.0

func _ready():
	await get_tree().process_frame
	run_validation()

func run_validation():
	var root := get_tree().current_scene
	if root == null:
		print("VALIDATION_FAILED: Current scene not found")
		get_tree().quit(1)
		return

	var shader_applier = _find_shader_applier(root)
	if shader_applier == null:
		print("VALIDATION_FAILED: Node with apply_clip_and_fov_shader_to_view_model not found")
		get_tree().quit(1)
		return

	var view_model_root = _find_view_model_root(shader_applier)
	if view_model_root == null:
		print("VALIDATION_FAILED: View model node with MeshInstance3D children not found")
		get_tree().quit(1)
		return

	var mesh_instance = _find_first_mesh_instance(view_model_root)
	if mesh_instance == null:
		print("VALIDATION_FAILED: No MeshInstance3D found under view model node")
		get_tree().quit(1)
		return

	var mesh = mesh_instance.mesh
	if mesh == null:
		print("VALIDATION_FAILED: MeshInstance3D has no mesh")
		get_tree().quit(1)
		return

	var base_mat = mesh.surface_get_material(0)
	if base_mat == null or not (base_mat is BaseMaterial3D):
		print("VALIDATION_FAILED: Base material is missing or not a BaseMaterial3D")
		get_tree().quit(1)
		return

	var expected_albedo: Color = base_mat.albedo_color
	var expected_metallic: float = base_mat.metallic
	var expected_roughness: float = base_mat.roughness

	shader_applier.apply_clip_and_fov_shader_to_view_model(view_model_root, EXPECTED_FOV)

	var surface_material = mesh.surface_get_material(0)
	if not surface_material or not (surface_material is ShaderMaterial):
		print("VALIDATION_FAILED: Surface material is not a ShaderMaterial")
		get_tree().quit(1)
		return

	var shader_mat := surface_material as ShaderMaterial
	if not shader_mat.shader:
		print("VALIDATION_FAILED: ShaderMaterial has no shader")
		get_tree().quit(1)
		return
	if shader_mat.shader.resource_path != SHADER_PATH:
		print("VALIDATION_FAILED: Shader path is incorrect")
		get_tree().quit(1)
		return

	var fov_value = float(shader_mat.get_shader_parameter("viewmodel_fov"))
	if abs(fov_value - EXPECTED_FOV) > 0.01:
		print("VALIDATION_FAILED: viewmodel_fov must be set to 54.0")
		get_tree().quit(1)
		return

	var albedo_value = shader_mat.get_shader_parameter("albedo")
	if not _color_close(albedo_value, expected_albedo, 0.01):
		print("VALIDATION_FAILED: Shader albedo parameter was not copied from base material")
		get_tree().quit(1)
		return

	var metallic_value = float(shader_mat.get_shader_parameter("metallic"))
	if abs(metallic_value - expected_metallic) > 0.01:
		print("VALIDATION_FAILED: Shader metallic parameter was not copied from base material")
		get_tree().quit(1)
		return

	var roughness_value = float(shader_mat.get_shader_parameter("roughness"))
	if abs(roughness_value - expected_roughness) > 0.01:
		print("VALIDATION_FAILED: Shader roughness parameter was not copied from base material")
		get_tree().quit(1)
		return

	print("VALIDATION_PASSED: View model shader applied and configured")
	get_tree().quit(1)

func _find_shader_applier(root: Node) -> Node:
	var nodes = root.find_children("*", "Node", true, false)
	for node in nodes:
		if node.has_method("apply_clip_and_fov_shader_to_view_model"):
			return node
	return null

func _find_view_model_root(root: Node) -> Node3D:
	var nodes = root.find_children("*", "Node3D", true, false)
	for node in nodes:
		var mesh_children = node.find_children("*", "MeshInstance3D", true, false)
		if mesh_children.size() > 0:
			return node as Node3D
	return null

func _find_first_mesh_instance(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root
	var nodes = root.find_children("*", "MeshInstance3D", true, false)
	return nodes[0] if nodes.size() > 0 else null

func _color_close(a: Color, b: Color, eps: float) -> bool:
	return abs(a.r - b.r) <= eps and abs(a.g - b.g) <= eps and abs(a.b - b.b) <= eps and abs(a.a - b.a) <= eps
