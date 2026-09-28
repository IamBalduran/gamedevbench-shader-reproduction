extends SceneTree

const State := preload("res://scenes/card_ui/card_states/card_state.gd").State

var failures := 0
var mouse_position := Vector2.ZERO
var mouse_buttons := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = root.get_final_transform() * position
	event.global_position = event.position
	event.relative = position - mouse_position
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
	event.pressed = pressed
	event.button_mask = mouse_buttons
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame


func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(path) == OK, "Screenshot failed: " + path)


func _run() -> void:
	Input.use_accumulated_input = false
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _settle()
	var tray = main.get_node("ActionUI/Tray")
	var front_layer = main.get_node("ActionUI")
	var use_zone = main.get_node("UseZone")
	var cards: Array = tray.get_children()
	_check(cards.size() == 3, "Harness must start with three cards")
	for card in cards:
		_check(card.card_state_machine.current_state.state == State.BASE, "Initial state must be Base")
		_check(not card.drop_point_detector.monitoring, "Base must disable monitoring")
		for state in card.card_state_machine.get_children():
			_check(state.card_ui == card, "Every state must receive its card")
			_check(state.transition_requested.is_connected(card.card_state_machine._on_transition_requested), "Every state must connect transitions")
	await _capture("res://verification_initial.png")

	# Use actual viewport input to check each original sibling index.
	for card in cards:
		var original_index: int = card.get_index()
		_motion(card.global_position + Vector2(5, 5))
		_button(MOUSE_BUTTON_LEFT, true)
		_check(card.card_state_machine.current_state.state == State.CLICKED, "Left GUI click must enter Clicked")
		_check(card.original_index == original_index, "Clicked must record original index")
		_check(card.drop_point_detector.monitoring, "Clicked must enable monitoring")
		var grab_offset: Vector2 = card.pivot_offset
		_motion(Vector2(100, 60))
		_check(card.card_state_machine.current_state.state == State.DRAGGING, "Motion must enter Dragging")
		_check(card.get_parent() == front_layer, "Dragging must use front_layer group")
		_check(card.global_position.is_equal_approx(mouse_position - grab_offset), "Card must follow mouse with grab offset")
		card.card_state_machine.get_node("CardBaseState").transition_requested.emit(card.card_state_machine.get_node("CardBaseState"), State.RELEASED)
		_check(card.card_state_machine.current_state.state == State.DRAGGING, "Inactive state transition must be ignored")
		card.card_state_machine.current_state.transition_requested.emit(card.card_state_machine.current_state, 999)
		_check(card.card_state_machine.current_state.state == State.DRAGGING, "Unknown transition must be ignored")
		_button(MOUSE_BUTTON_LEFT, false)
		_check(card.card_state_machine.current_state.state == State.DRAGGING, "Release before 70ms must be ignored")
		await _settle()
		_check(card.targets.has(use_zone), "Real area overlap must populate targets")
		card._on_drop_point_detector_area_entered(use_zone)
		card._on_drop_point_detector_area_entered(use_zone)
		_check(card.targets.size() == 1, "Targets must not contain duplicates")
		if original_index == 1:
			await _capture("res://verification_dragging.png")
		_button(MOUSE_BUTTON_RIGHT, true)
		_check(card.card_state_machine.current_state.state == State.BASE, "Right click must cancel")
		_check(card.get_parent() == tray and card.get_index() == original_index, "Cancel must restore recorded tray index")
		_check(not card.drop_point_detector.monitoring and card.targets.is_empty(), "Cancel must reset drop detector and targets")
		_button(MOUSE_BUTTON_RIGHT, false)
		await _settle()
		_check(tray.get_children() == cards, "Cancelled drag must preserve full hand order")
	await _capture("res://verification_cancelled.png")

	# Clicking without motion should leave the card usable.
	var card = cards[1]
	_motion(card.global_position + Vector2(5, 5))
	_button(MOUSE_BUTTON_LEFT, true)
	_button(MOUSE_BUTTON_LEFT, false)
	_check(card.card_state_machine.current_state.state == State.BASE, "Stationary click release must reset")

	# Real physics enter/exit, followed by an invalid release and next-input reset.
	_button(MOUSE_BUTTON_LEFT, true)
	_motion(Vector2(100, 60))
	await _settle()
	_check(card.targets.has(use_zone), "Second drag must detect target again")
	_motion(Vector2(100, 135))
	await _settle()
	_check(card.targets.is_empty(), "Leaving the use zone must remove the target")
	await create_timer(0.09).timeout
	_button(MOUSE_BUTTON_LEFT, false)
	_check(card.card_state_machine.current_state.state == State.RELEASED, "Invalid drop must enter Released after threshold")
	_check(not card.is_queued_for_deletion(), "Invalid drop must keep card")
	_motion(Vector2(101, 135))
	_check(card.card_state_machine.current_state.state == State.BASE, "Invalid drop must reset on next input")
	await _settle()
	_check(tray.get_children() == cards, "Invalid drop must restore original hand order")

	# A valid release must queue deletion immediately and remove only that card.
	_motion(card.global_position + Vector2(5, 5))
	_button(MOUSE_BUTTON_LEFT, true)
	_motion(Vector2(100, 60))
	_button(MOUSE_BUTTON_LEFT, false)
	_check(card.card_state_machine.current_state.state == State.DRAGGING, "Minimum threshold must restart on every drag")
	await _settle()
	await create_timer(0.09).timeout
	_button(MOUSE_BUTTON_LEFT, true)
	_check(card.is_queued_for_deletion(), "Valid drop must immediately queue card removal")
	_button(MOUSE_BUTTON_LEFT, false)
	await _settle()
	_check(not is_instance_valid(card), "Played card must be freed")
	_check(tray.get_child_count() == 2, "Successful play must leave two cards in tray")
	_check(tray.get_children() == [cards[0], cards[2]], "Successful play must preserve remaining order")
	await _capture("res://verification_played.png")
	print("Card drag integration checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
