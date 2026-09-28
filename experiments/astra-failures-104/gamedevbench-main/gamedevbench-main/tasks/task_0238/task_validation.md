# Variant Summary

- Task family: `task_6022*` gemstone-highlight placement
- Variant task: `task_0238`
- Scene setup: `Level.position = Vector2(53, 5.5)`, `Level.scale = Vector2(0.65, 0.65)`, `Level.rotation = 0`
- Asset: `Sprite2D` uses `assets/sprites/platformer_coins.jpg` with top-left anchoring via `centered = false`
- Validation target: one `Polygon2D` gemstone highlight under `Level/GemstoneHighlights`
- Success condition: the submitted polygon must overlap the frozen ground-truth gemstone polygon with IoU greater than `0.85`
