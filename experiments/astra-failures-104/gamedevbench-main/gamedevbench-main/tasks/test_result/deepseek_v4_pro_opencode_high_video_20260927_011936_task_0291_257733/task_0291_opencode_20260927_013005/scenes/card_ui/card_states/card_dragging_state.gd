extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.055

var _drag_start_time: int


func enter() -> void:
	var drag_overlay = card_ui.get_tree().get_first_node_in_group("drag_overlay")
	if drag_overlay:
		card_ui.reparent(drag_overlay)
	_drag_start_time = Time.get_ticks_msec()


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		card_ui.global_position = event.global_position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		transition_requested.emit(state, State.BASE)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var elapsed := (Time.get_ticks_msec() - _drag_start_time) / 1000.0
		if elapsed < DRAG_MINIMUM_THRESHOLD:
			transition_requested.emit(state, State.BASE)
		else:
			transition_requested.emit(state, State.RELEASED)