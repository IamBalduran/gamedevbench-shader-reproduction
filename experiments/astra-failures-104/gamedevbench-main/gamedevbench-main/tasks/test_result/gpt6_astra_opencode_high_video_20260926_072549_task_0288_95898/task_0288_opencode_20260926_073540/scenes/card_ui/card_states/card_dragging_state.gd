extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.05

var drag_started_at := 0


func enter() -> void:
	drag_started_at = Time.get_ticks_msec()
	var drag_layer := get_tree().get_first_node_in_group("hud_drag_layer")
	if drag_layer:
		card_ui.reparent(drag_layer)
	card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
	card_ui.state_label.text = "Dragging"


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
	elif event.is_action_pressed("right_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, State.BASE)
	elif event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse"):
		get_viewport().set_input_as_handled()
		if (Time.get_ticks_msec() - drag_started_at) / 1000.0 >= DRAG_MINIMUM_THRESHOLD:
			transition_requested.emit(self, State.RELEASED)
