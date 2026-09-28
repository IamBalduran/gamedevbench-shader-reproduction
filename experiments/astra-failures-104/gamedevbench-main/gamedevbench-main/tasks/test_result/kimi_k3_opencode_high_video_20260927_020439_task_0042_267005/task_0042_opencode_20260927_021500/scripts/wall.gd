extends Area2D

signal rightPointUp

func _on_area_entered(area):
	if area.name == "Ball":
		emit_signal("rightPointUp")
