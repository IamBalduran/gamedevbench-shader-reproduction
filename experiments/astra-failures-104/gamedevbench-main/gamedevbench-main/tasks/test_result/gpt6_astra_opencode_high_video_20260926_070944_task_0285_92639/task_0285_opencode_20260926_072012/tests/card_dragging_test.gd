extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")
const State = preload("res://scenes/card_ui/card_states/card_state.gd").State

var failures := 0
var main: Node
var slots: HBoxContainer


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	main = MAIN_SCENE.instantiate()
	root.add_child(main)
	slots = main.get_node("CombatHUD/Slots")
	await _settle()
	var cards := slots.get_children()
	_check(cards.size() == 3, "the alternate harness starts with three cards")
	for card in cards:
		_check(card.card_state_machine.current_state.state == State.BASE, "cards start in base")
		_check(not card.drop_point_detector.monitoring, "idle detectors are disabled")
		for state in card.card_state_machine.get_children():
			_check(state.card_ui == card, "every state is initialized")
	await _capture("initial")

	var card = cards[1]
	var machine = card.card_state_machine
	var base = machine.get_node("CardBaseState")
	var clicked = machine.get_node("CardClickedState")
	clicked.transition_requested.emit(clicked, State.DRAGGING)
	_check(machine.current_state == base, "inactive states cannot request a transition")
	base.transition_requested.emit(base, 999)
	_check(machine.current_state == base, "unknown transitions are ignored")

	# A click without motion must not leave a card stuck in the clicked state.
	var point: Vector2 = card.global_position + card.size / 2.0
	_motion(point)
	_button(MOUSE_BUTTON_LEFT, true, point)
	_check(machine.current_state.state == State.CLICKED, "GUI left-click enters clicked")
	_check(card.original_index == 1, "clicked records the slot index")
	_check(card.drop_point_detector.monitoring, "clicked enables overlap detection")
	_button(MOUSE_BUTTON_LEFT, false, point)
	_check(machine.current_state.state == State.BASE, "a stationary click returns to base")

	# The first release arrives in the same frame as drag entry, before 30 ms.
	_button(MOUSE_BUTTON_LEFT, true, point)
	_motion(Vector2(130, 44), MOUSE_BUTTON_MASK_LEFT)
	_button(MOUSE_BUTTON_LEFT, false, Vector2(130, 44))
	_check(machine.current_state.state == State.DRAGGING, "an early release is ignored")
	_check(card.get_parent() == main.get_node("CombatHUD"), "drag uses the float_layer group")
	_check(card.global_position.is_equal_approx(Vector2(130, 44) - card.pivot_offset), "drag follows the mouse with its grab offset")
	await _settle()
	var target := main.get_node("CommitArea")
	_check(card.targets.has(target), "physics detects the commit area")
	card._on_drop_point_detector_area_entered(target)
	card._on_drop_point_detector_area_entered(target)
	_check(card.targets.size() == 1, "target entries cannot be duplicated")
	await _capture("dragging")
	_button(MOUSE_BUTTON_RIGHT, true, Vector2(130, 44))
	_button(MOUSE_BUTTON_RIGHT, false, Vector2(130, 44))
	await _settle()
	_check(machine.current_state.state == State.BASE, "right-click cancels the drag")
	_check(slots.get_children() == cards, "cancellation restores the original slot order")
	_check(not card.drop_point_detector.monitoring and card.targets.is_empty(), "cancellation resets detection and targets")
	await _capture("cancelled")

	# Repeated cancellation covers both ends of the Slots container too.
	for index in [0, 2, 1]:
		var other = cards[index]
		point = other.global_position + other.size / 2.0
		_motion(point)
		_button(MOUSE_BUTTON_LEFT, true, point)
		_motion(Vector2(200, 120), MOUSE_BUTTON_MASK_LEFT)
		_button(MOUSE_BUTTON_RIGHT, true, Vector2(200, 120))
		_button(MOUSE_BUTTON_RIGHT, false, Vector2(200, 120))
		_button(MOUSE_BUTTON_LEFT, false, Vector2(200, 120))
		await _settle()
		_check(slots.get_children() == cards, "cancel restores slot %d" % index)

	# Leave a real overlapping target before releasing in an empty region.
	point = card.global_position + card.size / 2.0
	_motion(point)
	_button(MOUSE_BUTTON_LEFT, true, point)
	_motion(Vector2(130, 44), MOUSE_BUTTON_MASK_LEFT)
	await _settle()
	_check(card.targets.has(target), "a repeated drag detects targets")
	_motion(Vector2(210, 122), MOUSE_BUTTON_MASK_LEFT)
	await _settle()
	_check(card.targets.is_empty(), "area exit removes the target")
	await create_timer(0.04).timeout
	_button(MOUSE_BUTTON_LEFT, false, Vector2(210, 122))
	_check(machine.current_state.state == State.RELEASED, "release after the threshold enters released")
	_check(not card.is_queued_for_deletion(), "empty drops keep the card")
	await _capture("empty_release")
	_motion(Vector2(211, 122))
	await _settle()
	_check(machine.current_state.state == State.BASE, "empty release returns on the next input")
	_check(slots.get_children() == cards, "empty release restores slot order")

	# A confirmed drop over CommitArea removes only the dragged card.
	point = card.global_position + card.size / 2.0
	_motion(point)
	_button(MOUSE_BUTTON_LEFT, true, point)
	_motion(Vector2(130, 44), MOUSE_BUTTON_MASK_LEFT)
	await _settle()
	await create_timer(0.04).timeout
	_button(MOUSE_BUTTON_LEFT, false, Vector2(130, 44))
	_check(card.is_queued_for_deletion(), "valid release immediately queues the card for removal")
	await _settle()
	_check(not is_instance_valid(card), "the played card is freed")
	_check(slots.get_children() == [cards[0], cards[2]], "playing preserves the remaining cards and their order")
	await _capture("played")

	if failures == 0:
		print("PASS: card dragging integration checks")
	else:
		push_error("FAIL: %d card dragging integration checks" % failures)
	quit(1 if failures else 0)


func _motion(point: Vector2, buttons: int = 0) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.button_mask = buttons
	root.push_input(event, true)


func _button(button: MouseButton, pressed: bool, point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = point
	event.global_position = point
	root.push_input(event, true)


func _settle() -> void:
	for frame in range(3):
		await physics_frame
		await process_frame


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := "res://.godot/card_drag_%s.png" % label
	_check(root.get_texture().get_image().save_png(path) == OK, "save visual capture: " + label)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
