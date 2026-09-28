# Variant Summary

- Task family: `task_6022*` star-highlight placement
- Scene setup: `Level.position = Vector2(53, 5.5)`, `Level.scale = Vector2(0.65, 0.65)`, `Level.rotation = 0`
- Asset: `Sprite2D` uses `assets/sprites/platformer_coins.jpg` with top-left anchoring via `centered = false`
- Validation target: one `Polygon2D` star highlight under `Level/StarHighlights`
- Success condition: the submitted polygon must overlap the frozen ground-truth star polygon with IoU greater than `0.85`
