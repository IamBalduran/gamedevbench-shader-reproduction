extends Node

func _ready():
	run_validation()

func run_validation():
	var main_node := get_node_or_null("Main")
	if main_node == null:
		print("VALIDATION_FAILED: Main node not found")
		get_tree().quit(1)
		return

	var preview := main_node.get_node_or_null("DistortionPreview")
	if preview == null:
		print("VALIDATION_FAILED: DistortionPreview node not found")
		get_tree().quit(1)
		return

	if not (preview is TextureRect):
		print("VALIDATION_FAILED: DistortionPreview must be a TextureRect")
		get_tree().quit(1)
		return

	var texture_rect := preview as TextureRect
	if texture_rect.texture == null or texture_rect.texture.resource_path != "res://addons/shaderV/shaderV_icon.png":
		print("VALIDATION_FAILED: DistortionPreview must use shaderV_icon.png")
		get_tree().quit(1)
		return

	var material = texture_rect.material
	if material == null or not (material is ShaderMaterial):
		print("VALIDATION_FAILED: DistortionPreview must use a ShaderMaterial")
		get_tree().quit(1)
		return

	var shader = material.shader
	if shader == null or not (shader is VisualShader):
		print("VALIDATION_FAILED: ShaderMaterial must use a VisualShader")
		get_tree().quit(1)
		return

	var shader_code = shader.code
	if shader_code.find("distortionUV.gdshaderinc") == -1:
		print("VALIDATION_FAILED: VisualShader must include distortionUV.gdshaderinc")
		get_tree().quit(1)
		return

	if shader_code.find("7.000000") == -1 or shader_code.find("5.000000") == -1 or shader_code.find("0.100000") == -1:
		print("VALIDATION_FAILED: VisualShader constants do not match DistortionUV example")
		get_tree().quit(1)
		return

	print("VALIDATION_PASSED: Distortion UV preview configured")
	get_tree().quit(0)
