extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.04

var drag_started_at := 0


func enter() -> void:
	drag_started_at = Time.get_ticks_msec()
	var overlay_layer: Node = card_ui.get_tree().get_first_node_in_group("overlay_layer")
	if overlay_layer:
		card_ui.reparent(overlay_layer)
	_follow_mouse()


func exit() -> void:
	drag_started_at = 0


func on_input(event: InputEvent) -> void:
	if event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, State.BASE)
		return

	if event is InputEventMouseMotion:
		_follow_mouse()

	var drag_duration := (Time.get_ticks_msec() - drag_started_at) / 1000.0
	if event.is_action_released("left_mouse") and drag_duration >= DRAG_MINIMUM_THRESHOLD:
		transition_requested.emit(self, State.RELEASED)


func _follow_mouse() -> void:
	card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.size / 2.0
