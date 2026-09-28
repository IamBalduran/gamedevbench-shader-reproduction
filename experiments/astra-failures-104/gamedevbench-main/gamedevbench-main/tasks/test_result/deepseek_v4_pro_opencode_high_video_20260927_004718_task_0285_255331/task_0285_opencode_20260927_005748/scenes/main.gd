extends Node2D

@onready var hand := $CombatHUD/Slots


func _ready() -> void:
	hand.add_card("Block")
	hand.add_card("Lunge")
	hand.add_card("Guard")
