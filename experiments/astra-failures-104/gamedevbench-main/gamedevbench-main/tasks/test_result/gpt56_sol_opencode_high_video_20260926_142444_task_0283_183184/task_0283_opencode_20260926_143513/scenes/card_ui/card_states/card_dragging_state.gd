extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.08

var drag_started_at := 0


func enter() -> void:
	drag_started_at = Time.get_ticks_msec()
	var card_layer: Node = card_ui.get_tree().get_first_node_in_group("card_layer")
	card_ui.reparent(card_layer)
	card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
	card_ui.state_label.text = "Dragging"


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset

	if event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, State.BASE)
	elif event.is_action_released("left_mouse") and _minimum_drag_time_elapsed():
		transition_requested.emit(self, State.RELEASED)


func _minimum_drag_time_elapsed() -> bool:
	return Time.get_ticks_msec() - drag_started_at >= DRAG_MINIMUM_THRESHOLD * 1000.0
