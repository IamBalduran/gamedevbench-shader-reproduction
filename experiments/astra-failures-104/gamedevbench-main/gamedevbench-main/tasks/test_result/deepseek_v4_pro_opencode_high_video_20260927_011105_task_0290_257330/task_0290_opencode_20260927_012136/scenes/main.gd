extends Node2D

@onready var hand := $FieldUI/GripRow


func _ready() -> void:
	hand.add_card("Ward")
	hand.add_card("Rush")
	hand.add_card("Smite")
