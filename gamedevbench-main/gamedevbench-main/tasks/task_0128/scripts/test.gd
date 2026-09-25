extends Node

func _ready():
	run_validation()

func run_validation():
	var main_node = get_node("Main")
	if not main_node:
		print("VALIDATION_FAILED: Main node not found")
		get_tree().quit(1)
		return

	var panel = main_node.get_node("Panel")
	if not panel:
		print("VALIDATION_FAILED: Panel node not found")
		get_tree().quit(1)
		return

	if not panel is TextureRect:
		print("VALIDATION_FAILED: Panel must be a TextureRect")
		get_tree().quit(1)
		return

	if panel.material == null or panel.material.resource_path != "res://materials/julia.material":
		print("VALIDATION_FAILED: Panel material must be materials/julia.material")
		get_tree().quit(1)
		return
	
	var mat_script = (panel.material as ShaderMaterial).shader.code
	if not (mat_script.contains("(-0.794084, 0.136444)")):
		print("VALIDATION_FAILED: Shader script should not be directly edited")
		get_tree().quit(1)
		return
	
	if ((panel.material as ShaderMaterial).get_shader_parameter("seed") != Vector2(0.4, -0.2)):
		print("VALIDATION_FAILED: Material seed should be (0.4, -0.2)")
		get_tree().quit(1)
		return

	if panel.texture == null or panel.texture.resource_path != "res://icon.png":
		print("VALIDATION_FAILED: Panel texture must be icon.png")
		get_tree().quit(1)
		return

	if abs(panel.anchor_right - 1.0) > 0.001 or abs(panel.anchor_bottom - 1.0) > 0.001:
		print("VALIDATION_FAILED: Panel anchors must fill the right/bottom")
		get_tree().quit(1)
		return

	if panel.grow_horizontal != Control.GROW_DIRECTION_BOTH or panel.grow_vertical != Control.GROW_DIRECTION_BOTH:
		print("VALIDATION_FAILED: Panel grow directions must be BOTH")
		get_tree().quit(1)
		return

	print("VALIDATION_PASSED: Fractal panel configured")
	get_tree().quit(1)
