extends "res://scenes/card_ui/card_states/card_state.gd"


func enter() -> void:
	if not card_ui.targets.is_empty():
		card_ui.queue_free()


func on_input(_event: InputEvent) -> void:
	transition_requested.emit(self, CardState.State.BASE)