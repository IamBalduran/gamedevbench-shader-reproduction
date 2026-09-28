extends Node

const MIN_IOU := 0.90

func _ready():
	run_validation()

func fail(message: String) -> void:
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit(1)

func base_circle_points() -> Array:
	return [
		Vector2(18, 0),
		Vector2(16.63, 6.89),
		Vector2(12.73, 12.73),
		Vector2(6.89, 16.63),
		Vector2(0, 18),
		Vector2(-6.89, 16.63),
		Vector2(-12.73, 12.73),
		Vector2(-16.63, 6.89),
		Vector2(-18, 0),
		Vector2(-16.63, -6.89),
		Vector2(-12.73, -12.73),
		Vector2(-6.89, -16.63),
		Vector2(0, -18),
		Vector2(6.89, -16.63),
		Vector2(12.73, -12.73),
		Vector2(16.63, -6.89),
	]

func expected_highlights() -> Dictionary:
	return {
		"CoinHighlight1": {"position": Vector2(283.49997, 110.99999), "scale": Vector2(0.8361113, 0.8166667), "polygon": base_circle_points()},
		"CoinHighlight2": {
			"position": Vector2(319.5, 84.0),
			"scale": Vector2(0.7944446, 0.7861112),
			"polygon": [
				Vector2(18, 0),
				Vector2(16.63, 6.89),
				Vector2(12.73, 12.73),
				Vector2(6.89, 16.63),
				Vector2(0, 18),
				Vector2(-6.89, 16.63),
				Vector2(-12.73, 12.73),
				Vector2(-16.63, 6.89),
				Vector2(-18, 0),
				Vector2(-16.63, -6.89),
				Vector2(-12.73, -12.73),
				Vector2(-6.89, -16.63),
				Vector2(0, -18),
				Vector2(6.89, -16.63),
				Vector2(12.73, -12.73),
				Vector2(15.104889, -10.176674),
				Vector2(16.63, -6.89),
			],
		},
		"CoinHighlight3": {"position": Vector2(426.25003, 72.450005), "scale": Vector2(0.7916667, 0.75277746), "polygon": base_circle_points()},
		"CoinHighlight4": {"position": Vector2(288.5, 187.0), "scale": Vector2(0.794097, 0.82256955), "polygon": base_circle_points()},
		"CoinHighlight5": {"position": Vector2(287.50003, 297.0), "scale": Vector2(0.79722255, 0.82777745), "polygon": base_circle_points()},
		"CoinHighlight6": {"position": Vector2(254.49998, 312.0), "scale": Vector2(0.85000014, 0.8083335), "polygon": base_circle_points()},
	}

func transformed_points(points, position: Vector2, scale: Vector2, rotation: float) -> Array:
	var transformed: Array = []
	for point in points:
		var local_point = Vector2(point.x * scale.x, point.y * scale.y).rotated(rotation)
		transformed.append(local_point + position)
	return transformed

func signed_area(points: Array) -> float:
	var total := 0.0
	for i in range(points.size()):
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5

func polygon_area(points: Array) -> float:
	return abs(signed_area(points))

func is_inside(point: Vector2, edge_start: Vector2, edge_end: Vector2, orientation: float) -> bool:
	var cross_value = (edge_end - edge_start).cross(point - edge_start)
	return cross_value * orientation >= -0.0001

func line_intersection(start_a: Vector2, end_a: Vector2, start_b: Vector2, end_b: Vector2) -> Vector2:
	var direction_a = end_a - start_a
	var direction_b = end_b - start_b
	var denominator = direction_a.cross(direction_b)
	if abs(denominator) < 0.00001:
		return end_a
	var t = (start_b - start_a).cross(direction_b) / denominator
	return start_a + direction_a * t

