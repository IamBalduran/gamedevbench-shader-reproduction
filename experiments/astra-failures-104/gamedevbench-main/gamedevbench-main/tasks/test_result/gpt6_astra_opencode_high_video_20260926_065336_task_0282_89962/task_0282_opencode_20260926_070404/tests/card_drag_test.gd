extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")
const CardState := preload("res://scenes/card_ui/card_states/card_state.gd")

var failures := 0
var mouse_position := Vector2.ZERO


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)


func motion(position: Vector2, held := false) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = position - mouse_position
	event.position = position
	event.global_position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	mouse_position = position
	if DisplayServer.get_name() != "headless":
		root.warp_mouse(position)
	event.position = root.get_final_transform() * position
	event.global_position = event.position
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func button(which: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = which
	event.pressed = pressed
	event.position = root.get_final_transform() * mouse_position
	event.global_position = event.position
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame


func capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.save_png("res://tests/" + filename) == OK, "Saved visual capture: " + filename)


func run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	current_scene = main
	await settle()
	var grip: HBoxContainer = main.get_node("ScreenUI/Grip")
	var drag_layer := get_first_node_in_group("drag_layer")
	var zone: Area2D = main.get_node("CastZone")
	var cards := grip.get_children()
	check(cards.size() == 3, "Alternate harness creates three cards in Grip")
	for card in cards:
		var machine = card.card_state_machine
		check(machine.current_state == machine.initial_state, "Initial state entered: " + card.card_title)
		check(not card.drop_point_detector.monitoring, "Detector starts disabled: " + card.card_title)
		for state in machine.get_children():
			check(state.card_ui == card and state.transition_requested.is_connected(machine._on_transition_requested), "State initialized and connected: " + card.card_title + "/" + state.name)
	await capture("card_drag_initial.png")

	var card = cards[1]
	var machine = card.card_state_machine
	machine.get_node("CardDraggingState").transition_requested.emit(machine.get_node("CardDraggingState"), CardState.State.RELEASED)
	check(machine.current_state.state == CardState.State.BASE, "Inactive state cannot request a transition")
	machine.current_state.transition_requested.emit(machine.current_state, 99)
	check(machine.current_state.state == CardState.State.BASE, "Unknown destination leaves the active state intact")

	card._on_drop_point_detector_area_entered(zone)
	card._on_drop_point_detector_area_entered(zone)
	check(card.targets.size() == 1, "Target callbacks do not introduce duplicates")
	card._on_drop_point_detector_area_exited(zone)
	card._on_drop_point_detector_area_exited(zone)
	check(card.targets.is_empty(), "Repeated target exits are safe")

	motion(card.get_global_rect().get_center())
	button(MOUSE_BUTTON_LEFT, true)
	check(machine.current_state.state == CardState.State.CLICKED, "GUI left click enters Clicked")
	check(card.original_index == 1 and card.drop_point_detector.monitoring, "Click records the middle index and enables detection")
	var click_offset: Vector2 = card.pivot_offset
	motion(Vector2(128, 70), true)
	check(machine.current_state.state == CardState.State.DRAGGING and card.get_parent() == drag_layer, "Mouse motion enters Dragging under the drag_layer group")
	check(card.global_position.is_equal_approx(mouse_position - click_offset), "Card follows the mouse while preserving the grab offset")
	button(MOUSE_BUTTON_LEFT, false)
	check(machine.current_state.state == CardState.State.DRAGGING, "Release before 0.06 seconds is ignored")
	await settle()
	check(card.targets.has(zone), "Physics detector recognizes CastZone during dragging")
	await capture("card_drag_active.png")
	button(MOUSE_BUTTON_RIGHT, true)
	check(machine.current_state.state == CardState.State.BASE and card.get_parent() == grip, "Right click cancels dragging back into Grip")
	check(grip.get_children() == cards and card.get_index() == 1, "Cancellation restores the original card order")
	check(not card.drop_point_detector.monitoring and card.targets.is_empty(), "Cancellation resets detector and targets")
	button(MOUSE_BUTTON_RIGHT, false)
	await settle()
	await capture("card_drag_cancelled.png")

	# A click without motion must also leave the card usable.
	motion(card.get_global_rect().get_center())
	button(MOUSE_BUTTON_LEFT, true)
	button(MOUSE_BUTTON_LEFT, false)
	check(machine.current_state.state == CardState.State.BASE, "Click without motion returns to Base")

	# Re-entering Dragging must reset the time gate for every drag.
	motion(card.get_global_rect().get_center())
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(128, 110), true)
	button(MOUSE_BUTTON_LEFT, false)
	check(machine.current_state.state == CardState.State.DRAGGING, "Each drag gets a fresh minimum threshold")
	await create_timer(0.08).timeout
	check(card.targets.is_empty(), "Dragging outside CastZone leaves targets empty")
	button(MOUSE_BUTTON_LEFT, true)
	check(machine.current_state.state == CardState.State.RELEASED and not card.is_queued_for_deletion(), "Late confirmation outside target enters Released without removing card")
	button(MOUSE_BUTTON_LEFT, false)
	check(machine.current_state.state == CardState.State.BASE and grip.get_children() == cards, "Invalid release restores original order on the next input")
	await settle()

	# Cancellation restores first and last indices as well as the middle.
	for index in [0, 2]:
		var edge_card = cards[index]
		motion(edge_card.get_global_rect().get_center())
		button(MOUSE_BUTTON_LEFT, true)
		motion(Vector2(128, 70), true)
		button(MOUSE_BUTTON_RIGHT, true)
		check(grip.get_children() == cards and edge_card.get_index() == index, "Cancellation restores index " + str(index))
		button(MOUSE_BUTTON_RIGHT, false)
		button(MOUSE_BUTTON_LEFT, false)
		await settle()

	# Area exit must remove an overlap before release.
	motion(card.get_global_rect().get_center())
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(128, 70), true)
	await settle()
	check(card.targets.has(zone), "Re-entering CastZone repopulates targets")
	motion(Vector2(128, 110), true)
	await settle()
	check(card.targets.is_empty(), "Physics area exit removes the target")
	motion(Vector2(128, 70), true)
	await create_timer(0.08).timeout
	button(MOUSE_BUTTON_LEFT, false)
	check(card.is_queued_for_deletion(), "Valid release removes the card immediately")
	await settle()
	check(not is_instance_valid(card) and grip.get_child_count() == 2, "Played card is freed and two cards remain")
	await capture("card_drag_played.png")
	print("Card drag regression failures: ", failures)
	quit(1 if failures else 0)
