extends "res://scenes/card_ui/card_states/card_state.gd"


func enter() -> void:
	if card_ui.tween and card_ui.tween.is_running():
		card_ui.tween.kill()
	card_ui.reparent_requested.emit(card_ui)
	card_ui.pivot_offset = Vector2.ZERO
	card_ui.drop_point_detector.monitoring = false
	card_ui.targets.clear()
	card_ui.state_label.text = "Base"


func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		card_ui.pivot_offset = card_ui.get_global_mouse_position() - card_ui.global_position
		card_ui.accept_event()
		transition_requested.emit(self, State.CLICKED)
