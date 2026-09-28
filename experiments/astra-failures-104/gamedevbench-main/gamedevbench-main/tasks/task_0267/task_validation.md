# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure
  - Evidence: Running `uv run gamedevbench validate task_0267` returned `Validation result: FAILED` with `Message: Create res://custom_nodes/detect_range.gd`.
- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: Running `uv run gamedevbench --gt validate task_0267` returned `Validation result: PASSED` with `Message: DetectRange and TargetFinder choose and track nearby enemy units`.
- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0267
  - Evidence: Both task roots contain `scenes/main.tscn` and `scenes/test.tscn`. `scenes/test.tscn` instances `res://scenes/main.tscn` as `Main`, matching the standard pattern.
- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - Instruction 1 / Transcript 1: Define `TARGET = { Team.PLAYER: "enemy_units", Team.ENEMY: "player_units" }`.
  - Transcript evidence: "We'll also add a new dictionary where the keys will use the team enum ... and the values ... will be the group name of the opposing group. So for the player team it will be enemy units ... for the enemy team it will be the player units."
  - Instruction 2 / Transcript 2: Create `DetectRange` as an `Area2D` that dynamically sizes a `CircleShape2D` from `base_range_size * attack_range`.
  - Transcript evidence: "One of it is called detect range. This will be an area 2D which dynamically creates a collision shape based on the auto attack range of the unit."
  - Instruction 3 / Transcript 3: Set `DetectRange` collision layer to `4 * (stats.team + 1)` and collision mask to `2 - stats.team`.
  - Transcript evidence: The detect-range implementation section describes configuring the range area from team-specific layers and masks before testing the purple range circles.
  - Instruction 4 / Transcript 4: Create `TargetFinder` with an `actor`, `target`, `targets_in_range`, and `targets_in_range_changed`.
  - Transcript evidence: "We'll have this custom node called target finder, which is capable of finding the closest available target to the unit and also keeps track of all the targets that are in range for that specific unit."
  - Instruction 5 / Transcript 5: Connect `DetectRange.area_entered` and `area_exited`, append and erase only `BattleUnit`s, and emit `targets_in_range_changed`.
  - Transcript evidence: "When an area enters the detect area ... we'll append that battle unit to an array and emit the signal ... when an area exits ... remove that unit from the targets in range array ... and emit the signal."
  - Instruction 6 / Transcript 6: Implement `find_target()` with `UnitStats.TARGET`, `get_nodes_in_group()`, and `distance_squared_to()` to choose the closest opposing unit.
  - Transcript evidence: "We grab all the possible targets ... calculate the distances ... find the index of the closest target among these ... and set it to the target."
  - Instruction 7 / Transcript 7: Implement `has_target_in_range()` to return whether `targets_in_range` is non-empty.
  - Transcript evidence: "We'll have another method ... has target in range ... it returns true if the size of the targets in range now ... is greater than zero."
  - Instruction 8 / Transcript 8: Add `DetectRange` and `TargetFinder` to `battle_unit.tscn`, wire them to the battle unit, and expose them in `battle_unit.gd`.
  - Transcript evidence: "We'll have this detect range ... and the target finder nodes or components added to this battle unit scene." Also: "For the target finder, we need to assign the export variable to the battle unit ... provide an onready variable reference to the target finder."
  - Instructions Missing from Transcript: None. The task omits unrelated tutorial content like hitbox/hurtbox and health/mana bars, but every included instruction is supported by transcript evidence.
- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: Ground-truth code is directly adapted from `origin/season2_episode_06` of `https://github.com/guladam/godot_autobattler_course`.
  - `tasks_gt/task_0267/custom_nodes/detect_range.gd` mirrors repo `custom_nodes/detect_range.gd`.
  - `tasks_gt/task_0267/custom_nodes/target_finder.gd` mirrors repo `custom_nodes/target_finder.gd`.
  - `tasks_gt/task_0267/data/units/unit_stats.gd` keeps the repo `Team`, `TARGET`, and `MAX_ATTACK_RANGE` targeting subset from repo `data/units/unit_stats.gd`.
  - `tasks_gt/task_0267/scenes/battle_unit/battle_unit.gd` and `scenes/battle_unit/battle_unit.tscn` mirror the repo battle-unit wiring after scoping away unrelated health, mana, and hurtbox logic.
- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: `task_config.json` names every required file path, node name, signal name, constant value, collision formula, and runtime behavior directly inside the instruction. It does not reference the YouTube video, transcript, tests, or any other task.
- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - Test 1, Instruction 1: `scripts/test.gd:28-30` requires `res://custom_nodes/detect_range.gd` and `res://custom_nodes/target_finder.gd`; covered by the instruction sentence that explicitly says to create both files.
  - Test 2, Instruction 2: `scripts/test.gd:33-39` checks `UnitStats.TARGET` exists and maps `Team.PLAYER` to `enemy_units` and `Team.ENEMY` to `player_units`; covered by the instruction sentence that defines the exact dictionary.
  - Test 3, Instruction 3: `scripts/test.gd:50-66` checks for a `DetectRange` child, `base_range_size == 36.0`, collision layer `4`, collision mask `2`, a `CollisionShape2D` child, a `CircleShape2D`, and radius `72.0`; covered by the instruction sentence naming the node, child, exact exported values, exact formulas, and the `CircleShape2D` radius formula.
  - Test 4, Instruction 4: `scripts/test.gd:68-77` checks for a `TargetFinder` child, `find_target()`, `has_target_in_range()`, and `battle_unit.gd` onready exposure as `detect_range` and `target_finder`; covered by the instruction sentence naming the `TargetFinder` node, required methods, and exact property names in `battle_unit.gd`.
  - Test 5, Instruction 5: `scripts/test.gd:80-90` checks that `targets_in_range` is an array, `has_target_in_range()` becomes true, only `EnemyUnitNear` is present initially, and `targets_in_range_changed` fires on entry; covered by the instruction sentence saying to append and erase only `BattleUnit`s and emit `targets_in_range_changed`, plus the `has_target_in_range()` sentence.
  - Test 6, Instruction 6: `scripts/test.gd:93-100` checks that `find_target()` first chooses `EnemyUnitNear`, then switches to `EnemyUnitFar` after it moves closer; covered by the instruction sentence that `find_target()` must use `get_nodes_in_group()` plus `distance_squared_to()` to store the closest opposing `BattleUnit`.
  - Test 7, Instruction 7: `scripts/test.gd:103-110` checks that `has_target_in_range()` becomes false, `targets_in_range` becomes empty, and `targets_in_range_changed` fires on exit after both enemies move away; covered by the instruction sentences for `has_target_in_range()` and enter/exit array maintenance plus signal emission.
  - Missing Coverage: None. Every test check is spelled out in the instruction. No test adjustment is needed.
- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - For EACH test, list EVERY assertion/check it makes, then verify the instruction specifies that EXACT detail
  - Test 1, Assertions: `custom_nodes/detect_range.gd` exists, `custom_nodes/target_finder.gd` exists. Instruction coverage: "Create `res://custom_nodes/detect_range.gd` ..." and "Create `res://custom_nodes/target_finder.gd` ...".
  - Test 2, Assertions: `UnitStats.TARGET` exists, `TARGET[Team.PLAYER] == "enemy_units"`, `TARGET[Team.ENEMY] == "player_units"`. Instruction coverage: "define `TARGET = { Team.PLAYER: "enemy_units", Team.ENEMY: "player_units" }`".
  - Test 3, Assertions: `PlayerUnit` has `DetectRange`; `base_range_size == 36.0`; collision layer uses `4 * (stats.team + 1)`; collision mask uses `2 - stats.team`; `DetectRange` has a `CollisionShape2D` child; that child uses a `CircleShape2D`; radius equals `base_range_size * stats.attack_range`, which is `72.0` for the provided player stats. Instruction coverage: the DetectRange sentence specifies the exact node path, exported properties, formulas, and shape type.
  - Test 4, Assertions: `PlayerUnit` has `TargetFinder`; `find_target()` exists; `has_target_in_range()` exists; `battle_unit.gd` exposes `detect_range`; `battle_unit.gd` exposes `target_finder`. Instruction coverage: the TargetFinder sentence names the node, methods, and exact onready variable names.
  - Test 5, Assertions: `targets_in_range` is an array; one enemy starts in range; `has_target_in_range()` is true; `targets_in_range_changed` emits on enter. Instruction coverage: the instruction requires `targets_in_range: Array[BattleUnit]`, the `has_target_in_range()` boolean method, and append/erase handlers that emit `targets_in_range_changed`.
  - Test 6, Assertions: `find_target()` picks the closest enemy at start and updates to a different enemy after positions change. Instruction coverage: the instruction explicitly says `find_target()` must use `distance_squared_to()` to store the closest opposing `BattleUnit` in `target`.
  - Test 7, Assertions: when enemies leave range, `has_target_in_range()` is false, `targets_in_range` is empty, and `targets_in_range_changed` emits again. Instruction coverage: the instruction explicitly says the exit handler must erase `BattleUnit`s from `targets_in_range`, emit `targets_in_range_changed`, and `has_target_in_range()` must report whether the array is non-empty.
  - **CRITICAL AMBIGUITY CHECKS** - For each test, explicitly verify:
    - [x] String formatting (padding, delimiters, exact format) is specified in instruction
    - [x] Exact string values/names are in instruction (not just "format text")
    - [x] Number formats (zero-padding, decimal places) are specified
    - [x] Any comparison operators (==, !=, >, <, contains, begins_with, ends_with) have clear criteria
    - [x] Node names, paths, and types match instruction exactly
    - [x] Property values (numbers, booleans, strings) have exact values in instruction
  - Ambiguous Tests: None.
- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: This task intentionally fixes the implementation contract to the repo-derived solution: exact file paths, node names, constant values, layer/mask formulas, signal name, and closest-target behavior. It is effectively a single-solution task, and that solution is fully decipherable from the instruction without consulting the tests.
- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0267)
  - Evidence: Both task roots follow the standard structure with `project.godot`, `task_config.json`, `custom_nodes/`, `data/`, `scenes/`, and `scripts/`. The task folder name follows `task_<ID>_<name>`, and `scenes/test.tscn` plus `scripts/test.gd` use the standard validator naming convention.
- [x] PROCEED. Check this box is the task is validated and all key checks pass successfully.


# Feature Checklist
- [ ] The task contains instructions or goals that are Node/inspector-focused. 
  - Evidence: The task includes some node wiring in `battle_unit.tscn`, but the core work is scripting and runtime behavior rather than inspector-only editing.
- [ ] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: The task is code-and-scene based only. It does not depend on interpreting screenshots, textures, or visual differences.
- [ ] The task contains a multimodal input (such as a image) in the instruction.
  - Evidence: No image or other multimodal input is referenced in the instruction.

# Notes

- Validation commands executed successfully after copying `task_config.json` into both task roots:
  - `uv run gamedevbench validate task_0267`
  - `uv run gamedevbench --gt validate task_0267`
- Starting-point files intentionally remove the tutorial feature:
  - `tasks/task_0267/data/units/unit_stats.gd` omits `TARGET`
  - `tasks/task_0267/scenes/battle_unit/battle_unit.tscn` omits `DetectRange` and `TargetFinder`
  - `tasks/task_0267/scenes/battle_unit/battle_unit.gd` omits `detect_range`, `target_finder`, and `detect_range.stats = stats`
- Ground truth restores the repo-derived feature:
  - `tasks_gt/task_0267/custom_nodes/detect_range.gd`
  - `tasks_gt/task_0267/custom_nodes/target_finder.gd`
  - `tasks_gt/task_0267/scenes/battle_unit/battle_unit.tscn`
  - `tasks_gt/task_0267/scenes/battle_unit/battle_unit.gd`
  - `tasks_gt/task_0267/data/units/unit_stats.gd`

# Examples

## Matching task instruction to transcript

- Define `TARGET = { Team.PLAYER: "enemy_units", Team.ENEMY: "player_units" }`.
    - "We'll also add a new dictionary where the keys will use the team enum ... for the player team it will be enemy units ... for the enemy team it will be player units."
- Create `DetectRange` as an `Area2D` that dynamically creates a `CircleShape2D` radius from the unit's attack range.
    - "One of it is called detect range. This will be an area 2D which dynamically creates a collision shape based on the auto attack range of the unit."
- Make `TargetFinder` keep `targets_in_range`, emit a change signal, and pick the closest opposing unit.
    - "Target finder ... keeps track of all the targets that are in range" and "find the closest available target to the unit."

## Matching Test to Instruction

- Test 1 / Instruction 1
    - `scripts/test.gd:28-30` requires the two repo-derived script files to exist.
- Test 2 / Instruction 2
    - `scripts/test.gd:33-39` checks the exact `TARGET` mapping values.
- Test 3 / Instruction 3
    - `scripts/test.gd:50-66` checks the exact DetectRange node wiring, collision formulas, and circle radius.
- Test 4 / Instruction 4
    - `scripts/test.gd:68-77` checks the exact TargetFinder node and onready property names.
- Test 5 / Instruction 5
    - `scripts/test.gd:80-90` checks the range-entry array and signal behavior.
- Test 6 / Instruction 6
    - `scripts/test.gd:93-100` checks closest-target selection before and after moving an enemy.
- Test 7 / Instruction 7
    - `scripts/test.gd:103-110` checks exit handling, empty range state, and additional signal emission.
