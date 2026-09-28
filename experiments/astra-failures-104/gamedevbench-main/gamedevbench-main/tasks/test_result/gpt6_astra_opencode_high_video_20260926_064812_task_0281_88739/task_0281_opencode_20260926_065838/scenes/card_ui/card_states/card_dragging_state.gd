extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.04

var minimum_drag_timer: SceneTreeTimer


func enter() -> void:
	var overlay := get_tree().get_first_node_in_group("overlay_layer")
	card_ui.reparent(overlay)
	card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
	card_ui.state_label.text = "Dragging"
	minimum_drag_timer = get_tree().create_timer(DRAG_MINIMUM_THRESHOLD, false)


func exit() -> void:
	minimum_drag_timer = null


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
	elif event.is_action_pressed("right_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, State.BASE)
	elif minimum_drag_timer.time_left <= 0.0 and (
		event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")
	):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, State.RELEASED)
