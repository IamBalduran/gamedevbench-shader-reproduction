# Key Checklist
- [ ] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure
  - Evidence: Unable to run validation command due to environment setup issues (uv package installation hanging). However, code analysis shows starting point is missing required functionality:
    - steer_component.gd:6-21 does not populate debug dictionary when debug_enabled is true
    - steer_component.gd:27-28 has empty _process() function, missing queue_redraw() call
    - Based on test.gd:22-54, these missing features would cause validation failures
- [ ] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: Unable to run validation command due to environment setup issues. However, code analysis shows ground truth has all required functionality:
    - tasks_gt/task_0034/scripts/steer_component.gd:22-27 properly captures debug data
    - tasks_gt/task_0034/scripts/steer_component.gd:36 has queue_redraw() call
    - All test assertions in scripts/test.gd would pass with this implementation
- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0034
  - Evidence: Verified both files exist:
    - tasks/task_0034/scenes/main.tscn exists
    - tasks/task_0034/scenes/test.tscn exists
    - tasks_gt/task_0034/scenes/main.tscn exists
    - tasks_gt/task_0034/scenes/test.tscn exists
- [ ] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - Evidence: Tutorial folder not found in repository. The task_config.json indicates tutorial_folder: "tutorials/Cashew OldDew/Debug Visually in Godot 4.2" but this folder does not exist.
  - The task_config.json contains a transcript_excerpt: "add the forces the points and whatever else you want to visualize in a dictionary... make sure you redraw at every frame in your process function with Q redraw"
  - This excerpt aligns with the task instruction about capturing debug data and calling queue_redraw()
  - Unable to fully validate against complete transcript
- [ ] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: Unable to verify - tutorial repository folder not found in this repository. The task_config.json references github_repo: "https://github.com/cashew-olddew/godot-tutorials"
  - The steer_component.gd appears to be a simplified steering behavior implementation with debug support
  - Cannot confirm direct derivation without access to source repository
- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: Instruction from task_config.json: "Inside the SteerComponent script, capture the current velocity, scaled desired velocity, and steering force in a debug dictionary whenever debugging is enabled, and queue a redraw every frame so the overlay can update."
  - This instruction is self-contained with no references to tutorials or other tasks
  - It clearly specifies what to do (capture data in debug dictionary, queue redraw)
  - It specifies where (SteerComponent script)
  - It specifies when (whenever debugging is enabled, every frame)
