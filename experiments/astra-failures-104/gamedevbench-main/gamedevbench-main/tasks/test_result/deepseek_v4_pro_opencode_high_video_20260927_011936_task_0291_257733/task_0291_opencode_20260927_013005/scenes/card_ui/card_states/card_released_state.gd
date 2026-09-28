extends "res://scenes/card_ui/card_states/card_state.gd"


func enter() -> void:
	if not card_ui.targets.is_empty():
		card_ui.play()
		return


func on_input(_event: InputEvent) -> void:
	transition_requested.emit(state, State.BASE)