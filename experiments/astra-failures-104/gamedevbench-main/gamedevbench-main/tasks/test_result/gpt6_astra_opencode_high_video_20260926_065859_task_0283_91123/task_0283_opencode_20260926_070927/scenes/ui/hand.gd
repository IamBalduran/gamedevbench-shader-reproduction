extends HBoxContainer

const CARD_UI_SCENE := preload("res://scenes/card_ui/card_ui.tscn")


func add_card(card_title: String) -> void:
	var new_card_ui = CARD_UI_SCENE.instantiate()
	new_card_ui.home_parent = self
	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	add_child(new_card_ui)
	new_card_ui.card_title = card_title


func _on_card_ui_reparent_requested(which_card_ui) -> void:
	if which_card_ui.get_parent() != self:
		which_card_ui.reparent(self)
		move_child(which_card_ui, clampi(which_card_ui.original_index, 0, get_child_count() - 1))
