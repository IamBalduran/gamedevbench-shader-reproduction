extends Node2D

@onready var hand := $BattleOverlay/MoveBar


func _ready() -> void:
	hand.add_card("Cover")
	hand.add_card("Drive")
	hand.add_card("Cut")
