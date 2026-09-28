extends Node

const IMAGE_SIZE := Vector2(1610, 980)
const MIN_IOU := 0.85

func _ready():
	run_validation()

func fail(message: String) -> void:
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit(1)

func expected_star_highlight() -> Dictionary:
	return {
		"position": Vector2(1003.077, 76.15385),
		"scale": Vector2.ONE,
		"rotation": 0.0,
		"polygon": [
			Vector2(0.00012207031, -20.000015),
			Vector2(7.692383, -10.769241),
			Vector2(18.461426, -6.153839),
			Vector2(12.307617, 3.0769196),
			Vector2(10.769409, 16.923073),
			Vector2(-0.00012207031, 12.3076935),
			Vector2(-10.769043, 15.384613),
			Vector2(-12.307861, 3.0769196),
			Vector2(-19.999878, -6.1538467),
			Vector2(-7.6921387, -10.769241),
		],
	}

func transformed_points(points, position: Vector2, scale: Vector2, rotation: float) -> Array:
	var transformed: Array = []
	for point in points:
		var local_point = Vector2(point.x * scale.x, point.y * scale.y).rotated(rotation)
		transformed.append(local_point + position)
	return transformed

func point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside := false
	var j := polygon.size() - 1
	for i in range(polygon.size()):
		var pi: Vector2 = polygon[i]
		var pj: Vector2 = polygon[j]
		var intersects = ((pi.y > point.y) != (pj.y > point.y))
		if intersects:
			var denom = pj.y - pi.y
			if abs(denom) < 0.000001:
				denom = 0.000001
			var x_intersect = (pj.x - pi.x) * (point.y - pi.y) / denom + pi.x
			if point.x < x_intersect:
				inside = not inside
		j = i
	return inside

func polygon_iou(actual_points: Array, expected_points: Array) -> float:
	if actual_points.size() < 3 or expected_points.size() < 3:
		return 0.0

	var min_x = min(actual_points[0].x, expected_points[0].x)
	var min_y = min(actual_points[0].y, expected_points[0].y)
	var max_x = max(actual_points[0].x, expected_points[0].x)
	var max_y = max(actual_points[0].y, expected_points[0].y)

	for point in actual_points:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)

	for point in expected_points:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)

	var intersection := 0
	var union := 0
	for y in range(int(floor(min_y)) - 1, int(ceil(max_y)) + 1):
		for x in range(int(floor(min_x)) - 1, int(ceil(max_x)) + 1):
			var sample = Vector2(x + 0.5, y + 0.5)
			var in_actual = point_in_polygon(sample, actual_points)
			var in_expected = point_in_polygon(sample, expected_points)
			if in_actual or in_expected:
				union += 1
				if in_actual and in_expected:
					intersection += 1

	if union == 0:
		return 0.0
	return float(intersection) / float(union)

func run_validation():
	var main_node = get_node_or_null("Main")
	if not main_node:
		fail("Main scene is missing")
		return

	var level = main_node.get_node_or_null("Level")
	if not level or not level is Node2D:
		fail("Level node must exist as a Node2D child of Main")
		return

	if level.position.distance_to(Vector2(173.749, 180.879)) > 0.5:
		fail("Level should keep the platformer image aligned to the viewport")
		return

	if level.scale.distance_to(Vector2(0.53, 0.53)) > 0.02:
		fail("Level should keep the platformer image at scale Vector2(0.53, 0.53)")
		return

	if abs(level.rotation - -0.18) > 0.02:
		fail("Level should keep the platformer image at rotation -0.18")
		return

	var sprite = level.get_node_or_null("Sprite2D")
	if not sprite or not sprite is Sprite2D:
		fail("Level must keep its Sprite2D child")
		return

	if sprite.texture == null or not sprite.texture.resource_path.ends_with("platformer_coins.jpg"):
		fail("Sprite2D must use assets/sprites/platformer_coins.jpg")
		return

	if sprite.centered:
		fail("Sprite2D should use top-left coordinates by setting centered to false")
		return

	var highlights = level.get_node_or_null("StarHighlights")
	if not highlights or not highlights is Node2D:
		fail("Add a Node2D named StarHighlights under Level")
		return

	var highlight = highlights.get_node_or_null("StarHighlight")
	if not highlight or not highlight is Polygon2D:
		fail("StarHighlights needs a Polygon2D child named StarHighlight")
		return

	var effective_alpha = highlight.color.a * highlight.modulate.a
	if effective_alpha <= 0.0 or effective_alpha >= 1.0:
		fail("StarHighlight should use a semi-transparent color or modulate")
		return

	if highlight.polygon.size() < 10:
		fail("StarHighlight should use a star-like polygon with several points")
		return

	if highlight.position.x < 0.0 or highlight.position.x > IMAGE_SIZE.x or highlight.position.y < 0.0 or highlight.position.y > IMAGE_SIZE.y:
		fail("StarHighlight must stay inside the platformer image bounds")
		return

	var expected = expected_star_highlight()
	var actual_points = transformed_points(highlight.polygon, highlight.position, highlight.scale, highlight.rotation)
	var expected_points = transformed_points(expected["polygon"], expected["position"], expected["scale"], expected["rotation"])
	var iou = polygon_iou(actual_points, expected_points)
	if iou < MIN_IOU:
		fail("StarHighlight must cover the star with overlap above 85%% (IoU=%.4f)" % iou)
		return

	print("VALIDATION_PASSED: Star highlight correctly covers the star collectible")
	get_tree().quit(0)
