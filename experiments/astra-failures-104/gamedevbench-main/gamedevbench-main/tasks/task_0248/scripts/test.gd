extends Node

const IMAGE_SIZE := Vector2(1610, 980)
const MIN_IOU := 0.85

func _ready():
	run_validation()

func fail(message: String) -> void:
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit(1)

func expected_gemstone_highlight() -> Dictionary:
	return {
		"position": Vector2(1481.5385, 648.4616),
		"scale": Vector2.ONE,
		"rotation": 3.1415927,
		"polygon": [
			Vector2(0, -26),
			Vector2(18, -6),
			Vector2(9.230713, 3.0769653),
			Vector2(-9.230835, 3.0769653),
			Vector2(-17.117798, -5.5893555),
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

	if level.position.distance_to(Vector2(118.631, 56.766)) > 0.5:
		fail("Level should keep the platformer image aligned to the viewport")
		return

	if level.scale.distance_to(Vector2(0.64, 0.64)) > 0.02:
		fail("Level should keep the platformer image at scale Vector2(0.64, 0.64)")
		return

	if abs(level.rotation - -0.02) > 0.02:
		fail("Level should keep the platformer image at rotation -0.02")
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

	var highlights = level.get_node_or_null("GemstoneHighlights")
	if not highlights or not highlights is Node2D:
		fail("Add a Node2D named GemstoneHighlights under Level")
		return

	var highlight = highlights.get_node_or_null("GemstoneHighlight")
	if not highlight or not highlight is Polygon2D:
		fail("GemstoneHighlights needs a Polygon2D child named GemstoneHighlight")
		return

	var effective_alpha = highlight.color.a * highlight.modulate.a
	if effective_alpha <= 0.0 or effective_alpha >= 1.0:
		fail("GemstoneHighlight should use a semi-transparent color or modulate")
		return

	var effective_r = highlight.color.r * highlight.modulate.r
	var effective_g = highlight.color.g * highlight.modulate.g
	var effective_b = highlight.color.b * highlight.modulate.b
	if effective_r < 0.35 or effective_r > 1.0 or effective_g < 0.05 or effective_g > 0.75 or effective_b < 0.45 or effective_b > 1.0 or effective_b <= effective_g:
		fail("GemstoneHighlight should use a purple or pink-purple tint")
		return

	if highlight.polygon.size() < 4:
		fail("GemstoneHighlight should use a polygon with several points")
		return

	if highlight.position.x < 0.0 or highlight.position.x > IMAGE_SIZE.x or highlight.position.y < 0.0 or highlight.position.y > IMAGE_SIZE.y:
		fail("GemstoneHighlight must stay inside the platformer image bounds")
		return

	var expected = expected_gemstone_highlight()
	var actual_points = transformed_points(highlight.polygon, highlight.position, highlight.scale, highlight.rotation)
	var expected_points = transformed_points(expected["polygon"], expected["position"], expected["scale"], expected["rotation"])
	var iou = polygon_iou(actual_points, expected_points)
	if iou < MIN_IOU:
		fail("GemstoneHighlight must cover the gemstone with overlap above 85%% (IoU=%.4f)" % iou)
		return

	print("VALIDATION_PASSED: Gemstone highlight correctly covers the gemstone collectible")
	get_tree().quit(0)
