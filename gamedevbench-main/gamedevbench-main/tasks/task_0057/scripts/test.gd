extends Node

func _ready() -> void:
	validate_main_scene()

func fail(reason: String) -> void:
	print("VALIDATION_FAILED: %s" % reason)
	get_tree().quit(1)

func validate_main_scene() -> void:
	var main = get_node_or_null("Main")
	if main == null:
		fail("Main scene did not instance correctly")
		return
	var units := []
	for child in main.get_children():
		if child.get_scene_file_path() == "res://scenes/unit.tscn":
			units.append(child)
	if units.size() < 2:
		fail("Main needs at least two Unit instances for testing")
		return
	validate_unit_scene()
	print("VALIDATION_PASSED: Unit scene configured with aura highlight and detection area")
	get_tree().quit()

func validate_unit_scene() -> void:
	var unit_scene = load("res://scenes/unit.tscn")
	if not (unit_scene is PackedScene):
		fail("unit.tscn must be a PackedScene")
		return
	var first_instance = unit_scene.instantiate()
	var second_instance = unit_scene.instantiate()
	if not (first_instance is CharacterBody2D):
		fail("Unit root must be a CharacterBody2D")
		return
	if not first_instance.is_in_group("units"):
		fail("Unit needs to be added to the 'units' group")
		return
	if first_instance.collision_layer != 2:
		fail("Unit collision_layer must be 2")
		return
	if first_instance.collision_mask != 3:
		fail("Unit collision_mask must be 3")
		return
	var unit_script = first_instance.get_script()
	if unit_script == null:
		fail("Unit must have an attached script")
		return
	if unit_script.resource_path != "res://scripts/unit.gd":
		fail("Unit script should live at res://scripts/unit.gd")
		return
	validate_sprite(first_instance, second_instance)
	validate_colliders(first_instance)
	validate_detect_area(first_instance)
	validate_script_source(unit_script)
	validate_runtime_behaviour(first_instance)

func validate_sprite(unit_a: Node, unit_b: Node) -> void:
	var sprite: Sprite2D = unit_a.get_node_or_null("Sprite2D")
	if sprite == null:
		fail("Unit requires a Sprite2D child")
		return
	if sprite.texture == null:
		fail("Sprite2D must reference the tower defense texture")
		return
	if not sprite.texture.resource_path.ends_with("assets/sprites/towerDefense_tilesheet.png"):
		fail("Sprite2D should use assets/sprites/towerDefense_tilesheet.png")
		return
	if not sprite.region_enabled:
		fail("Sprite2D region_enabled must be true")
		return
	if sprite.region_rect != Rect2(960, 640, 64, 64):
		fail("Sprite2D region_rect must match the tutorial sprite coordinates")
		return
	if not (sprite.material is ShaderMaterial):
		fail("Sprite2D material must be a ShaderMaterial")
		return
	var shader = sprite.material.shader
	if shader == null or not shader.resource_path.ends_with("assets/shaders/aura.gdshader"):
		fail("Sprite2D should use the aura.gdshader resource")
		return
	unit_a._ready()
	unit_b._ready()
	var mat_a: ShaderMaterial = unit_a.get_node("Sprite2D").material
	var mat_b: ShaderMaterial = unit_b.get_node("Sprite2D").material
	if mat_a == mat_b:
		fail("Each Unit must duplicate its Sprite2D material in _ready()")
		return

func validate_colliders(unit: Node) -> void:
	var body_shape: CollisionShape2D = unit.get_node_or_null("CollisionShape2D")
	if body_shape == null:
		fail("Unit needs a CollisionShape2D child for the body")
		return
	if not (body_shape.shape is CircleShape2D):
		fail("Unit CollisionShape2D must use a CircleShape2D")
		return
	if not is_equal_approx(body_shape.shape.radius, 14.0):
		fail("Body CollisionShape2D radius must be 14")
		return

func validate_detect_area(unit: Node) -> void:
	var detect: Area2D = unit.get_node_or_null("Detect")
	if detect == null:
		fail("Unit must include a Detect Area2D child")
		return
	if detect.collision_layer != 2 or detect.collision_mask != 2:
		fail("Detect Area2D needs collision layer/mask of 2")
		return
	var detect_shape: CollisionShape2D = detect.get_node_or_null("CollisionShape2D")
	if detect_shape == null:
		fail("Detect Area2D requires its own CollisionShape2D child")
		return
	if not (detect_shape.shape is CircleShape2D):
		fail("Detect CollisionShape2D must use a CircleShape2D")
		return
	if not is_equal_approx(detect_shape.shape.radius, 35.0):
		fail("Detect CollisionShape2D radius must be 35")
		return

func validate_script_source(unit_script: Script) -> void:
	var code = unit_script.source_code
	if code.find("@export var speed") == -1:
		fail("unit.gd should export a speed value")
		return
	if code.find("var target_radius") == -1:
		fail("unit.gd must define target_radius")
		return
	if code.find("func set_selected") == -1:
		fail("unit.gd requires a set_selected() setter")
		return
	if code.find("set_shader_parameter(\"aura_width\"") == -1:
		fail("set_selected() must toggle the aura_width shader parameter")
		return
	if code.find("func set_target") == -1:
		fail("unit.gd needs a set_target() setter")
		return
	if code.find("func avoid") == -1 or code.find("$Detect.get_overlapping_bodies") == -1:
		fail("unit.gd must define avoid() using $Detect.get_overlapping_bodies()")
		return
	if code.find("move_and_collide") == -1:
		fail("unit.gd should move the body via move_and_collide")
		return

func validate_runtime_behaviour(unit: CharacterBody2D) -> void:
	var sprite: Sprite2D = unit.get_node("Sprite2D")
	unit._ready()
	unit.selected = true
	if not is_equal_approx(sprite.material.get_shader_parameter("aura_width"), 1.0):
		fail("selected setter must widen the aura when true")
		return
	unit.selected = false
	if not is_equal_approx(sprite.material.get_shader_parameter("aura_width"), 0.0):
		fail("selected setter must clear the aura when false")
		return
	unit.target = Vector2(256, 256)
	if unit.target != Vector2(256, 256):
		fail("set_target must store the provided vector")
		return