- [ ] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - Test 1 (scripts/test.gd:7-17): Verifies node structure (Main -> Fish -> SteerComponent) - NOT in instruction
  - Test 2 (scripts/test.gd:19-20): Verifies steer() method exists - Implicit in instruction (says "inside SteerComponent script")
  - Test 3 (scripts/test.gd:22-42): Calls steer() and verifies return value - NOT directly in instruction (instruction doesn't specify what steer() should return)
  - Test 4 (scripts/test.gd:44-54): Verifies debug dictionary has "velocity", "scaled_desired_velocity", "steer" keys with correct values - MATCHES instruction ("capture the current velocity, scaled desired velocity, and steering force in a debug dictionary")
  - Test 5 (scripts/test.gd:56-58): Verifies queue_redraw() exists in source code - MATCHES instruction ("queue a redraw every frame")
  - Missing Coverage: The instruction says "queue a redraw every frame" but test only checks if queue_redraw() appears in source, not if it's called in _process() specifically
- [ ] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - Test Assertions:
    - Check 1 (line 45-47): Verifies debug dictionary contains keys "velocity", "scaled_desired_velocity", "steer"
      - Instruction: "capture the current velocity, scaled desired velocity, and steering force in a debug dictionary"
      - Coverage: AMBIGUOUS - instruction says "steering force" but test checks for key named "steer", not "steering_force"
    - Check 2 (line 49-50): Verifies debug["velocity"] equals the velocity parameter
      - Instruction: "capture the current velocity"
      - Coverage: UNAMBIGUOUS - clearly specifies capturing velocity
    - Check 3 (line 51-52): Verifies debug["scaled_desired_velocity"] equals calculated scaled value
      - Instruction: "scaled desired velocity"
      - Coverage: AMBIGUOUS - instruction doesn't define what "scaled desired velocity" means or how to calculate it. Solver must infer from existing steer() function code
    - Check 4 (line 53-54): Verifies debug["steer"] equals steering adjustment
      - Instruction: "steering force"
      - Coverage: AMBIGUOUS - instruction says "steering force" but test expects "steer" as key name. Also unclear what "steering force" means - is it the adjustment or the final result?
    - Check 5 (line 56-58): Searches source code for "queue_redraw"
      - Instruction: "queue a redraw every frame so the overlay can update"
      - Coverage: PARTIAL - instruction says "every frame" but test doesn't verify it's in _process(), just that the text exists
  - **CRITICAL AMBIGUITY CHECKS**:
    - [ ] String formatting - N/A (no string formatting required)
    - [ ] Exact string values/names - FAIL: Instruction says "steering force" but test expects "steer" as dictionary key
    - [ ] Number formats - N/A (uses vector comparison with tolerance)
    - [x] Comparison operators - Uses _vectors_close() with tolerance, appropriate for Vector2
    - [ ] Node names, paths, and types - NOT in instruction (test checks for Main/Fish/SteerComponent but instruction doesn't mention this)
    - [ ] Property values - FAIL: "scaled_desired_velocity" calculation not defined in instruction
  - Ambiguous Tests:
    1. Dictionary key names not exact: "steering force" (instruction) vs "steer" (test)
    2. "scaled_desired_velocity" calculation not defined in instruction
    3. queue_redraw() location not specified (should be in _process but test only checks file content)
    4. Node structure not mentioned in instruction
- [ ] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: FAILS - There is only one expected solution, but it is NOT clearly decipherable from instructions due to:
    1. Dictionary key name ambiguity ("steering force" vs "steer")
    2. Missing definition of "scaled_desired_velocity" calculation
    3. No specification that queue_redraw() must be in _process()
    4. Solver must examine existing steer() function code to understand calculations
- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0034)
  - Evidence: Folder structure follows standard pattern:
    - tasks/task_0034/
    - tasks_gt/task_0034/
    - Contains: scenes/, scripts/, assets/, project.godot, task_config.json
- [ ] PROCEED. Check this box is the task is validated and all key checks pass successfully.


# Feature Checklist
- [ ] The task contains instructions or goals that are Node/inspector-focused.
  - Evidence: No - This task is purely code-focused. The instruction requires modifying the SteerComponent script to add debug data capture and queue_redraw() calls. No inspector or node configuration required.
- [ ] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: No - This is a code-only task. No visual analysis or multimodal understanding needed.
- [ ] The task contains a multimodal input (such as a image) in the instruction.
  - Evidence: No - The task instruction is text-only.

# Notes

## Summary of Validation

This task has significant validation issues that prevent it from passing the validation criteria:

### Critical Issues:
1. **Ambiguous Dictionary Key Names**: The instruction says "steering force" but the test expects a key named "steer". A solver following the instruction literally might use "steering_force" as the key name and fail the test.

2. **Missing Calculation Definitions**: The instruction mentions "scaled desired velocity" and "steering force" but doesn't define what these values are or how to calculate them. A solver must examine the existing steer() function code to understand these calculations, which contradicts the principle that instructions should be self-contained.

3. **Missing Tutorial Resources**: The tutorial folder referenced in task_config.json does not exist in the repository, making it impossible to verify if the task instruction matches the tutorial transcript or if the code derives from the tutorial repository.

4. **Incomplete queue_redraw() Specification**: The instruction says "queue a redraw every frame" but doesn't explicitly state this should be in the _process() function. The test only checks if "queue_redraw" text appears in the file, not where it's called.

### What Works:
- File and folder structure is correct
- main.tscn and test.tscn exist in both starting point and ground truth
- The instruction is self-contained (no references to other tasks or tutorials)
- The general concept is clear (capture debug data and redraw)

### Recommendations to Fix:
1. Update instruction to specify exact dictionary key names:
   - "capture the current velocity (key: 'velocity'), scaled desired velocity (key: 'scaled_desired_velocity'), and steering force (key: 'steer') in a debug dictionary"

2. Add calculation definitions to instruction or reference the existing steer() function:
   - "Use the velocity parameter, the scaled_desired_velocity calculated in steer(), and the steering_adjustment before returning"

3. Specify where queue_redraw() should be called:
   - "In the _process() function, call queue_redraw() every frame"

4. Either:
   - Add the tutorial folder to the repository, OR
   - Update task_config.json to reflect that tutorial resources are not available

## Code Analysis

### Starting Point (tasks/task_0034/scripts/steer_component.gd):
- Has debug_enabled variable and empty debug dictionary (lines 3-4)
- Has steer() function that calculates steering (lines 6-21)
- Has update_debug() helper function (lines 23-25)
- Has empty _process() function (lines 27-28)
- Has empty _draw() function (lines 30-31)
- MISSING: Code to populate debug dictionary when debug_enabled is true
- MISSING: queue_redraw() call in _process()

### Ground Truth (tasks_gt/task_0034/scripts/steer_component.gd):
- Same structure as starting point but with required additions:
- Lines 22-27: Captures debug data when debug_enabled is true:
  ```gdscript
  if debug_enabled:
      update_debug({
          "velocity": velocity,
          "scaled_desired_velocity": scaled_desired_velocity,
          "steer": steering_adjustment
      })
  ```
- Line 36: Calls queue_redraw() in _process():
  ```gdscript
  func _process(_delta: float) -> void:
      queue_redraw()
  ```

### Test File (tasks/task_0034/scripts/test.gd):
- Tests node structure (Main -> Fish -> SteerComponent)
- Tests steer() method existence and return value
- Tests debug dictionary contains correct keys and values
- Tests source code contains "queue_redraw" text

The test is well-structured but the instruction doesn't provide enough detail for a solver to pass it without examining the existing code.

# Examples

## Matching task instruction to transcript

- Add a ParallaxBackground under Main with a ParallaxLayer named Ground.
    - “here what I'm going to do under main create a new parallx parallx background and here under it create a parallx
      layer let's call it ground”
- Place a Sprite2D in Ground and assign the water texture asset to it.
    - “under it we are going to have a Sprite Tod which can stay Sprite Tod and we're going to drag our water texture
      now you can see it appearing”
- Create a second ParallaxLayer named Clouds and add a Control ColorRect to render the cloud visuals.
    - “go to our parallx background add another Parallax layer which will be clouds that's right and here under it we're
      going to add a wrecked from the control node”
- Turn the Clouds ColorRect into a ShaderMaterial-driven surface using the dedicated clouds.gdshader.
    - “go to our color wct and here we are going to do some things so what we're going to do is go to material and add a
      new Shader material … let's create a new Shader which will be let's say clouds. GD Shader”
- Mirror the Clouds layer with the same vector and set the ColorRect’s size to screen_max_size
  so it fills any aspect ratio.
    - “clouds. motion mirror equals to Vector 2 screen size and screen size screen Max size … it's not going to be scale
      but rather size of it and the size will simply be uh screen Max size and uh screen Max size”
## Matching Test to Instruction

- Test 1 / Instruction 1 – “Add a ParallaxBackground under Main with a ParallaxLayer named Ground.”
    - Code: tasks/task_0034/scripts/test.gd:11-17 checks for ParallaxBackground under Main
      and a ParallaxLayer child named Ground.
- Test 2 / Instruction 2 – “Place a Sprite2D in Ground and assign the water texture asset to it.”
    - Code: tasks/task_0034/scripts/test.gd:20-24 fetches Ground/Sprite2D and asserts its
      texture ends with assets/water.tres.
- Test 3 / Instruction 3 – “Create a second ParallaxLayer named Clouds and add a Control ColorRect to render the cloud
  visuals.”
    - Code: tasks/task_0034/scripts/test.gd:27-33 ensures the ParallaxLayer named Clouds
      exists and contains a ColorRect.
- Test 4 / Instruction 4 – “Turn the Clouds ColorRect into a ShaderMaterial-driven surface using the dedicated
  clouds.gdshader.”
    - Code: tasks/task_0034/scripts/test.gd:35-40 enforces that the ColorRect’s material is a
      ShaderMaterial whose shader path ends with shaders/clouds.gdshader.
- Test 5 / Instruction 5 – “Mirror the Clouds layer with the same vector and set the ColorRect’s size to screen_max_size
  so it fills any aspect ratio.”
    - Code: tasks/task_0034/scripts/test.gd:42-58 zeroes the values, runs _process, computes
      screen_max_size, and asserts both Clouds.motion_mirroring and ColorRect.size match Vector2(screen_max_size,
      screen_max_size).
## Identifying Ambiguous Tests (CRITICAL)

### Example 1: AMBIGUOUS - Vague formatting requirement

**Instruction**: "Format incremental and timer step text"

**Test Code**:
```gdscript
var expected_text = "Destroy 5 ships 00/05"
if do_label.text != expected_text:
    issues.append("Initial incremental text should be '%s'" % expected_text)
```

**Assertions**:
- Checks text equals exactly "Destroy 5 ships 00/05"
- Requires zero-padded format (%02d)
- Requires specific spacing and no delimiters

**Why AMBIGUOUS**: Instruction says "format text" but doesn't specify:
- Zero-padding (00 vs 0)
- Exact delimiter (/ vs out of vs :)
- Spacing
- Format string structure

**How to fix**: Change instruction to: "Format incremental step text as '{details} {collected:02d}/{required:02d}'" OR make test flexible to accept any reasonable format.

### Example 2: UNAMBIGUOUS - Specific requirement

**Instruction**: "Set the ColorRect size to Vector2(screen_max_size, screen_max_size)"

**Test Code**:
```gdscript
var expected_size = Vector2(screen_max_size, screen_max_size)
assert(color_rect.size == expected_size)
```

**Assertions**:
- Checks size equals Vector2(screen_max_size, screen_max_size)

**Why UNAMBIGUOUS**: Instruction explicitly states the exact Vector2 formula to use. No ambiguity about what value is expected.

### Example 3: AMBIGUOUS - Missing specific values

**Instruction**: "Connect to QuestManager signals"

**Test Code**:
```gdscript
var required_signals = ["step_updated", "step_complete", "quest_completed", "quest_failed"]
for signal_name in required_signals:
    if not _has_connection(qm, signal_name, quest_ui):
        issues.append("Must connect to QuestManager.%s" % signal_name)
```

**Why AMBIGUOUS**: Instruction says "signals" (plural, vague) but test checks for 4 specific signal names. A solver might connect only 2 signals and technically satisfy "connect to signals".

**How to fix**: Change instruction to: "Connect to QuestManager signals: step_updated, step_complete, quest_completed, and quest_failed"
