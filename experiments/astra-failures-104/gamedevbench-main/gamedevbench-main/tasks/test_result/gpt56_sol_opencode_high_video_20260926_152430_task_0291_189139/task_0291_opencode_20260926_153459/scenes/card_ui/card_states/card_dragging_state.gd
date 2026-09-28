extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.055

var drag_started_at_usec := 0
var drag_session := 0
var release_pending := false


func enter() -> void:
	drag_session += 1
	release_pending = false
	drag_started_at_usec = Time.get_ticks_usec()

	var drag_overlay := get_tree().get_first_node_in_group("drag_overlay")
	if drag_overlay:
		card_ui.reparent(drag_overlay)


func exit() -> void:
	release_pending = false
	drag_session += 1


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.size / 2.0

	if event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, State.BASE)
	elif event.is_action_released("left_mouse"):
		get_viewport().set_input_as_handled()
		_confirm_release_after_threshold()


func _confirm_release_after_threshold() -> void:
	var elapsed := (Time.get_ticks_usec() - drag_started_at_usec) / 1000000.0
	if elapsed >= DRAG_MINIMUM_THRESHOLD:
		transition_requested.emit(self, State.RELEASED)
		return

	release_pending = true
	var session := drag_session
	await get_tree().create_timer(DRAG_MINIMUM_THRESHOLD - elapsed).timeout
	if release_pending and session == drag_session:
		transition_requested.emit(self, State.RELEASED)
