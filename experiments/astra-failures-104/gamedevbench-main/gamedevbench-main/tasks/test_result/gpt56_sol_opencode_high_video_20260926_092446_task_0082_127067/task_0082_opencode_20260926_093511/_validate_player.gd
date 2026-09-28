extends SceneTree


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/Player.tscn")
	assert(packed != null)
	var player := packed.instantiate() as CharacterBody2D
	assert(player != null)
	assert(player.motion_mode == CharacterBody2D.MOTION_MODE_FLOATING)

	var sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert(sprite != null)
	assert(sprite.animation == &"idle0")
	assert(sprite.speed_scale == 2.0)
	for prefix in [&"idle", &"run"]:
		for direction in 8:
			var animation := StringName(str(prefix) + str(direction))
			assert(sprite.sprite_frames.has_animation(animation))
			assert(sprite.sprite_frames.get_frame_count(animation) == (16 if prefix == &"idle" else 15))

	var collision := player.get_node("CollisionShape2D") as CollisionShape2D
	assert(collision != null)
	assert(collision.position == Vector2(7, 44))
	assert(collision.shape is RectangleShape2D)
	assert(collision.shape.size == Vector2(66, 24))

	player.position = Vector2(200, 150)
	root.add_child(player)
