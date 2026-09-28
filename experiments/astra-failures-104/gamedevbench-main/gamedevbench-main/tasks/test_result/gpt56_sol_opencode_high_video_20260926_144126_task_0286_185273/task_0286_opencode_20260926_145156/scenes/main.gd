extends Node2D

@onready var hand := $ActionUI/Tray


func _ready() -> void:
	hand.add_card("Ward")
	hand.add_card("Strike")
	hand.add_card("Brace")
