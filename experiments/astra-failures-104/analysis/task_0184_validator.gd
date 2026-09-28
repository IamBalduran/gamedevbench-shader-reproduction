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


func _is_node_wired_to_player(enemy: Node, player: Node) -> bool:
	var player_ref: Variant = enemy.get("player")
	if player_ref is Node:
		return player_ref == player
	if player_ref is NodePath:
		return enemy.get_node_or_null(player_ref) == player
	return false


func _script_extends_base(script: Script, base_path: String) -> bool:
	if script == null:
		return false
	var current: Script = script
	while current != null:
		if String(current.resource_path) == base_path:
			return true
		current = current.get_base_script() as Script
	return false


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
			frames.append(animation.track_get_key_value(track_idx, key_idx))
		return frames

	return []


func _assert_hurt_response(character: Node2D, expected_x_sign: float, label: String) -> bool:
	var damage_receiver: Node = character.get_node_or_null("DamageReceiver") as Node
	if not assert_or_fail(damage_receiver != null, "%s must contain DamageReceiver" % label):
		return false
	if not assert_or_fail(int(damage_receiver.get("collision_layer")) > 0, "%s DamageReceiver must use a non-zero collision layer" % label):
		return false

	var anim_player: AnimationPlayer = character.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if not assert_or_fail(anim_player != null, "%s must contain AnimationPlayer" % label):
		return false
	if not assert_or_fail(anim_player.has_animation("hurt"), "%s must include a hurt animation" % label):
		return false

	damage_receiver.emit_signal("damage_received", 3, Vector2(expected_x_sign, 0))
	character.call("_process", 0.016)
	if not assert_or_fail(anim_player.current_animation == "hurt", "%s must play the hurt animation after taking damage" % label):
		return false
	if not assert_or_fail(signf(character.get("velocity").x) == expected_x_sign, "%s knockback must follow the hit direction" % label):
		return false

	return true


func _assert_removed_after_repeated_damage(character: Node2D, label: String) -> bool:
	var damage_receiver: Node = character.get_node_or_null("DamageReceiver") as Node
	if not assert_or_fail(damage_receiver != null, "%s must contain DamageReceiver for repeated damage checks" % label):
		return false

	for _i: int in range(32):
		if not is_instance_valid(character):
			return true
		damage_receiver.emit_signal("damage_received", 3, Vector2.LEFT)
		await get_tree().process_frame

	return assert_or_fail(not is_instance_valid(character), "%s must be removed after taking enough damage" % label)

func _get_array_set(vals : Array):
	var ret := []
	for v in vals:
		if v not in ret:
			ret.append(v)
	ret.sort()
	return ret

