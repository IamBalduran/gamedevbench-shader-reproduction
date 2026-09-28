extends Node2D

@onready var hand := $ArenaUI/Palm


func _ready() -> void:
	hand.add_card("Charge")
	hand.add_card("Brace")
	hand.add_card("Slice")
