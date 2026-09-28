extends Node2D

@onready var player := $ActorsContainer/Player
@onready var camera := $Camera

func _process(_delta: float) -> void:
	if is_instance_valid(player) and player.position.x > camera.position.x:
		camera.position.x = player.position.x
