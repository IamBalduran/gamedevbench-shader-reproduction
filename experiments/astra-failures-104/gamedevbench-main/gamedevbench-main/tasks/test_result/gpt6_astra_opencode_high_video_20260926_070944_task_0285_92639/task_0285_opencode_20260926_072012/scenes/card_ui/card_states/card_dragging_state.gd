extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.03

var drag_started_at := 0


func enter() -> void:
	drag_started_at = Time.get_ticks_usec()
	var float_layer := get_tree().get_first_node_in_group("float_layer")
	if float_layer:
		card_ui.reparent(float_layer)
	card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
	card_ui.state_label.text = "Dragging"


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset

	if event.is_action_pressed("right_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, State.BASE)
	elif event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse"):
		var elapsed_seconds := (Time.get_ticks_usec() - drag_started_at) / 1000000.0
		if elapsed_seconds >= DRAG_MINIMUM_THRESHOLD:
			get_viewport().set_input_as_handled()
			transition_requested.emit(self, State.RELEASED)
