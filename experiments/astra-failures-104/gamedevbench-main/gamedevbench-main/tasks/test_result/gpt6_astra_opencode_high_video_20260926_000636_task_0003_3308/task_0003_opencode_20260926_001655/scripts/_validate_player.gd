extends SceneTree


func _initialize() -> void:
	call_deferred("validate_player")


func validate_player() -> void:
	var scene = load("res://scenes/player.tscn") as PackedScene
	assert(scene != null)
	var player = scene.instantiate()
	root.add_child(player)
	assert(player is CharacterBody2D and player.name == "Player")
	var sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert(sprite.autoplay == "default")
	assert(sprite.animation == &"default" and sprite.is_playing())
	for animation_name in [&"default", &"left", &"right"]:
		assert(sprite.sprite_frames.has_animation(animation_name))
		assert(sprite.sprite_frames.get_animation_loop(animation_name))
		var texture = sprite.sprite_frames.get_frame_texture(animation_name, 0)
		assert(texture is AtlasTexture and texture.region.size == Vector2(16, 16))
		assert(texture.atlas.resource_path == "res://assets/sprites/sprites-Sheet.png")
	assert(not sprite.sprite_frames.get_animation_loop(&"explode"))
	assert(sprite.sprite_frames.get_frame_count(&"explode") == 7)
	for frame in range(7):
		var texture = sprite.sprite_frames.get_frame_texture(&"explode", frame)
		assert(texture.atlas.resource_path == "res://assets/sprites/Free Smoke Fx  Pixel 04.png")
	var collision = player.get_node("CollisionShape2D") as CollisionShape2D
	assert(collision.shape is RectangleShape2D)
	assert(collision.shape.size == Vector2(16, 16))
	assert(collision.position == sprite.position and sprite.centered)
	assert(not collision.disabled)
	sprite.play(&"explode")
	await sprite.animation_finished
	assert(not sprite.is_playing() and sprite.frame == 6)
	print("PASS: Player hierarchy, autoplay, jet animations, collision, and one-shot explosion")
	quit()
