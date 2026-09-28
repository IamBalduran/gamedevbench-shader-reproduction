class_name BasicEnemy
extends Character

@export var player : Node2D

func handle_input() -> void:
	if player != null and can_move():
		var direction: Vector2 = (player.position - position).normalized()
		velocity = direction * speed
