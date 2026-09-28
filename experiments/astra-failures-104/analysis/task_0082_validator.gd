extends Node

const REQUIRED_IDLE = ["idle0", "idle1", "idle2", "idle3", "idle4", "idle5", "idle6", "idle7"]
const REQUIRED_RUN = ["run0", "run1", "run2", "run3", "run4", "run5", "run6", "run7"]

func _ready() -> void:
	await get_tree().process_frame
	run_validation()

func run_validation() -> void:
	var main = get_node_or_null("Main")
	if main == null:
		return _fail("VALIDATION_FAILED: Main scene is missing")

	var player = main.get_node_or_null("Player")
	if player == null:
		return _fail("VALIDATION_FAILED: Add the Player scene to Main")
	if not (player is CharacterBody2D):
		return _fail("VALIDATION_FAILED: Player must be a CharacterBody2D root")
	if player.motion_mode != CharacterBody2D.MOTION_MODE_FLOATING:
		return _fail("VALIDATION_FAILED: Set Player.motion_mode to Floating for 8-direction movement")

	var animated_sprite = player.get_node_or_null("AnimatedSprite2D")
	if animated_sprite == null:
		return _fail("VALIDATION_FAILED: Player needs an AnimatedSprite2D child")
	if animated_sprite.sprite_frames == null:
		return _fail("VALIDATION_FAILED: AnimatedSprite2D must use the Crusader SpriteFrames resource")
	var frames: SpriteFrames = animated_sprite.sprite_frames
	for anim_name in REQUIRED_IDLE + REQUIRED_RUN:
		if not frames.has_animation(anim_name):
			return _fail("VALIDATION_FAILED: Missing %s animation" % anim_name)

	# test frame usage
	for anim_name in REQUIRED_IDLE:
		if frames.get_frame_count(anim_name) != 16:
			return _fail("VALIDATION_FAILED: Idle animations need multiple frames from the sprites")
		if frames.get_frame_texture(anim_name, 0) is not AtlasTexture:
			return _fail("VALIDATION_FAILED: Animation texture should be AtlasTexture")
		if not frames.get_frame_texture(anim_name, 0).atlas.resource_path.contains("crusader_idle"):
			return _fail("VALIDATION_FAILED: Idle animations used wrong frames")
			
	if not frames.get_frame_texture("idle4", 1).region == Rect2(299, 1440, 299, 240):
		return _fail("VALIDATION_FAILED: Idle animations atlas was sliced incorrectly")
	if not frames.get_frame_texture("idle7", 2).region == Rect2(598, 720, 299, 240):
		return _fail("VALIDATION_FAILED: Idle animations atlas was sliced incorrectly")
		
	
	for anim_name in REQUIRED_RUN:
		if frames.get_frame_count(anim_name) != 17:
			return _fail("VALIDATION_FAILED: Run animations must include the directional frames")
		if frames.get_frame_texture(anim_name, 0) is not AtlasTexture:
			return _fail("VALIDATION_FAILED: Animation texture should be AtlasTexture")
		if not frames.get_frame_texture(anim_name, 0).atlas.resource_path.contains("crusader_walk"):
			return _fail("VALIDATION_FAILED: Run animations used wrong frames")

	if not frames.get_frame_texture("run4", 1).region == Rect2(299, 1440, 299, 240):
		return _fail("VALIDATION_FAILED: Run animations atlas was sliced incorrectly")
	if not frames.get_frame_texture("run7", 2).region == Rect2(598, 720, 299, 240):
		return _fail("VALIDATION_FAILED: Run animations atlas was sliced incorrectly")
			
	if animated_sprite.animation != "idle0":
		return _fail("VALIDATION_FAILED: Default animation should start at idle0")
	if not is_equal_approx(animated_sprite.speed_scale, 2.0):
		return _fail("VALIDATION_FAILED: AnimatedSprite2D.speed_scale must be 2.0")
	
	# test frame offset correctness
	
	

	var collider = player.get_node_or_null("CollisionShape2D")
	if collider == null:
		return _fail("VALIDATION_FAILED: Player requires a CollisionShape2D child")
	if not (collider.shape is RectangleShape2D):
		return _fail("VALIDATION_FAILED: CollisionShape2D must use a RectangleShape2D")
	var rect := collider.shape as RectangleShape2D
	if rect.size != Vector2(66, 24):
		return _fail("VALIDATION_FAILED: Crusader rectangle size should be 66x24")
	if collider.position.distance_to(Vector2(7, 44)) > 0.1:
		return _fail("VALIDATION_FAILED: Collider offset must be positioned at (7, 44)")

	print("VALIDATION_PASSED: Crusader AnimatedSprite2D and collider are configured")
	get_tree().quit(0)

func _fail(message: String) -> void:
	print(message)
	get_tree().quit(1)
