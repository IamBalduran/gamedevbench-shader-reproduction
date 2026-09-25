extends Node

func _ready():
	run_validation()

func run_validation():
	var main_node = get_node_or_null("Main")
	if main_node == null:
		print("VALIDATION_FAILED: Main node not found")
		get_tree().quit(1)
		return

	var sphere = main_node.get_node_or_null("Sphere")
	if sphere == null or not sphere is MeshInstance3D:
		print("VALIDATION_FAILED: Sphere MeshInstance3D not found")
		get_tree().quit(1)
		return

	if sphere.mesh == null or not sphere.mesh is SphereMesh:
		print("VALIDATION_FAILED: SphereMesh not assigned")
		get_tree().quit(1)
		return

	var material = sphere.mesh.material
	if material == null or not material is ShaderMaterial:
		print("VALIDATION_FAILED: ShaderMaterial not assigned to SphereMesh")
		get_tree().quit(1)
		return

	var shader = material.shader
	if shader == null:
		print("VALIDATION_FAILED: Shader not assigned on ShaderMaterial")
		get_tree().quit(1)
		return

	if shader.resource_path != "res://scripts/triplanar_axis_blend.gdshader":
		print("VALIDATION_FAILED: Shader path must be res://scripts/triplanar_axis_blend.gdshader")
		get_tree().quit(1)
		return

	var texture_x = material.get_shader_parameter("texture_x")
	var texture_y = material.get_shader_parameter("texture_y")
	var texture_z = material.get_shader_parameter("texture_z")

	if texture_x == null or texture_y == null or texture_z == null:
		print("VALIDATION_FAILED: texture_x, texture_y, and texture_z must be assigned")
		get_tree().quit(1)
		return

	if texture_x.resource_path != "res://assets/sprites/Rock022_2K-PNG_Color.png":
		print("VALIDATION_FAILED: texture_x must use Rock022_2K-PNG_Color.png")
		get_tree().quit(1)
		return

	if texture_y.resource_path != "res://assets/sprites/Grass002_2K-PNG_Color.png":
		print("VALIDATION_FAILED: texture_y must use Grass002_2K-PNG_Color.png")
		get_tree().quit(1)
		return

	if texture_z.resource_path != "res://assets/sprites/Rock022_2K-PNG_Color.png":
		print("VALIDATION_FAILED: texture_z must use Rock022_2K-PNG_Color.png")
		get_tree().quit(1)
		return

	var shader_path = "res://scripts/triplanar_axis_blend.gdshader"
	if not FileAccess.file_exists(shader_path):
		print("VALIDATION_FAILED: Shader file not found")
		get_tree().quit(1)
		return

	var shader_text = FileAccess.get_file_as_string(shader_path)
	var required_snippets = [
		"uniform sampler2D texture_x",
		"uniform sampler2D texture_y",
		"uniform sampler2D texture_z",
		"vec3 adjusted_normal = pow(abs(normal), vec3(8.0))",
		"float use_y_up = float(normal.y > 0.0)",
		"vec3 color_y_up = texture(texture_y, uv_y).rgb * weights.y",
		"vec3 color_y_down = texture(texture_x, uv_y).rgb * weights.y",
		"mix(color_y_down, color_y_up, use_y_up)",
		"ALBEDO = (color_x + mix(color_y_down, color_y_up, use_y_up) + color_z) / 3.0"
	]

	for snippet in required_snippets:
		if shader_text.find(snippet) == -1:
			print("VALIDATION_FAILED: Shader missing required snippet: %s" % snippet)
			get_tree().quit(1)
			return

	print("VALIDATION_PASSED: Task completed successfully")
	get_tree().quit(1)
