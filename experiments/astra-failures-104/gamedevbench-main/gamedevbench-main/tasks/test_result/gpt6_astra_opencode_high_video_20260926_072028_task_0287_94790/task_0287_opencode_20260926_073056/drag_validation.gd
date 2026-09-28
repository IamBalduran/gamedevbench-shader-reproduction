extends SceneTree

const MAIN := preload("res://scenes/main.tscn")
const STATE := preload("res://scenes/card_ui/card_states/card_state.gd")

var failures := 0
var mouse_position := Vector2.ZERO


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _move(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.relative = position - mouse_position
	mouse_position = position
	root.push_input(event, true)


func _button(button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = mouse_position
	event.global_position = mouse_position
	root.push_input(event, true)


func _settle() -> void:
	await process_frame
	await process_frame


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://" + filename)


func _run() -> void:
	var main = MAIN.instantiate()
	root.add_child(main)
	current_scene = main
	await _settle()
	var hand = main.get_node("BoardUI/HandBar")
	var layer = main.get_node("BoardUI")
	var drop_slot = main.get_node("DropSlot")
	var cards: Array = hand.get_children()
	_check(cards.size() == 3, "Harness must start with three cards")
	for card in cards:
		_check(card.card_state_machine.current_state.state == STATE.State.BASE, "Initial state must be entered")
		_check(not card.drop_point_detector.monitoring, "Base state must disable monitoring")
		for state in card.card_state_machine.get_children():
			_check(state.card_ui == card, "Every state must receive its card")
			_check(state.transition_requested.get_connections().size() == 1, "Every state must be connected once")
		card.get_node("CardStateMachine/CardDraggingState").transition_requested.emit(card.get_node("CardStateMachine/CardDraggingState"), STATE.State.RELEASED)
		_check(card.card_state_machine.current_state.state == STATE.State.BASE, "Inactive states must not transition")
	await _capture("drag_check_initial.png")

	# Cancel a drag from every hand position, including immediate cancellation.
	for index in [1, 0, 2]:
		var card = cards[index]
		var click_position: Vector2 = card.global_position + Vector2(8, 6)
		_move(click_position)
		_button(MOUSE_BUTTON_LEFT, true)
		_check(card.card_state_machine.current_state.state == STATE.State.CLICKED, "GUI left-click must enter clicked")
		_check(card.original_index == index, "Clicked state must record hand order")
		_check(card.drop_point_detector.monitoring, "Clicked state must enable monitoring")
		_move(Vector2(120, 65))
		_check(card.card_state_machine.current_state.state == STATE.State.DRAGGING, "Mouse motion must start dragging")
		_check(card.get_parent() == layer, "Dragged card must move to the grouped layer")
		_check(card.global_position.is_equal_approx(Vector2(112, 59)), "Drag must follow mouse preserving click offset")
		_button(MOUSE_BUTTON_LEFT, false)
		_check(card.card_state_machine.current_state.state == STATE.State.DRAGGING, "Release before 0.09 seconds must be ignored")
		if index == 1:
			await physics_frame
			await physics_frame
			await _settle()
			_check(card.targets.has(drop_slot), "Physics overlap must populate targets")
			card._on_drop_point_detector_area_entered(drop_slot)
			_check(card.targets.size() == 1, "Repeated area entry must not duplicate targets")
			await _capture("drag_check_dragging.png")
		_button(MOUSE_BUTTON_RIGHT, true)
		_button(MOUSE_BUTTON_RIGHT, false)
		await _settle()
		_check(card.card_state_machine.current_state.state == STATE.State.BASE, "Right-click must cancel")
		_check(hand.get_children() == cards, "Cancelled drag must restore exact hand order")
		_check(not card.drop_point_detector.monitoring and card.targets.is_empty(), "Cancellation must reset drop detection")
	await _capture("drag_check_cancelled.png")

	# Empty releases wait for the next input before returning to the hand.
	var card = cards[1]
	_move(card.global_position + Vector2(8, 6))
	_button(MOUSE_BUTTON_LEFT, true)
	_move(Vector2(25, 122))
	await create_timer(0.12).timeout
	_check(card.targets.is_empty(), "A card below the drop area must have no targets")
	_button(MOUSE_BUTTON_LEFT, false)
	_check(card.card_state_machine.current_state.state == STATE.State.RELEASED, "Release after the threshold must enter released")
	await _settle()
	_check(card.get_parent() == layer, "Empty release must wait for input")
	await _capture("drag_check_empty_release.png")
	_move(Vector2(26, 122))
	await _settle()
	_check(card.card_state_machine.current_state.state == STATE.State.BASE, "Next input after empty release must enter base")
	_check(hand.get_children() == cards, "Empty release must restore original index")

	# Leave and re-enter the target, then confirm with a second click.
	_move(card.global_position + Vector2(8, 6))
	_button(MOUSE_BUTTON_LEFT, true)
	_move(Vector2(120, 65))
	_button(MOUSE_BUTTON_LEFT, false)
	await create_timer(0.12).timeout
	_check(card.targets.has(drop_slot), "Drag into target must detect it")
	_move(Vector2(120, 122))
	await physics_frame
	await physics_frame
	await _settle()
	_check(card.targets.is_empty(), "Leaving an area must remove it from targets")
	_move(Vector2(120, 65))
	await physics_frame
	await physics_frame
	await _settle()
	_check(card.targets.has(drop_slot), "Re-entering a drop area must detect it again")
	_button(MOUSE_BUTTON_LEFT, true)
	_check(card.is_queued_for_deletion(), "Confirmed targeted release must immediately remove the card")
	_button(MOUSE_BUTTON_LEFT, false)
	await _settle()
	_check(not is_instance_valid(card), "Played card must be freed")
	_check(hand.get_child_count() == 2, "Playing one card must leave the other two in the hand")
	await _capture("drag_check_played.png")
	print("Drag interaction checks completed; failures: ", failures)
	quit(1 if failures else 0)
