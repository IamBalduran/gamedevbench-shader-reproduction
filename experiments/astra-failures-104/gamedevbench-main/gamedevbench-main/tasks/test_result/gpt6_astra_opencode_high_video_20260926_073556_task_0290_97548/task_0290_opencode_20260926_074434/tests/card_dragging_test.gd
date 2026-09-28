extends SceneTree

const MAIN_SCENE = preload("res://scenes/main.tscn")
const CardState = preload("res://scenes/card_ui/card_states/card_state.gd")

var failures := 0
var checks := 0
var mouse_position := Vector2.ZERO
var mouse_buttons := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var harness = MAIN_SCENE.instantiate()
	root.add_child(harness)
	current_scene = harness
	await _settle()
	var hand = harness.get_node("FieldUI/GripRow")
	var top_layer = harness.get_node("FieldUI")
	var spend_area = harness.get_node("SpendArea")
	var cards = hand.get_children()
	_check(cards.size() == 3, "Three cards start in GripRow")
	for card in cards:
		var machine = card.card_state_machine
		_check(machine.current_state == machine.initial_state, "Initial base state entered")
		_check(not card.drop_point_detector.monitoring, "Base disables detector")
		for state in machine.get_children():
			_check(state.card_ui == card, "Every state receives its card")
			_check(state.transition_requested.is_connected(machine._on_transition_requested), "Every transition signal connected")
	await _snapshot("card_drag_base.png")

	var card = cards[1]
	var machine = card.card_state_machine
	machine.get_node("CardDraggingState").transition_requested.emit(machine.get_node("CardDraggingState"), CardState.State.RELEASED)
	_check(machine.current_state.state == CardState.State.BASE, "Inactive state cannot request a transition")
	machine.current_state.transition_requested.emit(machine.current_state, 999)
	_check(machine.current_state.state == CardState.State.BASE, "Unknown transition is ignored")
	card._on_drop_point_detector_area_entered(spend_area)
	card._on_drop_point_detector_area_entered(spend_area)
	_check(card.targets.size() == 1, "Target callbacks reject duplicates")
	card._on_drop_point_detector_area_exited(spend_area)
	card._on_drop_point_detector_area_exited(spend_area)
	_check(card.targets.is_empty(), "Target exit removes an area safely")

	# Exercise GUI click routing, pickup offset, and a release before 65 ms.
	var pickup = card.global_position + Vector2(8, 12)
	_motion(pickup)
	_button(MOUSE_BUTTON_LEFT, true)
	_check(machine.current_state.state == CardState.State.CLICKED, "GUI left click enters clicked state")
	_check(card.original_index == 1, "Clicked records original hand index")
	_check(card.drop_point_detector.monitoring, "Clicked enables detector")
	_motion(pickup + Vector2(5, -3))
	_check(machine.current_state.state == CardState.State.DRAGGING, "Mouse motion starts dragging")
	_check(card.get_parent() == top_layer, "Drag reparents into top_ui_layer")
	_check(card.global_position.is_equal_approx(mouse_position - Vector2(8, 12)), "Drag follows mouse and preserves pickup offset")
	_button(MOUSE_BUTTON_LEFT, false)
	_check(machine.current_state.state == CardState.State.DRAGGING, "Release before minimum threshold is ignored")
	_button(MOUSE_BUTTON_RIGHT, true)
	_check(machine.current_state.state == CardState.State.BASE, "Right click immediately cancels")
	_check(card.get_parent() == hand and card.get_index() == 1, "Cancel restores recorded GripRow index")
	_check(not card.drop_point_detector.monitoring and card.targets.is_empty(), "Cancel clears detector and targets")
	_button(MOUSE_BUTTON_RIGHT, false)
	await _settle()
	_check(hand.get_children() == cards, "Cancellation preserves all three cards in order")

	# Release over empty space waits in RELEASED until the following input.
	_start_drag(card)
	_motion(Vector2(240, 135))
	await create_timer(0.09).timeout
	_check(card.targets.is_empty(), "Empty-space drag has no drop targets")
	await _snapshot("card_drag_dragging.png")
	_button(MOUSE_BUTTON_LEFT, false)
	_check(machine.current_state.state == CardState.State.RELEASED, "Release after threshold enters released state")
	_check(not card.is_queued_for_deletion(), "Empty-space release keeps the card")
	_motion(mouse_position + Vector2(-1, 0))
	_check(machine.current_state.state == CardState.State.BASE, "Next input returns invalid release to base")
	await _settle()
	_check(hand.get_children() == cards, "Invalid release restores original hand order")

	# The threshold must reset even immediately after a completed drag.
	_start_drag(card)
	_button(MOUSE_BUTTON_LEFT, false)
	_check(machine.current_state.state == CardState.State.DRAGGING, "Minimum threshold resets for each drag")
	_button(MOUSE_BUTTON_RIGHT, true)
	_button(MOUSE_BUTTON_RIGHT, false)
	await _settle()

	# Confirm the first and last slots restore as well as the middle.
	for edge_card in [cards[0], cards[2]]:
		_start_drag(edge_card)
		_button(MOUSE_BUTTON_RIGHT, true)
		_button(MOUSE_BUTTON_RIGHT, false)
		_button(MOUSE_BUTTON_LEFT, false)
		await _settle()
		_check(hand.get_children() == cards, "Edge-card cancellation restores hand order")

	# A click without mouse motion should not leave a card stuck in CLICKED.
	_motion(card.global_position + Vector2(8, 12))
	_button(MOUSE_BUTTON_LEFT, true)
	_button(MOUSE_BUTTON_LEFT, false)
	_check(machine.current_state.state == CardState.State.BASE, "Click without drag returns to base")

	# Use real physics overlap signals to test leaving and re-entering a target.
	_start_drag(card)
	_motion(Vector2(120, 50))
	await _settle()
	_check(card.targets.size() == 1 and card.targets.has(spend_area), "Physics entry records SpendArea")
	_motion(Vector2(240, 135))
	await _settle()
	_check(card.targets.is_empty(), "Physics exit clears SpendArea")
	_motion(Vector2(120, 50))
	await _settle()
	_check(card.targets.size() == 1, "Physics re-entry records target once")
	await _snapshot("card_drag_target.png")
	await create_timer(0.08).timeout
	_button(MOUSE_BUTTON_LEFT, false)
	_check(card.is_queued_for_deletion(), "Valid release immediately queues card removal")
	await _settle()
	_check(not is_instance_valid(card), "Played card is freed")
	_check(hand.get_child_count() == 2, "Exactly two cards remain after a valid drop")
	_check(hand.get_child(0) == cards[0] and hand.get_child(1) == cards[2], "Remaining cards preserve order")
	await _snapshot("card_drag_played.png")

	print("Card dragging: %d checks, %d failures" % [checks, failures])
	harness.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _start_drag(card) -> void:
	_motion(card.global_position + Vector2(8, 12))
	_button(MOUSE_BUTTON_LEFT, true)
	_motion(mouse_position + Vector2(3, -2))


func _motion(position: Vector2) -> void:
	root.warp_mouse(position)
	var event := InputEventMouseMotion.new()
	event.position = root.get_final_transform() * position
	event.global_position = event.position
	event.relative = root.get_final_transform().basis_xform(position - mouse_position)
	event.button_mask = mouse_buttons
	mouse_position = position
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _button(button: MouseButton, pressed: bool) -> void:
	var mask := 1 << (button - 1)
	if pressed:
		mouse_buttons |= mask
	else:
		mouse_buttons &= ~mask
	var event := InputEventMouseButton.new()
	event.position = root.get_final_transform() * mouse_position
	event.global_position = event.position
	event.button_index = button
	event.button_mask = mouse_buttons
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _settle() -> void:
	for frame in range(4):
		await physics_frame
		await process_frame


func _snapshot(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://tests/" + filename)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
