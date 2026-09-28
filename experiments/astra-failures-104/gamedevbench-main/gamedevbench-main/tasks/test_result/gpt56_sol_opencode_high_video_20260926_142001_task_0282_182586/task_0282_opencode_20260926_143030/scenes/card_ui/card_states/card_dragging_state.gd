extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.06

var elapsed := 0.0
var mouse_offset := Vector2.ZERO


func enter() -> void:
	elapsed = 0.0
	mouse_offset = card_ui.get_global_mouse_position() - card_ui.global_position
	var drag_layer := get_tree().get_first_node_in_group("drag_layer")
	if drag_layer:
		card_ui.reparent(drag_layer)
	card_ui.drop_point_detector.monitoring = true
	card_ui.global_position = card_ui.get_global_mouse_position() - mouse_offset


func on_input(event: InputEvent) -> void:
	if event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, CardState.State.BASE)
	elif event.is_action_released("left_mouse") and elapsed >= DRAG_MINIMUM_THRESHOLD:
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, CardState.State.RELEASED)


func _process(delta: float) -> void:
	if card_ui.card_state_machine.current_state == self:
		elapsed += delta
		card_ui.global_position = card_ui.get_global_mouse_position() - mouse_offset
