# Variant Summary

- Base task: `task_0206`
- Variant task: `task_0212`
- Starting scene intentionally perturbs `Sprite2D.rotation` and `Sprite2D.scale`
- Solver work: restore the sprite transform, add `SpawningPoints`, create `SpawnTop` and `SpawnBot`, align one marker with the bottom tip of the branch closest to the water and the other with the rightmost bottom tip of the trunk, and set `SpawnBot.z_index = 1`
