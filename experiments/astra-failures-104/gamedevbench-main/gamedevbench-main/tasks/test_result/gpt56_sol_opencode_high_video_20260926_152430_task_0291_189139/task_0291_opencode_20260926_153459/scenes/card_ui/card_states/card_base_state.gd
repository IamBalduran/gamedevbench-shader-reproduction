extends "res://scenes/card_ui/card_states/card_state.gd"


func enter() -> void:
	card_ui.drop_point_detector.monitoring = false
	card_ui.targets.clear()
	card_ui.reparent_requested.emit(card_ui)


func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		transition_requested.emit(self, State.CLICKED)
