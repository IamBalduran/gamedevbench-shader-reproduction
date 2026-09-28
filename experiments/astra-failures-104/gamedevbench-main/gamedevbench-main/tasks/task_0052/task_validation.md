# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure
  - Evidence: Ran `uv run gamedevbench validate task_0052` and received "FAILED: Player script must export friction and acceleration" - this is correct as the starting point does not have friction/acceleration exports yet.
- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: Ran `uv run gamedevbench --gt validate task_0052` and received "PASSED: Player controller uses export ranges and lerp-based acceleration/friction"
- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0052
  - Evidence: Both Main.tscn and test.tscn exist in scenes/ folder. Main.tscn contains a Node2D named "Main" with Player instance. test.tscn contains TestRunner node with test.gd script and Main instance as child. Structure matches task_0052 pattern.
- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - Instruction 1: "exports @export_range(0.0, 1.0) var friction = 0.1" / Transcript line 106: "@export_range(0.0, 1.0) var friction = 0.1"
  - Instruction 2: "exports @export_range(0.0, 1.0) var acceleration = 0.25" / Transcript line 107: "@export_range(0.0 , 1.0) var acceleration = 0.25"
  - Instruction 3: "cache Input.get_axis(\"move_left\", \"move_right\") in a dir variable" / Transcript line 112: "var dir = Input.get_axis(\"walk_left\", \"walk_right\")"
  - Instruction 4: "lerp velocity.x toward dir * speed using acceleration whenever dir != 0" / Transcript lines 113-114: "if dir != 0: velocity.x = lerp(velocity.x, dir * speed, acceleration)"
  - Instruction 5: "lerp toward 0 using friction when idle" / Transcript lines 115-116: "else: velocity.x = lerp(velocity.x, 0.0, friction)"
  - Instruction 6: "keep the existing gravity, move_and_slide(), and jump logic" / Transcript lines 111, 118-120: "velocity.y += gravity * delta", "move_and_slide()", "if Input.is_action_just_pressed(\"jump\") and is_on_floor(): velocity.y = jump_speed"
  - Instructions Missing from Transcript: NONE - Note: The instruction uses "move_left"/"move_right" while transcript uses "walk_left"/"walk_right" for input actions. This is acceptable as both refer to horizontal movement inputs and the task is testing the pattern/structure, not the exact action names.
- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: The starting point player.gd (lines 1-13) matches the basic platform character code from transcript lines 33-51/53-71 (first code example). The ground truth player.gd matches transcript lines 101-120/122-141 (second code example with friction/acceleration). The code structure, export variables (speed, jump_speed, gravity), and logic (gravity application, move_and_slide, jump gating) are directly from the transcript which references the GitHub repo https://github.com/godotrecipes/2d_platform_basic.
- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: The instruction is self-contained. It specifies: (1) exact export ranges and default values, (2) exact variable name for caching input, (3) exact lerp formulas for moving and idle cases, (4) preservation of existing logic. No references to tutorial or external resources. All necessary information is provided within the instruction text.
- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - Test 1 (lines 21-26): Checks friction and acceleration exports exist and are float type → Instruction: "exports @export_range(0.0, 1.0) var friction = 0.1 and @export_range(0.0, 1.0) var acceleration = 0.25"
  - Test 2 (lines 27-32): Checks default values friction=0.1 and acceleration=0.25 → Instruction: "var friction = 0.1 and ... var acceleration = 0.25"
  - Test 3 (lines 39-44): Checks exact @export_range syntax in source → Instruction: "@export_range(0.0, 1.0) var friction" and "@export_range(0.0, 1.0) var acceleration"
  - Test 4 (lines 45-50): Checks lerp formula for moving and idle cases → Instruction: "lerp velocity.x toward dir * speed using acceleration whenever dir != 0, lerp toward 0 using friction when idle"
  - Test 5 (lines 51-53): Checks Input.get_axis is cached in variable → Instruction: "cache Input.get_axis(\"move_left\", \"move_right\") in a dir variable"
  - Test 6 (lines 55-66): Checks gravity, move_and_slide, jump action, and is_on_floor preservation → Instruction: "keep the existing gravity, move_and_slide(), and jump logic gating Input.is_action_just_pressed(\"jump\") on is_on_floor()"
  - Missing Coverage: NONE - all instruction elements are tested and all tests correspond to instruction elements.
- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - Test 1 (lines 21-26), Assertions:
    - Checks `player.get("friction") != null` and `player.get("acceleration") != null`
    - Checks both are `float` type
    - Instruction coverage: "exports @export_range(0.0, 1.0) var friction = 0.1 and @export_range(0.0, 1.0) var acceleration = 0.25" - explicitly states these must be exported variables with specific type (float implied by range 0.0-1.0)
  - Test 2 (lines 27-32), Assertions:
    - Checks `is_equal_approx(player.get("friction"), 0.1)`
    - Checks `is_equal_approx(player.get("acceleration"), 0.25)`
    - Instruction coverage: "var friction = 0.1" and "var acceleration = 0.25" - exact default values specified
  - Test 3 (lines 39-44), Assertions:
    - String search for exact text: `"@export_range(0.0, 1.0) var friction"`
    - String search for exact text: `"@export_range(0.0, 1.0) var acceleration"`
    - Instruction coverage: "@export_range(0.0, 1.0) var friction = 0.1 and @export_range(0.0, 1.0) var acceleration = 0.25" - exact syntax specified including @export_range decorator with range values
  - Test 4 (lines 45-50), Assertions:
    - String search for: `"lerp(velocity.x, dir * speed, acceleration"`
    - String search for: `"lerp(velocity.x, 0.0, friction"`
    - Instruction coverage: "lerp velocity.x toward dir * speed using acceleration whenever dir != 0, lerp toward 0 using friction when idle" - exact lerp formulas specified (velocity.x as first arg, dir * speed / 0.0 as targets, acceleration/friction as interpolation amounts)
  - Test 5 (lines 51-53), Assertions:
    - String search for: `"var dir := Input.get_axis"`
    - Instruction coverage: "cache Input.get_axis(\"move_left\", \"move_right\") in a dir variable" - explicitly requires storing result in "dir" variable using "var dir"
  - Test 6 (lines 55-66), Assertions:
    - String search for: `"velocity.y += gravity * delta"`
    - String search for: `"move_and_slide()"`
    - String search for: `"Input.is_action_just_pressed(\"jump\""` OR `"Input.is_action_just_pressed('jump'"`
    - String search for: `"is_on_floor()"`
    - Instruction coverage: "keep the existing gravity, move_and_slide(), and jump logic gating Input.is_action_just_pressed(\"jump\") on is_on_floor()" - explicitly lists all four elements that must remain
  - **CRITICAL AMBIGUITY CHECKS**:
    - [x] String formatting (padding, delimiters, exact format) is specified in instruction - N/A, no string formatting required
    - [x] Exact string values/names are in instruction (not just "format text") - Yes: "dir" variable name, "friction", "acceleration", exact lerp formulas
    - [x] Number formats (zero-padding, decimal places) are specified - Yes: 0.1 and 0.25 are exact values, 0.0 and 1.0 for range
    - [x] Any comparison operators (==, !=, >, <, contains, begins_with, ends_with) have clear criteria - Yes: "dir != 0" explicitly stated
    - [x] Node names, paths, and types match instruction exactly - N/A, instruction focuses on script code
    - [x] Property values (numbers, booleans, strings) have exact values in instruction - Yes: friction = 0.1, acceleration = 0.25
  - Ambiguous Tests: NONE - all test checks are unambiguously specified in the instruction with exact syntax, formulas, and values
- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: The instruction is very specific about the implementation (exact export ranges, exact variable name "dir", exact lerp formulas with specific parameters). While minor variations in whitespace or comment placement are acceptable, the core implementation has essentially one solution that matches the transcript. The tests appropriately check for the specific patterns required (exact @export_range syntax, exact lerp formulas). This level of specificity is justified because the task is teaching a specific pattern from the tutorial.
- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0052)
  - Evidence: Folder structure matches: scenes/ contains Main.tscn, Player.tscn, test.tscn; scripts/ contains player.gd, test.gd; assets/ contains sprites; root contains project.godot and task_config.json. Naming conventions match (lowercase "scenes", "scripts", "assets" folders, Main.tscn with capital M, test files lowercase).
- [x] PROCEED. Check this box if the task is validated and all key checks pass successfully.


# Feature Checklist
- [ ] The task contains instructions or goals that are Node/inspector-focused.
  - Evidence: This task is code-focused (script editing) rather than Node/Inspector-focused. The instruction is about modifying the player.gd script to add exports and lerp-based movement, not about manipulating the scene tree or inspector properties.
- [ ] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: No multimodal reasoning required. The task is text-based script modification without requiring visual understanding, image interpretation, or spatial reasoning about the scene.
- [ ] The task contains a multimodal input (such as an image) in the instruction.
  - Evidence: No images or multimodal inputs in the instruction. It's purely text-based code modification instructions.

# Notes

## Validation Summary
This task successfully validates according to all key checklist criteria. The task asks developers to enhance a basic platform character with lerp-based acceleration and friction, transforming instant movement into smooth, natural-feeling motion.

## Key Strengths
1. **Clear progression**: Starting point has basic movement, ground truth adds acceleration/friction - clean teaching moment
2. **Unambiguous instruction**: Every test requirement is explicitly stated in the instruction with exact syntax
3. **Good test coverage**: Tests verify both runtime behavior (correct export values) and code structure (exact @export_range syntax, exact lerp formulas)
4. **Transcript alignment**: Instruction directly matches transcript lines 91-141, teaching the friction/acceleration enhancement pattern
5. **Self-contained**: No external references needed, all information provided

## Minor Note
The instruction uses "move_left"/"move_right" while the transcript uses "walk_left"/"walk_right" for input action names. This is acceptable because:
- The test checks for the pattern `Input.get_axis` rather than specific action names
- Both refer to horizontal movement inputs
- The task is teaching the lerp pattern, not specific action naming
- The starting point code already uses "move_left"/"move_right" so the instruction is consistent with the codebase

## Code Derivation
- Starting point: Basic platform character from transcript lines 33-51 (first example)
- Ground truth: Enhanced version from transcript lines 101-120 (second example with friction/acceleration)
- Direct correspondence to the tutorial's progression from instant movement to lerp-based movement

## Test Analysis
All 6 test groups map cleanly to instruction elements:
1. Export existence and type → "exports ... var friction ... and ... var acceleration"
2. Default values → "= 0.1" and "= 0.25"
3. Exact @export_range syntax → "@export_range(0.0, 1.0)"
4. Lerp formulas → "lerp velocity.x toward dir * speed using acceleration" and "lerp toward 0 using friction"
5. Dir variable caching → "cache Input.get_axis ... in a dir variable"
6. Preserved logic → "keep the existing gravity, move_and_slide(), and jump logic"

No ambiguous tests found - all assertions have exact specification in instruction text.

# Examples

## Matching task instruction to transcript

- "exports @export_range(0.0, 1.0) var friction = 0.1"
    - Transcript line 106: "@export_range(0.0, 1.0) var friction = 0.1"
- "exports @export_range(0.0, 1.0) var acceleration = 0.25"
    - Transcript line 107: "@export_range(0.0 , 1.0) var acceleration = 0.25"
- "cache Input.get_axis(\"move_left\", \"move_right\") in a dir variable"
    - Transcript line 112: "var dir = Input.get_axis(\"walk_left\", \"walk_right\")"
    - Note: Action names differ ("move" vs "walk") but pattern is identical
