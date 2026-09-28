extends "res://scenes/characters/character.gd"

@export var player: CharacterBody2D
@export var attack_range := 13.0

func handle_input() -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	var offset := player.global_position - global_position
	if offset.length() <= attack_range:
		velocity = Vector2.ZERO
		state = State.ATTACK
	else:
		velocity = offset.normalized() * speed
