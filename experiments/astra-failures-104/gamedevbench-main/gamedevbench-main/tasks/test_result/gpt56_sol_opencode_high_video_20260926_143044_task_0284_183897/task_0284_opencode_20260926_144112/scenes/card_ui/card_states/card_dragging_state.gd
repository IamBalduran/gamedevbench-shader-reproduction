extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.05

var drag_started_at_msec := 0


func enter() -> void:
	drag_started_at_msec = Time.get_ticks_msec()
	var ui_layer: Node = card_ui.get_tree().get_first_node_in_group("ui_layer")
	card_ui.reparent(ui_layer)
	_move_card_to_mouse()


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_move_card_to_mouse()

	if event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, State.BASE)
	elif event.is_action_released("left_mouse") and _minimum_drag_time_elapsed():
		transition_requested.emit(self, State.RELEASED)


func _move_card_to_mouse() -> void:
	card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.size / 2.0


func _minimum_drag_time_elapsed() -> bool:
	return Time.get_ticks_msec() - drag_started_at_msec >= DRAG_MINIMUM_THRESHOLD * 1000.0
