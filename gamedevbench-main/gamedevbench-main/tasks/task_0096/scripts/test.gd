extends Node

func _ready():
	run_validation()

func _fail(message: String) -> void:
	print("VALIDATION_FAILED: ", message)
	get_tree().quit(1)

func run_validation():
	var main = get_node("Main")
	if not main or not main is Node3D:
		_fail("Main scene root must be a Node3D")
		return

	var screen_quad = main.get_node_or_null("ScreenQuad")
	if not screen_quad or not screen_quad is MeshInstance2D:
		_fail("ScreenQuad must be a MeshInstance2D")
		return

	var quad_mesh = screen_quad.mesh
	if not quad_mesh or not quad_mesh is QuadMesh:
		_fail("ScreenQuad must use a QuadMesh")
		return

	if not quad_mesh.size.is_equal_approx(Vector2(1280, 720)):
		_fail("QuadMesh size must be 1280x720")
		return

	if not screen_quad.position.is_equal_approx(Vector2(640, 360)):
		_fail("ScreenQuad position must be (640, 360)")
		return

	var material = screen_quad.material
	if not material or not material is ShaderMaterial:
		_fail("ScreenQuad must use a ShaderMaterial")
		return

	var shader = material.shader
	if not shader or not shader is Shader:
		_fail("ShaderMaterial must reference a Shader")
		return

	var shader_code = shader.code
	if shader_code.find("shader_type canvas_item") == -1:
		_fail("Shader must be a canvas_item shader")
		return

	if shader_code.find("render_mode unshaded") == -1:
		_fail("Shader must use render_mode unshaded")
		return

	if shader_code.find("target_resolution") == -1:
		_fail("Shader must define a target_resolution uniform")
		return

	if shader_code.find("colors_per_channel") == -1:
		_fail("Shader must define a colors_per_channel uniform")
		return

	if shader_code.find("hint_screen_texture") == -1 or shader_code.find("filter_nearest") == -1:
		_fail("Shader must sample screen_texture with hint_screen_texture and filter_nearest")
		return

	if shader_code.find("SCREEN_UV") == -1:
		_fail("Shader must use SCREEN_UV for sampling")
		return

	var target_resolution = material.get_shader_parameter("target_resolution")
	if target_resolution != Vector2(320, 180):
		_fail("target_resolution must be set to Vector2(320, 180)")
		return

	var colors_per_channel = material.get_shader_parameter("colors_per_channel")
	if colors_per_channel != 8.0:
		_fail("colors_per_channel must be set to 8.0")
		return

	print("VALIDATION_PASSED: Screen quad shader setup is correct")
	get_tree().quit(0)
