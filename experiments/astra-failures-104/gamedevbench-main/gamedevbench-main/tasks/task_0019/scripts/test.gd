extends Node

var validation_done := false
var flash_count := 0
var max_flashes := 10

func _ready():
	run_validation()
	# Start repeatedly spawning muzzle flashes for visual feedback
	if validation_done:
		spawn_muzzle_flash()

func fail(msg: String) -> void:
	print("VALIDATION_FAILED: %s" % msg)
	get_tree().quit(1)

func succeed(msg: String) -> void:
	print("VALIDATION_PASSED: %s" % msg)
	validation_done = true

func spawn_muzzle_flash() -> void:
	var effect_scene = load("res://scenes/effects/muzzle_flash_effect.tscn")
	var effect = effect_scene.instantiate()
	get_node("Main").add_child(effect)
	effect.global_position = Vector3(0, 0, 0)

	flash_count += 1
	if flash_count < max_flashes:
		# Wait 0.8 seconds before spawning next flash
		await get_tree().create_timer(0.8).timeout
		spawn_muzzle_flash()
	else:
		# Wait 1 second before quitting
		await get_tree().create_timer(1.0).timeout
		get_tree().quit()

func run_validation() -> void:
	var effect = get_node_or_null("Main/MuzzleFlashEffect")
	if not effect:
		fail("Main must instance the MuzzleFlashEffect scene")
		return

	var script = effect.get_script()
	if script == null or String(script.resource_path).find("generic_effect_handler.gd") == -1:
		fail("MuzzleFlashEffect must use generic_effect_handler.gd")
		return

	if effect.get("optional_light_path") != NodePath("MuzzleFlash"):
		fail("Optional light export must point to the MuzzleFlash OmniLight")
		return

	if abs(effect.get("light_duration") - 0.2) > 0.01:
		fail("Light duration must be 0.2 seconds")
		return

	var omni = effect.get_node_or_null("MuzzleFlash")
	if not (omni is OmniLight3D):
		fail("MuzzleFlash node must be an OmniLight3D")
		return

	var smoke = effect.get_node_or_null("SmokeParticles")
	if not (smoke is GPUParticles3D):
		fail("SmokeParticles GPUParticles3D is missing")
		return

	if not smoke.process_material:
		fail("SmokeParticles needs a process material for lifetime control")
		return

	if smoke.process_material is ParticleProcessMaterial:
		if smoke.process_material.gravity != Vector3.ZERO:
			fail("SmokeParticles gravity must be (0, 0, 0) to prevent falling")
			return

	if smoke.draw_pass_1 == null:
		fail("SmokeParticles must render with a mesh draw pass")
		return

	var smoke_mesh = smoke.draw_pass_1
	if smoke_mesh.material == null:
		fail("SmokeParticles mesh must have a material assigned")
		return
	
	if not (smoke_mesh.material is StandardMaterial3D):
		fail("SmokeParticles mesh must use a StandardMaterial3D")
		return

	if smoke_mesh.material.billboard_mode != BaseMaterial3D.BILLBOARD_PARTICLES:
		fail("SmokeParticles material must use Billboard Mode (Particles) to look volumetric")
		return
	if not (smoke_mesh.material.albedo_texture is GradientTexture2D):
		fail("SmokeParticles material must use a GradientTexture2D (procedural radial puff)")
		return

	if smoke_mesh.material.albedo_texture.fill != GradientTexture2D.FILL_RADIAL:
		fail("SmokeParticles gradient texture must be Radial to look like a round puff")
		return

	for name in ["MuzzleFireLeft", "MuzzleFireRight"]:
		var fire_node = effect.get_node_or_null(name)
		if not (fire_node is GPUParticles3D):
			fail("%s must be a GPUParticles3D" % name)
			return
		if fire_node.process_material == null:
			fail("%s needs a process material" % name)
			return
		var mat = fire_node.material_override
		if not (mat is ShaderMaterial) or mat.shader == null:
			fail("%s must use the muzzle flash shader material" % name)
			return
		var shader_path = String(mat.shader.resource_path)
		if shader_path.find("muzzle_flash.gdshader") == -1:
			fail("%s must reference assets/shaders/muzzle_flash.gdshader" % name)
			return
		if fire_node.draw_pass_1 == null:
			fail("%s must define a draw pass mesh" % name)
			return

	succeed("Muzzle flash effect configured with light and particles")
