extends Node

func _ready():
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	if player_scene == null:
		return _fail("Player scene not found at res://scenes/player.tscn")

	var player_instance = player_scene.instantiate()
	add_child(player_instance)

	if not player_instance is CharacterBody2D:
		return _fail("Player root must be CharacterBody2D")
	if player_instance.name != "Player":
		return _fail("Player root node must be named 'Player'")

	var animated_sprite: AnimatedSprite2D = player_instance.get_node_or_null("AnimatedSprite2D")
	if animated_sprite == null:
		return _fail("AnimatedSprite2D child missing on Player")

	var frames: SpriteFrames = animated_sprite.sprite_frames
	if frames == null:
		return _fail("Player AnimatedSprite2D has no SpriteFrames resource")

	var required_anims = ["default", "left", "right", "explode"]
	for anim_name in required_anims:
		if not frames.has_animation(anim_name):
			return _fail("AnimatedSprite2D missing '%s' animation" % anim_name)

	if animated_sprite.autoplay != "default":
		return _fail("AnimatedSprite2D autoplay must be 'default'")

	if not frames.get_animation_loop("default"):
		return _fail("'default' animation must loop")
	if not frames.get_animation_loop("left"):
		return _fail("'left' animation must loop")
	if not frames.get_animation_loop("right"):
		return _fail("'right' animation must loop")
	if frames.get_animation_loop("explode"):
		return _fail("'explode' animation must not loop")

	if frames.get_frame_count("default") != 1:
		return _fail("'default' animation must have exactly one frame")
	if not _texture_matches(frames.get_frame_texture("default", 0), "sprites-Sheet.png", Rect2(16, 0, 16, 16)):
		return _fail("'default' animation must use jet neutral frame at (16,0,16,16)")
	if not _texture_matches(frames.get_frame_texture("left", 0), "sprites-Sheet.png", Rect2(32, 0, 16, 16)):
		return _fail("'left' animation must use jet frame at (32,0,16,16)")
	if not _texture_matches(frames.get_frame_texture("right", 0), "sprites-Sheet.png", Rect2(48, 0, 16, 16)):
		return _fail("'right' animation must use jet frame at (48,0,16,16)")

	if frames.get_frame_count("explode") < 4:
		return _fail("'explode' animation must contain multiple frames from the smoke sheet")
	if not _texture_matches(frames.get_frame_texture("explode", 0), "Free Smoke Fx  Pixel 04.png", Rect2(0, 128, 64, 64)):
		return _fail("'explode' first frame must come from smoke sheet region (0,128,64,64)")
	if not _texture_matches(frames.get_frame_texture("explode", frames.get_frame_count("explode") - 1), "Free Smoke Fx  Pixel 04.png", Rect2(384, 128, 64, 64)):
		return _fail("'explode' animation should include later smoke frames (expect region 384,128,64,64)")

	var collision: CollisionShape2D = player_instance.get_node_or_null("CollisionShape2D")
	if collision == null:
		return _fail("CollisionShape2D child missing on Player")
	if not collision.shape is RectangleShape2D:
		return _fail("Player collider must be RectangleShape2D")
	if collision.shape.size != Vector2(16, 16):
		return _fail("Player collider must be 16×16")

	print("VALIDATION_PASSED: Player scene structure matches tutorial")
	get_tree().quit(0)

func _texture_matches(texture: Texture2D, path_suffix: String, region: Rect2) -> bool:
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		return atlas.atlas != null \
			and atlas.atlas.resource_path.ends_with(path_suffix) \
			and atlas.region == region
	return false

func _fail(message: String):
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit(1)
