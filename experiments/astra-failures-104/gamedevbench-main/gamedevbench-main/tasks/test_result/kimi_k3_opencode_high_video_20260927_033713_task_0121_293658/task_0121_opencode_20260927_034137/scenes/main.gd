extends Node

@onready var balloon: CanvasLayer = $PortraitBalloon

func _ready() -> void:
	var portrait: TextureRect = balloon.get_node("%PortraitTexture")
	portrait.texture = load("res://assets/portraits/hero.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
