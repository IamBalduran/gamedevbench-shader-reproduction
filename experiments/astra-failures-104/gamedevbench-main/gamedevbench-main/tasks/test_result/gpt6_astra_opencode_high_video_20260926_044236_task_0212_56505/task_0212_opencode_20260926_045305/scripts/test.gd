extends Node

func _ready():
	run_validation()

func fail(message: String) -> void:
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit(1)

func run_validation():
	var main_node = get_node_or_null("Main")
	if not main_node:
		fail("Main scene is missing")
		return

	var trap = main_node.get_node_or_null("Trap")
	if not trap or not trap is Node2D:
		fail("Trap node must exist as a Node2D child of Main")
		return

	if trap.position.distance_to(Vector2(320, 180)) > 0.5:
		fail("Trap must be centered at Vector2(320, 180)")
		return

	if trap.scale.distance_to(Vector2(1.6, 1.6)) > 0.05:
		fail("Trap must be scaled to Vector2(1.6, 1.6)")
		return

	var sprite = trap.get_node_or_null("Sprite2D")
	if not sprite or not sprite is Sprite2D:
		fail("Trap must keep its Sprite2D child")
		return

	if sprite.position.distance_to(Vector2(64.5, 34.5)) > 0.5:
		fail("Sprite2D must keep its transformed position")
		return

	if abs(sprite.rotation) > 0.02:
		fail("Sprite2D must be rotated back to 0")
		return

	if sprite.scale.distance_to(Vector2(0.07473366, 0.08652595)) > 0.05:
		fail("Sprite2D must keep its transformed scale")
		return

	var spawn_holder = trap.get_node_or_null("SpawningPoints")
	if not spawn_holder or not spawn_holder is Node2D:
		fail("Add a Node2D named SpawningPoints under Trap")
		return

	var spawn_top = spawn_holder.get_node_or_null("SpawnTop")
	if not spawn_top or not spawn_top is Marker2D:
		fail("SpawningPoints needs a Marker2D child named SpawnTop")
		return

	var spawn_bot = spawn_holder.get_node_or_null("SpawnBot")
	if not spawn_bot or not spawn_bot is Marker2D:
		fail("SpawningPoints needs a Marker2D child named SpawnBot")
		return

	if spawn_top.position.distance_to(Vector2(36.5, 65.5)) > 5.0:
		fail("SpawnTop must line up with the bottom tip of the branch closest to the water")
		return

	if spawn_bot.position.distance_to(Vector2(76.49999, 65.5)) > 5.0:
		fail("SpawnBot must line up with the rightmost bottom tip of the trunk")
		return

	if spawn_bot.z_index != 1:
		fail("SpawnBot should render above Trap by setting z_index to 1")
		return

	print("VALIDATION_PASSED: Spawning markers configured for the trap")
	get_tree().quit(0)
