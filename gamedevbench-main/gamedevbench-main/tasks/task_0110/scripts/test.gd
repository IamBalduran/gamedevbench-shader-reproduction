extends Node

func _ready():
	run_validation()

func run_validation():
	var main_node: Node3D = null
	for child in get_children():
		if child is Node3D:
			main_node = child
			break
	if main_node == null:
		print("VALIDATION_FAILED: Node3D scene root not found")
		get_tree().quit(1)
		return

	var sphere: MeshInstance3D = null
	for child in main_node.get_children():
		if child is MeshInstance3D:
			sphere = child
			break
	if sphere == null:
		print("VALIDATION_FAILED: MeshInstance3D sphere not found")
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

	if shader.resource_path != "res://scripts/triplanar_basic.gdshader":
		print("VALIDATION_FAILED: Shader path must be res://scripts/triplanar_basic.gdshader")
		get_tree().quit(1)
		return

	var texture_x = material.get_shader_parameter("texture_x")
	if texture_x == null:
		print("VALIDATION_FAILED: texture_x parameter not assigned")
		get_tree().quit(1)
		return

	var shader_path = "res://scripts/triplanar_basic.gdshader"
	if not FileAccess.file_exists(shader_path):
		print("VALIDATION_FAILED: Shader file not found")
		get_tree().quit(1)
		return

	var shader_text = FileAccess.get_file_as_string(shader_path)
	var required_snippets = [
		"uniform sampler2D texture_x",
		"vec4 vertex = INV_VIEW_MATRIX * vec4(VERTEX, 1.0)",
		"vec3 normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz)",
		"vec3 adjusted_normal = abs(normal)",
		"vec3 weights = adjusted_normal / (adjusted_normal.x + adjusted_normal.y + adjusted_normal.z)",
		"vec2 uv_x = vertex.zy",
		"vec2 uv_y = vertex.xz",
		"vec2 uv_z = vertex.xy",
		"ALBEDO ="
	]

	for snippet in required_snippets:
		if shader_text.find(snippet) == -1:
			print("VALIDATION_FAILED: Shader missing required snippet: %s" % snippet)
			get_tree().quit(1)
			return

	print("VALIDATION_PASSED: Task completed successfully")
	get_tree().quit(1)
