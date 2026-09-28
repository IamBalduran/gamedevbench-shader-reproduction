extends Node2D

@onready var hand := $BoardUI/HandBar


func _ready() -> void:
	hand.add_card("Thrust")
	hand.add_card("Guard")
	hand.add_card("Chant")