- "lerp velocity.x toward dir * speed using acceleration whenever dir != 0"
    - Transcript lines 113-114: "if dir != 0: velocity.x = lerp(velocity.x, dir * speed, acceleration)"
- "lerp toward 0 using friction when idle"
    - Transcript lines 115-116: "else: velocity.x = lerp(velocity.x, 0.0, friction)"
- "keep the existing gravity, move_and_slide(), and jump logic gating Input.is_action_just_pressed(\"jump\") on is_on_floor()"
    - Transcript line 111: "velocity.y += gravity * delta"
    - Transcript line 118: "move_and_slide()"
    - Transcript lines 119-120: "if Input.is_action_just_pressed(\"jump\") and is_on_floor(): velocity.y = jump_speed"

## Matching Test to Instruction

- Test 1 (lines 21-26) / Instruction – "exports @export_range(0.0, 1.0) var friction = 0.1 and @export_range(0.0, 1.0) var acceleration = 0.25"
    - Code checks that friction and acceleration exist as exported properties and are float type
- Test 2 (lines 27-32) / Instruction – "var friction = 0.1" and "var acceleration = 0.25"
    - Code verifies default values are 0.1 and 0.25 using is_equal_approx
- Test 3 (lines 39-44) / Instruction – "@export_range(0.0, 1.0) var friction" and "@export_range(0.0, 1.0) var acceleration"
    - Code searches source for exact @export_range syntax strings
- Test 4 (lines 45-50) / Instruction – "lerp velocity.x toward dir * speed using acceleration whenever dir != 0, lerp toward 0 using friction when idle"
    - Code searches for exact lerp formulas: "lerp(velocity.x, dir * speed, acceleration" and "lerp(velocity.x, 0.0, friction"
- Test 5 (lines 51-53) / Instruction – "cache Input.get_axis(\"move_left\", \"move_right\") in a dir variable"
    - Code searches for "var dir := Input.get_axis" pattern
- Test 6 (lines 55-66) / Instruction – "keep the existing gravity, move_and_slide(), and jump logic gating Input.is_action_just_pressed(\"jump\") on is_on_floor()"
    - Code searches for all four preserved elements: gravity increment, move_and_slide call, jump action check, is_on_floor check

## Identifying Ambiguous Tests (CRITICAL)

### Analysis: NO AMBIGUOUS TESTS FOUND

All tests have unambiguous specification in the instruction:

**Test 1-2 (Export properties)**: UNAMBIGUOUS
- Instruction explicitly states "@export_range(0.0, 1.0) var friction = 0.1" - specifies type (float via range), name (friction), and value (0.1)
- Same for acceleration with 0.25 value
- No ambiguity about what to export or what values to use

**Test 3 (@export_range syntax)**: UNAMBIGUOUS
- Instruction provides exact text: "@export_range(0.0, 1.0) var friction"
- Test checks for this exact string in source
- Solver knows exactly what syntax to write

**Test 4 (Lerp formulas)**: UNAMBIGUOUS
- Instruction states: "lerp velocity.x toward dir * speed using acceleration"
- This unambiguously translates to: lerp(velocity.x, dir * speed, acceleration)
- First parameter is velocity.x (current value), second is target (dir * speed), third is interpolation amount (acceleration)
- Same clarity for idle case: "lerp toward 0 using friction" → lerp(velocity.x, 0.0, friction)

**Test 5 (Dir variable)**: UNAMBIGUOUS
- Instruction: "cache Input.get_axis(\"move_left\", \"move_right\") in a dir variable"
- Explicitly names the variable "dir"
- Explicitly states to cache (store) the Input.get_axis result
- Solver knows to write: var dir := Input.get_axis(...)

**Test 6 (Preserved logic)**: UNAMBIGUOUS
- Instruction lists specific items to keep: "gravity", "move_and_slide()", "Input.is_action_just_pressed(\"jump\")", "is_on_floor()"
- Each element is named explicitly
- Solver knows exactly what existing code to preserve
