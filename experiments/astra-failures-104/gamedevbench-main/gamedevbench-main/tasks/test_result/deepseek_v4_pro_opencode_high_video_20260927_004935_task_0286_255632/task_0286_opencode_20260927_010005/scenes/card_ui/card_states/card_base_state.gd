extends "res://scenes/card_ui/card_states/card_state.gd"


func enter() -> void:
	card_ui.reparent_requested.emit(card_ui)
	card_ui.drop_point_detector.monitoring = false


func on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		transition_requested.emit(self, CardState.State.CLICKED)