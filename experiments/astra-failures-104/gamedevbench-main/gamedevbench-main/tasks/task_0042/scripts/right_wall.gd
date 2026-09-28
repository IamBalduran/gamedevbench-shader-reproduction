extends Area2D

signal leftPointUp

func _on_area_entered(area):
	if area.name == "Ball":
		emit_signal("leftPointUp")
