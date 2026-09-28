extends "res://scenes/characters/character.gd"

@export var player: CharacterBody2D
@export var attack_cooldown: float = 0.9

var attack_time_left := 0.0

func _physics_process(delta: float) -> void:
	attack_time_left = maxf(0.0, attack_time_left - delta)
	super._physics_process(delta)

func handle_input() -> void:
	velocity = Vector2.ZERO
	if not is_instance_valid(player) or player.is_queued_for_deletion():
		return
	var distance := player.global_position - global_position
	var facing := -1.0 if distance.x < 0.0 else 1.0
	character_sprite.flip_h = facing < 0.0
	damage_emitter.scale.x = facing
	if absf(distance.x) <= 12.0 and absf(distance.y) <= 3.0:
		if attack_time_left <= 0.0:
			state = State.ATTACK
			attack_time_left = attack_cooldown
	else:
		var target := player.global_position - Vector2(facing * 10.0, 0.0)
		velocity = global_position.direction_to(target) * speed