func run_validation() -> void:
	var world_scene: PackedScene = load("res://world.tscn")
	if not assert_or_fail(world_scene != null, "world.tscn must load"):
		return

	var world: Node = world_scene.instantiate()
	add_child(world)

	var actors: Node = world.get_node_or_null("ActorsContainer") as Node
	if not assert_or_fail(actors != null, "ActorsContainer must exist"):
		return

	var player_scene: PackedScene = load("res://scenes/characters/player.tscn")
	if not assert_or_fail(player_scene != null, "player.tscn must load"):
		return

	var player: Node = world.get_node_or_null("ActorsContainer/Player")
	if not assert_or_fail(player != null, "World must include a Player node under ActorsContainer"):
		return

	var base_enemy_scene: PackedScene = load("res://scenes/characters/basic_enemy.tscn")
	if not assert_or_fail(base_enemy_scene != null, "basic_enemy.tscn must exist"):
		return

	var enemy_script_resource: Script = load("res://scenes/characters/basic_enemy.gd") as Script
	if not assert_or_fail(enemy_script_resource != null, "basic_enemy.gd must exist"):
		return
	if not assert_or_fail(_script_extends_base(enemy_script_resource, "res://scenes/characters/character.gd"), "basic_enemy.gd must extend Character"):
		return

	var character_script: Script = load("res://scenes/characters/character.gd") as Script
	if not assert_or_fail(character_script != null, "character.gd must load"):
		return

	var world_enemies: Array[Node] = []
	for child: Node in actors.get_children():
		var child_script: Script = child.get_script() as Script
		if child_script != null and String(child_script.resource_path) == "res://scenes/characters/basic_enemy.gd":
			world_enemies.append(child)

	if not assert_or_fail(world_enemies.size() == 2, "World must include exactly two basic enemy instances under ActorsContainer"):
		return
	for enemy: Node in world_enemies:
		if not assert_or_fail(_is_node_wired_to_player(enemy, player), "Each world basic enemy must reference the world player through its exported player property"):
			return

	var base_enemy: Node2D = base_enemy_scene.instantiate() as Node2D
	add_child(base_enemy)
	var enemy_script: Script = base_enemy.get_script() as Script
	if not assert_or_fail(enemy_script != null, "BasicEnemy must have a script"):
		return
	if not assert_or_fail(String(enemy_script.resource_path) == "res://scenes/characters/basic_enemy.gd", "BasicEnemy must use scenes/characters/basic_enemy.gd"):
		return
	var enemy_sprite: Sprite2D = base_enemy.get_node_or_null("CharacterSprite") as Sprite2D
	if not assert_or_fail(enemy_sprite != null, "BasicEnemy must contain CharacterSprite"):
		return
	if not assert_or_fail(enemy_sprite.texture != null and String(enemy_sprite.texture.resource_path) == "res://assets/art/characters/enemy_boss.png", "BasicEnemy must use res://assets/art/characters/enemy_boss.png for CharacterSprite"):
		return
	var enemy_anim_player: AnimationPlayer = base_enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if not assert_or_fail(enemy_anim_player != null, "BasicEnemy must contain AnimationPlayer"):
		return
	if not assert_or_fail(_get_array_set(_get_animation_frames(enemy_anim_player, "idle")) == [0], "BasicEnemy idle animation must use the expected sprite frame sequence"):
		return
	if not assert_or_fail(_get_array_set(_get_animation_frames(enemy_anim_player, "walk")) == [10, 11, 12, 13, 14, 15, 16, 17], "BasicEnemy walk animation must use the expected sprite frame sequence"):
		return
	if not assert_or_fail(_get_array_set(_get_animation_frames(enemy_anim_player, "hurt")) == [50, 51], "BasicEnemy hurt animation must use the expected sprite frame sequence"):
		return

	var damage_receiver_scene: Node = base_enemy.get_node_or_null("DamageReceiver") as Node
	if not assert_or_fail(damage_receiver_scene != null, "BasicEnemy must contain DamageReceiver"):
		return

	var chase_player: Node2D = player_scene.instantiate() as Node2D
	if not assert_or_fail(chase_player != null, "Player scene must instantiate for chase test"):
		return
	chase_player.position = Vector2(40, 0)
	add_child(chase_player)
	base_enemy.position = Vector2.ZERO
	base_enemy.set("player", chase_player)
	base_enemy.call("_process", 0.016)
	var velocity: Vector2 = base_enemy.get("velocity")
	if not assert_or_fail(velocity.length() > 0.0 and velocity.x > 0.0, "BasicEnemy handle_input must chase assigned player"):
		return

	if not _assert_hurt_response(base_enemy, -1.0, "BasicEnemy"):
		return

	var player_instance: Node2D = player_scene.instantiate() as Node2D
	add_child(player_instance)
	if not assert_or_fail(player_instance.get_node_or_null("DamageReceiver") != null, "Player must contain DamageReceiver"):
		return
	var player_anim: AnimationPlayer = player_instance.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if not assert_or_fail(player_anim != null, "Player must include AnimationPlayer"):
		return
	if not _assert_hurt_response(player_instance, 1.0, "Player"):
		return

	var enemy_emitter: Area2D = base_enemy.get_node_or_null("DamageEmitter") as Area2D
	var player_receiver: Area2D = player_instance.get_node_or_null("DamageReceiver") as Area2D
	if not assert_or_fail(enemy_emitter != null, "BasicEnemy must contain DamageEmitter"):
		return
	if not assert_or_fail(player_receiver != null, "Player must contain DamageReceiver"):
		return
	enemy_emitter.area_entered.emit(player_receiver)
	base_enemy.call("_process", 0.016)
	player_instance.call("_process", 0.016)
	if not assert_or_fail(player_anim.current_animation == "hurt", "Enemy attacks must damage the player through the shared damage system"):
		return

	var doomed_enemy: Node2D = base_enemy_scene.instantiate() as Node2D
	add_child(doomed_enemy)
	if not await _assert_removed_after_repeated_damage(doomed_enemy, "BasicEnemy"):
		return

	var doomed_player: Node2D = player_scene.instantiate() as Node2D
	add_child(doomed_player)
	if not await _assert_removed_after_repeated_damage(doomed_player, "Player"):
		return

	print("VALIDATION_PASSED: basic enemies, hurt state, and knockback are implemented")
	get_tree().quit(0)
