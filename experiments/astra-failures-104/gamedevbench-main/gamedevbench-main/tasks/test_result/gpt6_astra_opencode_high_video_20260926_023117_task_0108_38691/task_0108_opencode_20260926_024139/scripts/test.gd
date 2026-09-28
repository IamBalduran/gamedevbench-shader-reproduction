extends Node

var _failed := false

func _ready():
	run_validation()

func run_validation():
	_validate_world_scene()
	if _failed:
		return
	_validate_world_script()
	if _failed:
		return
	_validate_tank_scene()
	if _failed:
		return
	_validate_tank_script()
	if _failed:
		return

	print("VALIDATION_PASSED: Task completed successfully")
	get_tree().quit(0)

func _validate_world_scene():
	var world_scene: PackedScene = load("res://scenes/world.tscn")
	if world_scene == null:
		fail("world.tscn not found or empty")
		return
	var world = world_scene.instantiate()
	if world == null:
		fail("world.tscn failed to instantiate")
		return
	var tile_map = world.get_node_or_null("TileMap")
	if tile_map == null or !(tile_map is TileMap):
		fail("World missing TileMap node")
		return
	var tile_set: TileSet = tile_map.tile_set
	if tile_set == null:
		fail("TileMap missing TileSet")
		return
	var found_tile_type := false
	for i in range(tile_set.get_custom_data_layers_count()):
		if tile_set.get_custom_data_layer_name(i) == "tile_type":
			found_tile_type = true
			if tile_set.get_custom_data_layer_type(i) != TYPE_INT:
				fail("tile_type custom data layer must be type int")
				return
	if !found_tile_type:
		fail("TileSet missing tile_type custom data layer")
		return

	var water_color = world.get("water_color")
	var dirt_color = world.get("dirt_color")
	var grass_color = world.get("grass_color")
	if water_color == null or !(water_color is GradientTexture1D):
		fail("World node missing water_color GradientTexture1D")
		return
	if dirt_color == null or !(dirt_color is GradientTexture1D):
		fail("World node missing dirt_color GradientTexture1D")
		return
	if grass_color == null or !(grass_color is GradientTexture1D):
		fail("World node missing grass_color GradientTexture1D")
		return

	world.queue_free()

func _validate_world_script():
	var world_script_text = FileAccess.get_file_as_string("res://scripts/world.gd")
	if world_script_text.is_empty():
		fail("world.gd not found or empty")
		return
	if world_script_text.find("enum TILE_TYPES") == -1:
		fail("World is missing TILE_TYPES enum")
		return
	if world_script_text.find("get_gradient_at") == -1:
		fail("World is missing get_gradient_at")
		return
	if world_script_text.find("tile_type") == -1:
		fail("get_gradient_at must read tile_type custom data")
		return
	if world_script_text.find("water_color") == -1 or world_script_text.find("dirt_color") == -1 or world_script_text.find("grass_color") == -1:
		fail("World must reference water_color, dirt_color, and grass_color")
		return

func _validate_tank_scene():
	var tank_scene: PackedScene = load("res://scenes/tank.tscn")
	if tank_scene == null:
		fail("tank.tscn not found or empty")
		return
	var tank = tank_scene.instantiate()
	if tank == null:
		fail("tank.tscn failed to instantiate")
		return
	var left = tank.get_node_or_null("LeftTrackParticles")
	if left == null or !(left is GPUParticles2D):
		fail("Tank scene missing LeftTrackParticles GPUParticles2D")
		return
	var right = tank.get_node_or_null("RightTrackParticles")
	if right == null or !(right is GPUParticles2D):
		fail("Tank scene missing RightTrackParticles GPUParticles2D")
		return

	_check_particles(left, -16.0, "LeftTrackParticles")
	_check_particles(right, 16.0, "RightTrackParticles")

	tank.queue_free()

func _check_particles(particles: GPUParticles2D, expected_dir_y: float, label: String):
	if particles.amount != 128:
		fail("%s.amount must be 128" % label)
		return
	if particles.z_index != -1:
		fail("%s.z_index must be -1" % label)
		return
	if particles.emitting != false:
		fail("%s.emitting must start disabled" % label)
		return

	var material = particles.process_material
	if material == null or !(material is ParticleProcessMaterial):
		fail("%s.process_material must be ParticleProcessMaterial" % label)
		return
	if material.emission_shape != ParticleProcessMaterial.EMISSION_SHAPE_BOX:
		fail("%s.process_material must use box emission" % label)
		return
	if !_approx(material.emission_box_extents.x, -16.0):
		fail("%s.emission_box_extents.x must be -16" % label)
		return
	if !_approx(material.direction.y, expected_dir_y):
		fail("%s.direction.y must be %s" % [label, str(expected_dir_y)])
		return
	if !_approx(material.spread, 25.0):
		fail("%s.spread must be 25" % label)
		return
	if material.gravity != Vector3.ZERO:
		fail("%s.gravity must be zero" % label)
		return
	if !_approx(material.initial_velocity_max, 4.0):
		fail("%s.initial_velocity_max must be 4" % label)
		return
	if !_approx(material.damping_max, 3.0):
		fail("%s.damping_max must be 3" % label)
		return
	if !_approx(material.scale_min, 0.25):
		fail("%s.scale_min must be 0.25" % label)
		return

func _validate_tank_script():
	var tank_script_text = FileAccess.get_file_as_string("res://scripts/tank.gd")
	if tank_script_text.is_empty():
		fail("tank.gd not found or empty")
		return
	if tank_script_text.find("World.get_gradient_at") == -1:
		fail("Tank is missing World.get_gradient_at call")
		return
	if tank_script_text.find("color_ramp") == -1:
		fail("Tank does not apply particle gradient to color_ramp")
		return
	if !_has_emitting_value(tank_script_text, true) or !_has_emitting_value(tank_script_text, false):
		fail("Tank must enable and disable particles while moving")
		return

func _has_emitting_value(text: String, value: bool) -> bool:
	var pattern = ""
	if value:
		pattern = "emitting\\s*=\\s*true|set_emitting\\s*\\(\\s*true\\s*\\)"
	else:
		pattern = "emitting\\s*=\\s*false|set_emitting\\s*\\(\\s*false\\s*\\)"
	var re = RegEx.new()
	var err = re.compile(pattern)
	if err != OK:
		return false
	return re.search(text) != null

func _approx(a: float, b: float) -> bool:
	return is_equal_approx(a, b)

func fail(reason: String):
	_failed = true
	print("VALIDATION_FAILED: %s" % reason)
	get_tree().quit(1)
