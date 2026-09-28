class_name BasicEnemy
extends "res://scenes/characters/character.gd"

@export var player : Node2D

func handle_input() -> void:
	if player != null and can_move():
		var direction := (player.position - position).normalized()
		velocity = direction * speed
