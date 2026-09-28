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


func _get_animation_method_names(animation_player: AnimationPlayer, animation_name: String) -> Array:
	if not animation_player.has_animation(animation_name):
		return []

	var animation: Animation = animation_player.get_animation(animation_name)
	if animation == null:
		return []

	for track_idx: int in range(animation.get_track_count()):
		if animation.track_get_type(track_idx) != Animation.TYPE_METHOD:
			continue
		if String(animation.track_get_path(track_idx)) != ".":
			continue

		var methods: Array = []
		for key_idx: int in range(animation.track_get_key_count(track_idx)):
			var key_value: Variant = animation.track_get_key_value(track_idx, key_idx)
			if key_value is Dictionary and key_value.has("method"):
				methods.append(String(key_value["method"]))
		return methods

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

func run_validation() -> void:
	var player_scene: PackedScene = load("res://scenes/characters/player.tscn")
	if not assert_or_fail(player_scene != null, "player.tscn must load"):
		return

	var player: Node2D = player_scene.instantiate() as Node2D
	if not assert_or_fail(player != null, "player.tscn must instantiate"):
		return
	add_child(player)

	var animation_player: AnimationPlayer = player.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if not assert_or_fail(animation_player != null, "Player must contain AnimationPlayer"):
		return

	var character_sprite: Sprite2D = player.get_node_or_null("CharacterSprite") as Sprite2D
	if not assert_or_fail(character_sprite != null, "Player must contain CharacterSprite"):
		return

	if not assert_or_fail(_get_animation_frames(animation_player, "takeoff") == [61], "takeoff animation must use the expected frame from the 7th row"):
		return
	if not assert_or_fail(_get_animation_frames(animation_player, "jump") == [62], "jump animation must use the expected frame from the 7th row"):
		return
	if not assert_or_fail(_get_animation_frames(animation_player, "land") == [60], "land animation must use the expected frame from the 7th row"):
		return
	if not assert_or_fail(_get_animation_method_names(animation_player, "takeoff") == ["on_takeoff_complete"], "takeoff animation must call on_takeoff_complete when it finishes"):
		return
	if not assert_or_fail(_get_animation_method_names(animation_player, "land") == ["on_land_complete"], "land animation must call on_land_complete when it finishes"):
		return
	var anims_monitoring = _get_animation_property_values(animation_player, "land", "DamageEmitter:monitoring") 
	if not assert_or_fail(anims_monitoring in [[false, false], [false]], "land animation must disable DamageEmitter monitoring while it plays"):
		return

	Input.action_press("jump")
	player.call("_process", 0.016)
	Input.action_release("jump")
	if not assert_or_fail(animation_player.current_animation == "takeoff", "Pressing jump must start the takeoff animation"):
		return

	var entered_jump := false
	for _i: int in range(10):
		player.call("_process", 0.01)
		if animation_player.current_animation == "jump":
			entered_jump = true
			break
	if not assert_or_fail(entered_jump, "Takeoff must transition into the jump animation"):
		return

	var became_airborne := false
	for _i: int in range(20):
		player.call("_process", 0.05)
		if character_sprite.position.y < 0:
			became_airborne = true
			break
	if not assert_or_fail(became_airborne, "Jumping must lift CharacterSprite above its grounded position"):
		return

	var landed := false
	for _i: int in range(80):
		player.call("_process", 0.05)
		if animation_player.current_animation == "land":
			landed = true
			break
	if not assert_or_fail(landed, "The jump arc must end by entering the land animation"):
		return
	if not assert_or_fail(is_zero_approx(character_sprite.position.y), "CharacterSprite must return to its grounded position when landing begins"):
		return
	var damage_emitter: Area2D = player.get_node_or_null("DamageEmitter") as Area2D
	if not assert_or_fail(damage_emitter != null, "Player must contain DamageEmitter"):
		return
	if not assert_or_fail(damage_emitter.monitoring == false, "DamageEmitter monitoring must be disabled during the land animation"):
		return

	var returned_to_idle := false
	for _i: int in range(10):
		player.call("_process", 0.01)
		if animation_player.current_animation == "idle":
			returned_to_idle = true
			break
	if not assert_or_fail(returned_to_idle, "Landing must return the player to the grounded idle state"):
		return

	print("VALIDATION_PASSED: fighter jump action and animations are implemented")
	get_tree().quit(0)
