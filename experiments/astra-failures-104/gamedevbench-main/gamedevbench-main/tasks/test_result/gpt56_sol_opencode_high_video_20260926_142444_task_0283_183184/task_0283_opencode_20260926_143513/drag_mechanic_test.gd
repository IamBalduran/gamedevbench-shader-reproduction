extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var rack = main.get_node("OverlayUI/Rack")
	assert(rack.get_child_count() == 3)
	var card = rack.get_child(1)
	assert(card.card_state_machine.current_state.state == 0)

	var card_center = card.global_position + card.size / 2.0
	card._on_gui_input(_mouse_button(card_center, MOUSE_BUTTON_LEFT, true))
	await process_frame
	assert(card.card_state_machine.current_state.state == 1)

	card._input(_mouse_motion(card_center + Vector2(10, -10)))
	await process_frame
	assert(card.card_state_machine.current_state.state == 2)
	assert(card.get_parent() == main.get_node("OverlayUI"))

	card._input(_mouse_button(card_center + Vector2(10, -10), MOUSE_BUTTON_RIGHT, true))
	await process_frame
	assert(card.card_state_machine.current_state.state == 0)
	assert(card.get_parent() == rack)
	assert(card.get_index() == 1)

	card_center = card.global_position + card.size / 2.0
	card._on_gui_input(_mouse_button(card_center, MOUSE_BUTTON_LEFT, true))
	card._input(_mouse_motion(Vector2(124, 54)))
	await create_timer(0.1).timeout
	card._on_drop_point_detector_area_entered(main.get_node("ResolveArea"))
	assert(not card.targets.is_empty())
	card._input(_mouse_button(Vector2(124, 54), MOUSE_BUTTON_LEFT, false))
	await process_frame
	assert(not is_instance_valid(card))
	assert(rack.get_child_count() == 2)

	print("drag mechanic integration test passed")
	quit()


func _mouse_button(position: Vector2, button: MouseButton, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = button
	event.pressed = pressed
	return event


func _mouse_motion(position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	return event
