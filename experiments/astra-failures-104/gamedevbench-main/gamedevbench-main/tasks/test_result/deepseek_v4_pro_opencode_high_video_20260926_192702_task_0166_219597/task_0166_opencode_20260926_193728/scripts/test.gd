extends Node


func _ready() -> void:
	run_validation()


func fail(message: String) -> void:
	print("VALIDATION_FAILED: " + message)
	get_tree().quit(1)


func assert_or_fail(condition: bool, message: String) -> bool:
	if not condition:
		fail(message)
		return false
	return true


func _ensure_action_exists(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)


func _get_animation_frames(animation_player: AnimationPlayer, animation_name: String) -> Array:
	if not animation_player.has_animation(animation_name):
		return []

	var animation: Animation = animation_player.get_animation(animation_name)
	if animation == null:
		return []

	for track_idx: int in range(animation.get_track_count()):
		if animation.track_get_type(track_idx) != Animation.TYPE_VALUE:
			continue
		if String(animation.track_get_path(track_idx)) != "CharacterSprite:frame":
			continue

		var frames: Array = []
		for key_idx: int in range(animation.track_get_key_count(track_idx)):
			var frame_value: Variant = animation.track_get_key_value(track_idx, key_idx)
			if frames.is_empty() or frames[-1] != frame_value:
				frames.append(frame_value)
		return frames

	return []


func _get_animation_property_values(animation_player: AnimationPlayer, animation_name: String, property_path: String) -> Array:
	if not animation_player.has_animation(animation_name):
		return []

	var animation: Animation = animation_player.get_animation(animation_name)
	if animation == null:
		return []

	for track_idx: int in range(animation.get_track_count()):
		if animation.track_get_type(track_idx) != Animation.TYPE_VALUE:
			continue
		if String(animation.track_get_path(track_idx)) != property_path:
			continue

		var values: Array = []
		for key_idx: int in range(animation.track_get_key_count(track_idx)):
			values.append(animation.track_get_key_value(track_idx, key_idx))
		return values

	return []

func _get_animation_method_names(animation_player: AnimationPlayer, animation_name: String) -> Array:
	if not animation_player.has_animation(animation_name):
		return []

	var animation: Animation = animation_player.get_animation(animation_name)
	if animation == null:
		return []

	var method_names: Array = []
	for track_idx: int in range(animation.get_track_count()):
		if animation.track_get_type(track_idx) != Animation.TYPE_METHOD:
			continue

		for key_idx: int in range(animation.track_get_key_count(track_idx)):
			var key_value: Variant = animation.track_get_key_value(track_idx, key_idx)
			if key_value is Dictionary and key_value.has("method"):
				method_names.append(String(key_value["method"]))

	return method_names

func run_validation() -> void:
	for action_name: String in ["ui_left", "ui_right", "ui_up", "ui_down", "attack", "jump"]:
		_ensure_action_exists(action_name)

	var player_scene: PackedScene = load("res://scenes/characters/player.tscn")
	if not assert_or_fail(player_scene != null, "player.tscn must load"):
		return

	var player: Node2D = player_scene.instantiate() as Node2D
	if not assert_or_fail(player != null, "player.tscn must instantiate"):
		return
	add_child(player)
	await get_tree().process_frame

	var animation_player: AnimationPlayer = player.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if not assert_or_fail(animation_player != null, "Player must contain AnimationPlayer"):
		return

	var character_sprite: Sprite2D = player.get_node_or_null("CharacterSprite") as Sprite2D
	if not assert_or_fail(character_sprite != null, "Player must contain CharacterSprite"):
		return

	if not assert_or_fail(_get_animation_frames(animation_player, "kick") == [40, 41, 42, 43, 44, 45], "kick animation must use all valid frames from the 5th row"):
		return
	var kick_monitoring_values: Array = _get_animation_property_values(animation_player, "kick", "DamageEmitter:monitoring")
	if not assert_or_fail(not kick_monitoring_values.is_empty() and kick_monitoring_values[0] == true and kick_monitoring_values[-1] == false, "kick animation must enable DamageEmitter monitoring during the kick and disable it when the kick ends"):
		return
	if not assert_or_fail("on_action_complete" in _get_animation_method_names(animation_player, "kick"), "kick animation must call on_action_complete when it finishes"):
		return
	if not assert_or_fail(animation_player.has_animation("punch"), "Player must preserve the existing punch animation"):
		return
	var damage_emitter: Area2D = player.get_node_or_null("DamageEmitter") as Area2D
	if not assert_or_fail(damage_emitter != null, "Player must contain DamageEmitter"):
		return

	Input.action_press("attack")
	await get_tree().process_frame
	Input.action_release("attack")
	await get_tree().process_frame
	if not assert_or_fail(animation_player.current_animation == "punch", "Pressing attack while idle must still play the punch animation"):
		return
	player.queue_free()
	await get_tree().process_frame

	player = player_scene.instantiate() as Node2D
	if not assert_or_fail(player != null, "player.tscn must instantiate for the kick test"):
		return
	add_child(player)
	await get_tree().process_frame
	animation_player = player.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if not assert_or_fail(animation_player != null, "Player must contain AnimationPlayer for the kick test"):
		return
	character_sprite = player.get_node_or_null("CharacterSprite") as Sprite2D
	if not assert_or_fail(character_sprite != null, "Player must contain CharacterSprite for the kick test"):
		return
	damage_emitter = player.get_node_or_null("DamageEmitter") as Area2D
	if not assert_or_fail(damage_emitter != null, "Player must contain DamageEmitter for the kick test"):
		return
	player.velocity = Vector2.RIGHT * player.speed
	player.call("handle_movement")
	if not assert_or_fail(player.velocity.x > 0.0, "The player must still be able to move horizontally before kicking"):
		return
	Input.action_press("attack")
	await get_tree().process_frame
	Input.action_release("attack")
	await get_tree().process_frame
	if not assert_or_fail(animation_player.current_animation == "kick", "Pressing attack while walking must trigger the kick animation"):
		return
	if not assert_or_fail(is_zero_approx(player.velocity.x), "Starting the kick must stop the player's horizontal movement"):
		return
	if not assert_or_fail(damage_emitter.monitoring == true, "Kick must enable DamageEmitter monitoring while the attack is active"):
		return
	if not assert_or_fail(is_zero_approx(character_sprite.position.y), "Kick must remain a grounded attack"):
		return

	var monitoring_disabled := false
	for _i: int in range(120):
		await get_tree().create_timer(0.01).timeout
		if damage_emitter.monitoring == false:
			monitoring_disabled = true
			break
	if not assert_or_fail(monitoring_disabled, "Kick must disable DamageEmitter monitoring again after the attack finishes"):
		return

	print("VALIDATION_PASSED: fighter kick action and animation are implemented")
	get_tree().quit(0)
