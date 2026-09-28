extends Node2D

@onready var hand := $TacticalUI/Cards


func _ready() -> void:
	hand.add_card("Bash")
	hand.add_card("Shield")
	hand.add_card("Jab")
