extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.09

var drag_started_at_msec := 0


func enter() -> void:
	var drag_layer := get_tree().get_first_node_in_group("ui_drag_layer")
	if drag_layer:
		card_ui.reparent(drag_layer)

	drag_started_at_msec = Time.get_ticks_msec()
	card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset

	if event.is_action_pressed("right_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, State.BASE)
	elif event.is_action_released("left_mouse") and _minimum_drag_time_elapsed():
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, State.RELEASED)


func _minimum_drag_time_elapsed() -> bool:
	return Time.get_ticks_msec() - drag_started_at_msec >= DRAG_MINIMUM_THRESHOLD * 1000.0
