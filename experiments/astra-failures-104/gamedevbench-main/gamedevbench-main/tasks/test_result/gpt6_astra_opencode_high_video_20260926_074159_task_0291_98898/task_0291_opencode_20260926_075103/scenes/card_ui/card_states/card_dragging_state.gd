extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.055

var drag_started_at: int


func enter() -> void:
	drag_started_at = Time.get_ticks_usec()
	var drag_overlay := get_tree().get_first_node_in_group("drag_overlay")
	if drag_overlay:
		card_ui.reparent(drag_overlay)
	card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
	card_ui.state_label.text = "Dragging"


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset

	if event.is_action_pressed("right_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, State.BASE)
		return

	var minimum_drag_time_elapsed := (Time.get_ticks_usec() - drag_started_at) / 1000000.0 >= DRAG_MINIMUM_THRESHOLD
	var confirm := event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")
	if minimum_drag_time_elapsed and confirm:
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, State.RELEASED)
