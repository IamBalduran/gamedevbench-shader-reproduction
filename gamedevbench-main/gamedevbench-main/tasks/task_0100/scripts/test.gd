extends Node

func _ready() -> void:
	run_validation()

func run_validation() -> void:
	var main = get_node("Main")
	if not main:
		print("VALIDATION_FAILED: Main scene not found")
		get_tree().quit(1)
		return

	var mesh := main.get_node("MeshInstance3D")
	if not mesh or not (mesh is MeshInstance3D):
		print("VALIDATION_FAILED: MeshInstance3D not found under Main")
		get_tree().quit(1)
		return

	var material = mesh.get_surface_override_material(0)
	if not material or not (material is ShaderMaterial):
		print("VALIDATION_FAILED: MeshInstance3D missing ShaderMaterial override")
		get_tree().quit(1)
		return

	var shader = material.shader
	if not shader:
		print("VALIDATION_FAILED: Shader not assigned to ShaderMaterial")
		get_tree().quit(1)
		return

	if shader.resource_path == "":
		print("VALIDATION_FAILED: Shader resource path is empty")
		get_tree().quit(1)
		return

	var shader_code = shader.code
	var required_markers = ["diag(", "threshold", "aa_scale", "base_line_thickness", "texelFetch"]
	for marker in required_markers:
		if shader_code.find(marker) == -1:
			print("VALIDATION_FAILED: Shader missing HQX marker: %s" % marker)
			get_tree().quit(1)
			return

	if not _float_matches(material.get_shader_parameter("threshold"), 0.1):
		print("VALIDATION_FAILED: threshold must be 0.1")
		get_tree().quit(1)
		return
	if not _float_matches(material.get_shader_parameter("aa_scale"), 17.6):
		print("VALIDATION_FAILED: aa_scale must be 17.6")
		get_tree().quit(1)
		return
	if not _float_matches(material.get_shader_parameter("base_line_thickness"), 0.38197):
		print("VALIDATION_FAILED: base_line_thickness must be 0.38197")
		get_tree().quit(1)
		return

	var subview_texture = material.get_shader_parameter("subview_image")
	if not subview_texture or not (subview_texture is Texture2D):
		print("VALIDATION_FAILED: subview_image must be a Texture2D")
		get_tree().quit(1)
		return
	if not subview_texture.resource_path.ends_with("assets/textures/ProvinceMap.bmp"):
		print("VALIDATION_FAILED: subview_image must use assets/textures/ProvinceMap.bmp")
		get_tree().quit(1)
		return

	print("VALIDATION_PASSED: Task completed successfully")
	get_tree().quit(1)

func _float_matches(value: Variant, expected: float) -> bool:
	if value == null:
		return false
	return abs(float(value) - expected) < 0.0001
