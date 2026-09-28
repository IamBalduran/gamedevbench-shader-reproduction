extends Node

var _drop_capture := {}

func _ready() -> void:
	await get_tree().process_frame

	var main := get_node_or_null("Main")
	if main == null or not (main is Node2D):
		return _fail("Main scene must root a Node2D named Main")

	var dragger := main.get_node_or_null("SampleDraggable")
	if dragger == null or not (dragger is Area2D):
		return _fail("Main must instance scenes/draggable.tscn as SampleDraggable")
	if dragger.get_script() == null or not dragger.get_script().resource_path.ends_with("scripts/draggable.gd"):
		return _fail("SampleDraggable must use scripts/draggable.gd")
	if not dragger.has_signal("dropped"):
		return _fail("Draggable scene needs a dropped signal")

	var sprite := dragger.get_node_or_null("Sprite")
	if sprite == null or not (sprite is Sprite2D):
		return _fail("Draggable requires a Sprite2D child named Sprite")
	if sprite.texture == null or not sprite.texture.resource_path.ends_with("assets/sprites/star_1.png"):
		return _fail("Sprite texture must be assets/sprites/star_1.png")
	if not sprite.scale.is_equal_approx(Vector2(0.58, 0.58)):
		return _fail("Sprite scale should match the tutorial's 0.58 uniform scale")

	var shape := dragger.get_node_or_null("CollisionShape")
	if shape == null or not (shape is CollisionShape2D):
		return _fail("Add a CollisionShape2D named CollisionShape")
	if shape.shape == null or not (shape.shape is RectangleShape2D):
		return _fail("CollisionShape must use a RectangleShape2D")
	var rect := shape.shape as RectangleShape2D
	if rect.size.distance_to(Vector2(72, 72)) > 0.5:
		return _fail("RectangleShape2D needs a ~72x72 size")

	if dragger.collision_mask != 2:
		return _fail("Draggable.collision_mask should be 2 so it only sees tree layers")
	if not dragger.has_method("self_destruct") or not dragger.has_method("play_spawn_animation"):
		return _fail("draggable.gd must implement self_destruct and tweens")

	var initial_position: Variant = dragger.get("initial_position")
	if initial_position == null or not (initial_position is Vector2):
		return _fail("Store the starting position in initial_position")

	var drop_target := main.get_node_or_null("DropTarget")
	if drop_target == null or not (drop_target is Area2D):
		return _fail("Main must provide a DropTarget Area2D for overlap testing")

	if dragger.is_connected("dropped", Callable(self, "_capture_drop")):
		dragger.disconnect("dropped", Callable(self, "_capture_drop"))
	dragger.connect("dropped", Callable(self, "_capture_drop"))
	_drop_capture.clear()

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = dragger.global_position
	dragger._on_input_event(null, press, 0)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	dragger.global_position = drop_target.global_position
	await get_tree().physics_frame
	dragger._input(release)
	await get_tree().physics_frame

	if not _drop_capture.has("overlaps"):
		return _fail("dropped signal must emit overlapping areas on release")
	var overlaps: Array = _drop_capture.get("overlaps", [])
	if not (overlaps is Array):
		return _fail("dropped signal should provide the overlaps array payload")

	var scene := load("res://scenes/draggable.tscn") as PackedScene
	var stray := scene.instantiate() as Area2D
	main.add_child(stray)
	await get_tree().physics_frame
	stray.global_position = Vector2.ZERO
	stray._on_input_event(null, press, 0)
	stray._input(release)
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(stray) and not stray.is_queued_for_deletion():
		return _fail("Draggable without overlaps must call self_destruct and queue_free")

	print("VALIDATION_PASSED: Draggable ornament scene configured and signaling correctly")
	get_tree().quit()

func _capture_drop(draggable: Node, overlaps: Array) -> void:
	_drop_capture["draggable"] = draggable
	_drop_capture["overlaps"] = overlaps

func _fail(message: String) -> void:
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit(1)
