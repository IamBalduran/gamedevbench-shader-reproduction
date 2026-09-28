extends Node

const REQUIRED_ANIMS = ["up", "down", "left", "right"]

func _ready() -> void:
	await get_tree().process_frame
	run_validation()

func run_validation() -> void:
	var main = get_node_or_null("Main")
	if not main:
		return _fail("VALIDATION_FAILED: Main scene is missing")

	var player = main.get_node_or_null("Player")
	if not player:
		return _fail("VALIDATION_FAILED: Player instance not found under Main")
	if not (player is Area2D):
		return _fail("VALIDATION_FAILED: Player must be an Area2D root")

	var sprite = player.get_node_or_null("Sprite2d")
	if not sprite:
		return _fail("VALIDATION_FAILED: Add a Sprite2d child to Player")
	if sprite.texture == null:
		return _fail("VALIDATION_FAILED: Sprite2d must use the sokoban_character texture")
	if sprite.texture.resource_path != "res://assets/sokoban_character.png":
		return _fail("VALIDATION_FAILED: Sprite2d texture must be res://assets/sokoban_character.png")
	if sprite.hframes != 6 or sprite.vframes != 4:
		return _fail("VALIDATION_FAILED: Sprite2d hframes/vframes must be 6x4 as in the tutorial")

	var collider = player.get_node_or_null("CollisionShape2d")
	if not collider:
		return _fail("VALIDATION_FAILED: Player needs a CollisionShape2d child")
	if not (collider.shape is RectangleShape2D):
		return _fail("VALIDATION_FAILED: CollisionShape2d must use a RectangleShape2D")
	var rect = collider.shape as RectangleShape2D
	if rect.size != Vector2(32, 32):
		return _fail("VALIDATION_FAILED: RectangleShape2D size must be 32x32 pixels")

	var ray = player.get_node_or_null("RayCast2d")
	if not ray:
		return _fail("VALIDATION_FAILED: Add a RayCast2d child to Player")
	if not ray.collide_with_areas:
		return _fail("VALIDATION_FAILED: RayCast2d must enable collide_with_areas")

	var anim_player = player.get_node_or_null("AnimationPlayer")
	if not anim_player:
		return _fail("VALIDATION_FAILED: Player needs an AnimationPlayer for walk cycles")
	for anim_name in REQUIRED_ANIMS:
		if not anim_player.has_animation(anim_name):
			return _fail("VALIDATION_FAILED: AnimationPlayer must include a '%s' animation" % anim_name)
		var anim = anim_player.get_animation(anim_name)
		if anim.get_track_count() == 0:
			return _fail("VALIDATION_FAILED: Animation '%s' must animate Sprite2d.frame" % anim_name)
		var path : NodePath = anim.track_get_path(0)
		if not path.get_name(path.get_name_count() - 1).contains("Sprite2d"):
			return _fail("VALIDATION_FAILED: Animation '%s' must key Sprite2d.frame" % anim_name)
		if not path.get_subname(path.get_subname_count() - 1).contains("frame"):
			return _fail("VALIDATION_FAILED: Animation '%s' must key Sprite2d.frame" % anim_name)
		if anim.track_get_key_count(0) < 4:
			return _fail("VALIDATION_FAILED: Animation '%s' needs keyframes for movement" % anim_name)

	print("VALIDATION_PASSED: Player node hierarchy matches the grid movement tutorial")
	get_tree().quit(0)

func _fail(message: String) -> void:
	print(message)
	get_tree().quit(1)
