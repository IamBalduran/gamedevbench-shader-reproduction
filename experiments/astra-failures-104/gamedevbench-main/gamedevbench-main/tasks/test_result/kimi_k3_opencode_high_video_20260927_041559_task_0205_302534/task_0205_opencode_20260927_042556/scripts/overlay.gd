extends Node2D

func _draw():
	var sp = get_node_or_null("../SpawningPoints")
	if sp:
		for m in sp.get_children():
			var p = sp.position + m.position
			# crosshair
			draw_line(p + Vector2(-10, 0), p + Vector2(10, 0), Color(1, 0, 1), 1.0)
			draw_line(p + Vector2(0, -10), p + Vector2(0, 10), Color(1, 0, 1), 1.0)
			draw_circle(p, 5, Color(1, 0, 1, 0.3))
			draw_string(ThemeDB.fallback_font, p + Vector2(8, -8), m.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0, 1))
