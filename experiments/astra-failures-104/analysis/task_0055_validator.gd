extends Node

const REQUIRED_TOKENS := [
	"get_local_mouse_position",
	"snappedf",
	"wrapi",
	"Input.is_action_pressed",
	"move_and_slide",
	"AnimatedSprite2D.play"
]

func _ready() -> void:
	await get_tree().process_frame
	run_validation()

func run_validation() -> void:
	var main = get_node_or_null("Main")
	if main == null:
		return _fail("VALIDATION_FAILED: Main scene missing")

	var player = main.get_node_or_null("Player")
	if player == null:
		return _fail("VALIDATION_FAILED: Player instance missing from Main")
	if not (player is CharacterBody2D):
		return _fail("VALIDATION_FAILED: Player must be a CharacterBody2D")

	var script_path = "res://scripts/player.gd"
	if not FileAccess.file_exists(script_path):
		return _fail("VALIDATION_FAILED: scripts/player.gd was not created")
	var script_text = FileAccess.get_file_as_string(script_path)
	for token in REQUIRED_TOKENS:
		if token not in script_text:
			return _fail("VALIDATION_FAILED: player.gd must reference %s" % token)

	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return _fail("VALIDATION_FAILED: AnimatedSprite2D child not found on Player")

	player.global_position = Vector2.ZERO
	Input.action_release("left_mouse")
	player._physics_process(0.016)
	if sprite.animation != "idle0":
		return _fail("VALIDATION_FAILED: Without clicks the character should stay on idle0")
	if not is_zero_approx(player.velocity.length()):
		return _fail("VALIDATION_FAILED: Player velocity must stay zero when not moving")

	Input.action_press("left_mouse")
	player.global_position = Vector2(-200, 0)
	player._physics_process(0.016)
	Input.action_release("left_mouse")
	if not sprite.animation.begins_with("run"):
		return _fail("VALIDATION_FAILED: Clicking should switch to a run animation")
	if is_zero_approx(player.velocity.length()):
		return _fail("VALIDATION_FAILED: Mouse press should push the character in motion")

	print("VALIDATION_PASSED: Mouse-based 8-direction logic implemented")
	get_tree().quit(0)

func _fail(message: String) -> void:
	print(message)
	get_tree().quit(1)
