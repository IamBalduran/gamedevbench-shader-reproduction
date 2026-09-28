extends "res://scenes/card_ui/card_states/card_state.gd"


func enter() -> void:
	card_ui.original_index = card_ui.get_index()
	card_ui.drop_point_detector.monitoring = true
	card_ui.state_label.text = "Clicked"


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		transition_requested.emit(self, State.DRAGGING)
	elif event.is_action_released("left_mouse") or event.is_action_pressed("right_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, State.BASE)
