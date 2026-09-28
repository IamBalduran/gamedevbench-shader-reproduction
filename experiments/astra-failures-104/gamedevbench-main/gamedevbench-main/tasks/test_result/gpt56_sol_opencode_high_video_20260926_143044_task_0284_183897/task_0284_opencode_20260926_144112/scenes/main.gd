extends Node2D

@onready var hand := $BattleUI/Hand


func _ready() -> void:
	hand.add_card("Block")
	hand.add_card("Defend")
	hand.add_card("Strike")
