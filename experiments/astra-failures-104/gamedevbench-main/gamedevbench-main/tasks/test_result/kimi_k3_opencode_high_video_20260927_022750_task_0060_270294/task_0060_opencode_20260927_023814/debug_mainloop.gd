extends SceneTree

var scene
var timer := 0.0
var tested := false

func _initialize():
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)

func _process(delta) -> bool:
	timer += delta
	if timer > 0.1 and not tested:
		tested = true
		var minimap = scene.get_node("CanvasLayer/Minimap")
		print("=== zoom setter tests ===")
		minimap.zoom = 10.0
		print("zoom clamp high (set 10 -> expect 3.0): ", minimap.zoom)
		minimap.zoom = 0.1
		print("zoom clamp low (set 0.1 -> expect 0.5): ", minimap.zoom)
		minimap.zoom = 1.0

		print("=== gui_input wheel tests ===")
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_WHEEL_UP
		up.pressed = true
		minimap._on_gui_input(up)
		print("after wheel up (expect 1.1): ", minimap.zoom)
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_WHEEL_DOWN
		down.pressed = true
		minimap._on_gui_input(down)
		print("after wheel down (expect 1.0): ", minimap.zoom)

		print("=== signal connection check via emit ===")
		var mob = scene.get_node("Mobs/Mob")
		print("before removal markers count: ", minimap.markers.size(), " has mob: ", minimap.markers.has(mob))
		mob.removed.emit(mob)
		print("after removal markers count (expect 1): ", minimap.markers.size(), " has mob: ", minimap.markers.has(mob))

		print("=== marker rotation follows player ===")
		minimap.player.rotation = PI / 4.0
		return false
	if tested and timer > 0.2:
		var minimap = scene.get_node("CanvasLayer/Minimap")
		var pm = minimap.get_node("Content/Grid/PlayerMarker")
		print("player marker rot (expect ", PI/4.0 + PI/2.0, "): ", pm.rotation)
		return true
	return false
