extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.07

var _drag_start_time := 0.0


func enter() -> void:
	_drag_start_time = Time.get_ticks_msec() / 1000.0
	var front_layer = card_ui.get_tree().get_first_node_in_group("front_layer")
	card_ui.reparent(front_layer)
	card_ui.drop_point_detector.monitoring = true


func on_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.size / 2

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			transition_requested.emit(self, CardState.State.BASE)
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var elapsed := Time.get_ticks_msec() / 1000.0 - _drag_start_time
			if elapsed > DRAG_MINIMUM_THRESHOLD:
				transition_requested.emit(self, CardState.State.RELEASED)