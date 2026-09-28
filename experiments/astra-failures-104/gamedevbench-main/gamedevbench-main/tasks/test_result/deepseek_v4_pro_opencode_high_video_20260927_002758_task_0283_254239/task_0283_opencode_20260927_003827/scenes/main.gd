extends Node2D

@onready var hand := $OverlayUI/Rack


func _ready() -> void:
	hand.add_card("Shell")
	hand.add_card("Focus")
	hand.add_card("Chop")
