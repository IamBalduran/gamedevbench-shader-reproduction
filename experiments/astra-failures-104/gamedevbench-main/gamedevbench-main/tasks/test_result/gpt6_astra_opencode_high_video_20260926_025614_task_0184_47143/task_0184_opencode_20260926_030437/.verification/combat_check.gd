extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func wait_frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	var player = world.get_node("ActorsContainer/Player")
	var enemy = world.get_node("ActorsContainer/BasicEnemy")
	var enemy2 = world.get_node("ActorsContainer/BasicEnemy2")
	var enemies := 0
	for actor in world.get_node("ActorsContainer").get_children():
		if actor.scene_file_path == "res://scenes/characters/basic_enemy.tscn":
			enemies += 1
			check(actor.player == player, "Enemy player reference must resolve")
	check(enemies == 2, "World must contain exactly two enemies")
	var enemy_animation = enemy.get_node("AnimationPlayer")
	for name in ["idle", "walk", "hurt"]:
		var expected = {"idle": [0], "walk": [10, 11, 12, 13, 14, 15, 16, 17], "hurt": [60, 61, 62]}[name]
		var animation = enemy_animation.get_animation(name)
		var actual := []
		for key in animation.track_get_key_count(0):
			actual.append(animation.track_get_key_value(0, key))
		check(actual == expected, "Enemy animation frames: " + name)
	var start_distance: float = enemy.global_position.distance_to(player.global_position)
	await wait_frames(60)
	check(enemy.global_position.distance_to(player.global_position) < start_distance, "Enemy should chase player")
	await wait_frames(180)
	check(player.health < 30, "Enemy attack should damage player through Area2D")

	# Isolate the actors to exercise the player's real input and emitter.
	enemy2.queue_free()
	world.get_node("ActorsContainer/Barrel").queue_free()
	enemy.player = null
	await wait_frames(60)
	player.position = Vector2(30, 46)
	enemy.position = Vector2(42, 46)
	player.health = 30
	player.state = player.State.IDLE
	enemy.health = 12
	enemy.state = enemy.State.IDLE
	await wait_frames(5)
	Input.action_press("ui_right")
	await wait_frames(4)
	Input.action_release("ui_right")
	check(player.position.x > 30.0, "Player movement should respond to input")
	player.position = Vector2(30, 46)
	await wait_frames(3)
	Input.action_press("attack")
	await wait_frames(4)
	Input.action_release("attack")
	check(enemy.health == 8, "Player punch should inflict configured damage")
	check(enemy.state == enemy.State.HURT, "Enemy should enter hurt state")
	check(enemy.velocity.x > 0.0, "Enemy knockback should point away from the player")
	check(enemy_animation.current_animation == "hurt", "Enemy should play hurt animation")
	check(not enemy.get_node("DamageEmitter").monitoring, "Hurt should disable attack emitter")
	var health_after_hit: int = enemy.health
	enemy.get_node("DamageReceiver").damage_received.emit(4, Vector2.LEFT)
	check(enemy.health == health_after_hit, "Hurt reaction should prevent overlapping damage")
	await wait_frames(30)
	check(enemy.state == enemy.State.IDLE, "Enemy should recover from nonlethal hurt")
	check(player.state == player.State.IDLE, "Player should recover from punch")

	# Face left, attack again, and confirm the mirrored emitter and knockback.
	player.position = Vector2(50, 46)
	enemy.position = Vector2(38, 46)
	Input.action_press("ui_left")
	await wait_frames(2)
	Input.action_release("ui_left")
	await wait_frames(3)
	Input.action_press("attack")
	await wait_frames(4)
	Input.action_release("attack")
	check(enemy.health == 4 and enemy.velocity.x < 0.0, "Left-facing punch should damage and knock back left")
	await wait_frames(30)
	enemy.position = player.position - Vector2(12, 0)
	await wait_frames(3)
	Input.action_press("attack")
	await wait_frames(4)
	Input.action_release("attack")
	check(enemy.health == 0, "Repeated punches should exhaust enemy health")
	await wait_frames(30)
	check(not is_instance_valid(enemy), "Lethal hurt should remove enemy")

	# Player damage, attack interruption, recovery, and camera after player death.
	Input.action_press("attack")
	await wait_frames(2)
	Input.action_release("attack")
	player.get_node("DamageReceiver").damage_received.emit(3, Vector2.LEFT)
	await wait_frames(2)
	check(player.health == 27, "Player should receive damage")
	check(player.state == player.State.HURT and player.velocity.x < 0.0, "Player should be knocked back while hurt")
	check(player.get_node("AnimationPlayer").current_animation == "hurt", "Player should play hurt animation")
	check(not player.get_node("DamageEmitter").monitoring, "Interrupted player attack should turn off")
	await wait_frames(30)
	check(player.state == player.State.IDLE, "Player should recover from hurt")
	player.get_node("DamageReceiver").damage_received.emit(30, Vector2.RIGHT)
	await wait_frames(40)
	check(not is_instance_valid(player), "Lethal hurt should remove player")
	await wait_frames(10)
	print("Combat integration checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	world.queue_free()
	quit(0 if failures == 0 else 1)
