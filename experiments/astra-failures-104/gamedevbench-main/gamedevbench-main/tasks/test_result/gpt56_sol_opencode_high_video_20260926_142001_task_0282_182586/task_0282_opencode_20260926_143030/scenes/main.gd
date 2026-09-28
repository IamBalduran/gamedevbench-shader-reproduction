extends Node2D

@onready var hand := $ScreenUI/Grip


func _ready() -> void:
	hand.add_card("Feint")
	hand.add_card("Ward")
	hand.add_card("Pierce")