func clipped_polygon(subject: Array, clip: Array) -> Array:
	var output := subject.duplicate()
	if output.is_empty() or clip.is_empty():
		return []
	var orientation := 1.0 if signed_area(clip) >= 0.0 else -1.0
	for i in range(clip.size()):
		var edge_start: Vector2 = clip[i]
		var edge_end: Vector2 = clip[(i + 1) % clip.size()]
		var input := output.duplicate()
		output.clear()
		if input.is_empty():
			break
		var previous: Vector2 = input[input.size() - 1]
		for current in input:
			var current_inside = is_inside(current, edge_start, edge_end, orientation)
			var previous_inside = is_inside(previous, edge_start, edge_end, orientation)
			if current_inside:
				if not previous_inside:
					output.append(line_intersection(previous, current, edge_start, edge_end))
				output.append(current)
			elif previous_inside:
				output.append(line_intersection(previous, current, edge_start, edge_end))
			previous = current
	return output

func polygon_iou(actual_points: Array, expected_points: Array) -> float:
	var actual_area = polygon_area(actual_points)
	var expected_area = polygon_area(expected_points)
	if actual_area <= 0.0 or expected_area <= 0.0:
		return 0.0
	var intersection = clipped_polygon(actual_points, expected_points)
	if intersection.size() < 3:
		return 0.0
	var intersection_area = polygon_area(intersection)
	var union_area = actual_area + expected_area - intersection_area
	if union_area <= 0.0:
		return 0.0
	return intersection_area / union_area

func best_unmatched_iou(actual_points: Array, remaining_expected: Array, expected_lookup: Dictionary) -> Dictionary:
	var best_name := ""
	var best_iou := -1.0
	for expected_name in remaining_expected:
		var expected = expected_lookup[expected_name]
		var expected_points = transformed_points(expected["polygon"], expected["position"], expected["scale"], 0.0)
		var iou = polygon_iou(actual_points, expected_points)
		if iou > best_iou:
			best_iou = iou
			best_name = expected_name
	return {"name": best_name, "iou": best_iou}

func run_validation():
	var main_node = get_node_or_null("Main")
	if not main_node:
		fail("Main scene is missing")
		return

	var level = main_node.get_node_or_null("Level")
	if not level or not level is Node2D:
		fail("Level node must exist as a Node2D child of Main")
		return

	if level.position.distance_to(Vector2(55.5, 5.0)) > 0.5:
		fail("Level should keep the platformer image aligned to the viewport")
		return

	var sprite = level.get_node_or_null("Sprite2D")
	if not sprite or not sprite is Sprite2D:
		fail("Level must keep its Sprite2D child")
		return

	if sprite.centered:
		fail("Sprite2D should use top-left coordinates by setting centered to false")
		return

	var highlights = level.get_node_or_null("CoinHighlights")
	if not highlights or not highlights is Node2D:
		fail("Add a Node2D named CoinHighlights under Level")
		return

	var expected_lookup = expected_highlights()
	var remaining_expected: Array = expected_lookup.keys()
	for i in range(1, 7):
		var name = "CoinHighlight%d" % i
		var highlight = highlights.get_node_or_null(name)
		if not highlight or not highlight is Polygon2D:
			fail("CoinHighlights needs a Polygon2D child named %s" % name)
			return
		if highlight.color.a <= 0.0 or highlight.color.a >= 1.0:
			fail("%s should use a semi-transparent color" % name)
			return
		if highlight.polygon.size() < 8:
			fail("%s should use a circular polygon with several points" % name)
			return
		if highlight.position.x < 0 or highlight.position.x > 529 or highlight.position.y < 0 or highlight.position.y > 350:
			fail("%s must stay inside the platformer image bounds" % name)
			return
		var actual_points = transformed_points(highlight.polygon, highlight.position, highlight.scale, highlight.rotation)
		var match = best_unmatched_iou(actual_points, remaining_expected, expected_lookup)
		var iou = match["iou"]
		if iou < MIN_IOU:
			fail("%s must tightly cover one of the coins with overlap above 90%% (best IoU=%.4f)" % [name, iou])
			return
		remaining_expected.erase(match["name"])

	print("VALIDATION_PASSED: Coin highlight overlays configured for the platformer image")
	get_tree().quit(0)
