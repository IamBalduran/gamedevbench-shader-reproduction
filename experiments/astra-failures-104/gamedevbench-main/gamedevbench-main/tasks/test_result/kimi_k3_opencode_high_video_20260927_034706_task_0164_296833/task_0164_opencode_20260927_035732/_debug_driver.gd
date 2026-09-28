extends Node

var frame := 0

func _process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		Input.action_press("jump")
		print("JUMP PRESSED at frame ", frame)
	if frame == 6:
		Input.action_release("jump")
