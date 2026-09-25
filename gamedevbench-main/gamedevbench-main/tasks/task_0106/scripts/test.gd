extends Node

func _ready() -> void:
	run_validation()

func run_validation() -> void:
	var script_text := FileAccess.get_file_as_string("res://scripts/outline_effect.gd")
	if script_text.is_empty():
		print("VALIDATION_FAILED: outline_effect.gd is missing or empty")
		get_tree().quit(1)
		return

	var required_script_bits = [
		"@tool",
		"extends CompositorEffect",
		"class_name OutlineEffect",
		"RenderingServer.get_rendering_device()",
		"rd.compute_pipeline_create",
		"storage_buffer_create",
		"sampler_create",
		"get_render_scene_buffers",
		"get_internal_size",
		"get_color_layer(0)",
		"get_depth_layer(0)",
		"buffer_update",
		"uniform_set_create",
		"compute_list_dispatch"
	]
	for needle in required_script_bits:
		if script_text.find(needle) == -1:
			print("VALIDATION_FAILED: outline_effect.gd missing '", needle, "'")
			get_tree().quit(1)
			return

	var shader_text := FileAccess.get_file_as_string("res://outline.glsl")
	if shader_text.is_empty():
		print("VALIDATION_FAILED: outline.glsl is missing or empty")
		get_tree().quit(1)
		return

	var required_shader_bits = [
		"#[compute]",
		"layout(local_size_x = 8",
		"binding = 0",
		"readonly buffer Params",
		"mat4 inv_proj_mat",
		"uniform image2D color_image",
		"sampler2D depth_texture",
		"get_linear_depth",
		"gl_GlobalInvocationID",
		"imageStore",
		"sample_size"
	]
	for needle in required_shader_bits:
		if shader_text.find(needle) == -1:
			print("VALIDATION_FAILED: outline.glsl missing '", needle, "'")
			get_tree().quit(1)
			return

	print("VALIDATION_PASSED: Task completed successfully")
	get_tree().quit(1)
