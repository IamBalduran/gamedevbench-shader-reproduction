extends SceneTree

func _init():
	var ok := true
	var scene: PackedScene = load("res://scenes/player.tscn")
	assert(scene != null, "player.tscn failed to load")

	var unit := scene.instantiate()
	root.add_child(unit)
	print("root type:", unit.get_class(), " script:", unit.get_script() != null)
	print("groups:", unit.get_groups())
	print("root layer/mask:", unit.collision_layer, "/", unit.collision_mask)

	var spr := unit.get_node("Sprite2D")
	print("sprite region_enabled:", spr.region_enabled, " rect:", spr.region_rect)
	print("sprite texture:", spr.texture.resource_path)
	var mat: ShaderMaterial = spr.material
	print("material is ShaderMaterial:", mat is ShaderMaterial, " shader:", mat.shader.resource_path)
	print("aura_width default:", mat.get_shader_parameter("aura_width"))

	var cs: CollisionShape2D = unit.get_node("CollisionShape2D")
	print("body shape radius:", cs.shape.radius)

	var detect: Area2D = unit.get_node("Detect")
	print("detect layer/mask:", detect.collision_layer, "/", detect.collision_mask)
	var dcs: CollisionShape2D = detect.get_node("CollisionShape2D")
	print("detect shape radius:", dcs.shape.radius)

	# ---- runtime script behavior ----
	var unit_a := scene.instantiate()
	var unit_b := scene.instantiate()
	root.add_child(unit_a)
	root.add_child(unit_b)
	unit.set_process(false)

	# _ready has run: materials must be unique per instance
	print("unique material A vs B:", unit_a.get_node("Sprite2D").material != unit_b.get_node("Sprite2D").material)
	if unit_a.get_node("Sprite2D").material == unit_b.get_node("Sprite2D").material:
		ok = false

	# set_selected toggles aura_width
	unit_a.set_selected(true)
	print("A aura_width after select:", unit_a.get_node("Sprite2D").material.get_shader_parameter("aura_width"))
	print("B aura_width after select A:", unit_b.get_node("Sprite2D").material.get_shader_parameter("aura_width"))
	if unit_a.get_node("Sprite2D").material.get_shader_parameter("aura_width") != 1.0: ok = false
	if unit_b.get_node("Sprite2D").material.get_shader_parameter("aura_width") != 0.0: ok = false
	unit_a.set_selected(false)
	if unit_a.get_node("Sprite2D").material.get_shader_parameter("aura_width") != 0.0: ok = false

	# exported speed / target_radius / set_target / avoid
	print("speed:", unit_a.speed, " target_radius:", unit_a.target_radius)
	unit_a.set_target(Vector2(100, 100))
	print("target after set_target:", unit_a.target)
	if unit_a.target != Vector2(100, 100): ok = false

	# avoid(): overlapping bodies of Detect
	unit_a.global_position = Vector2(500, 500)
	unit_b.global_position = Vector2(520, 500)  # within 35 px detect radius
	# physics must run at least once for area overlap to register
	await physics_frame
	await physics_frame
	print("detect overlapping bodies:", unit_a.get_node("Detect").get_overlapping_bodies().size())
	var av: Vector2 = unit_a.avoid()
	print("avoid() vector:", av)
	if av == Vector2.ZERO: ok = false

	# movement via move_and_collide in _physics_process
	unit_a.set_target(Vector2(600, 500))
	var before: Vector2 = unit_a.global_position
	await physics_frame
	await physics_frame
	print("moved? before:", before, " after:", unit_a.global_position)
	if unit_a.global_position == before: ok = false

	print("RESULT:", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
