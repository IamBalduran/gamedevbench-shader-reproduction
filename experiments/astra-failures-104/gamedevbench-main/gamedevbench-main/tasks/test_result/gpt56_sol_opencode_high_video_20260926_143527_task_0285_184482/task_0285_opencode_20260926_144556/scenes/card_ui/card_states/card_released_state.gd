extends "res://scenes/card_ui/card_states/card_state.gd"


func enter() -> void:
	if not card_ui.targets.is_empty():
		card_ui.play()


func on_input(_event: InputEvent) -> void:
	if card_ui.targets.is_empty():
		transition_requested.emit(self, CardState.State.BASE)
