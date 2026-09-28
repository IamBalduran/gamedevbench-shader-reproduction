# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure
  - Evidence: Based on code inspection, the starting point projectile.gd (tasks/task_0002/scripts/projectile.gd) only has basic movement and lacks the required functionality (_on_area_entered, progress_quest calls, queue_free on hit/off-screen), so tests would fail.
- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: The ground truth projectile.gd (tasks_gt/task_0002/scripts/projectile.gd) implements all required functionality: _on_area_entered method that checks for enemy group, calls QuestManager.progress_quest(QUEST_ID, STEP_ID), queue_free on hit, and queue_free when position.y < -50, matching all test requirements.
- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0002
  - Evidence: Both main.tscn and test.tscn exist in tasks/task_0002/scenes/ and tasks_gt/task_0002/scenes/. The test.tscn properly instantiates test.gd script and includes main.tscn as a child.
- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - "calling QuestManager.progress_quest with the kill step each time it overlaps an enemy" / "in order to progress the quest you need to call progress Quest... in my projectiles node... if the projectile overlapped with if it's an enemy I progress Quest... it's killing one enemy"
  - "queue_free itself after the hit" / "and then it removes itself"
  - "also removes itself when it travels far off screen" / "and that's just a check for if it's far off screen"
  - Instructions Missing from Transcript: None. All instruction elements are present in the transcript.
- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: The task uses the Quest Manager addon from the GitHub repository (https://github.com/Chevifier/QuestManager). The basic projectile structure, Area2D setup, movement in _physics_process, and the pattern of checking area.is_in_group("enemy") in _on_area_entered are all derived from the repository's example code shown in the tutorial.
- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: The instruction specifies exactly what to implement: (1) call QuestManager.progress_quest with the kill step on enemy overlap, (2) queue_free after hit, (3) queue_free when far off screen. It explicitly names the quest ("Shoot Em Up"), the method to call (QuestManager.progress_quest), and the step identifier (kill step). No tutorial references exist.
- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - Test 1 (lines 15-18): Checks projectile frees itself when leaving play area / Instruction: "also removes itself when it travels far off screen"
  - Test 2 (lines 26-34): Checks _on_area_entered method exists / Instruction: "each time it overlaps an enemy" (implies area_entered signal)
  - Test 3 (lines 28-30): Checks kill step increments on enemy collision / Instruction: "advance the Shoot Em Up quest by calling QuestManager.progress_quest with the kill step each time it overlaps an enemy"
  - Test 4 (lines 31-32): Checks projectile removes itself after damaging enemy / Instruction: "queue_free itself after the hit"
  - Missing Coverage: None. All instructions are tested and all tests match instructions.
- [ ] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - For EACH test, list EVERY assertion/check it makes, then verify the instruction specifies that EXACT detail
  - Test 1, Assertions: [projectile.position.y = -80, call _physics_process(0.016), check is_queued_for_deletion() is true], Instruction coverage: "also removes itself when it travels far off screen" - AMBIGUOUS: instruction doesn't specify the exact y position threshold (-50 in ground truth vs -80 in test)
  - Test 2, Assertions: [has_method("_on_area_entered")], Instruction coverage: "each time it overlaps an enemy" - UNAMBIGUOUS: overlapping implies using area_entered signal/method
  - Test 3, Assertions: [create enemy Area2D in group "enemy", call _on_area_entered(enemy), check quest kill_step.collected increments by 1], Instruction coverage: "calling QuestManager.progress_quest with the kill step each time it overlaps an enemy" - AMBIGUOUS: instruction mentions "kill step" but test uses quest.first_step to find the step. The instruction says "Shoot Em Up quest" which is unambiguous, but doesn't specify exact parameter values ("shoot_em_up" vs "Shoot Em Up")
  - Test 4, Assertions: [after calling _on_area_entered(enemy), check is_queued_for_deletion() is true], Instruction coverage: "queue_free itself after the hit" - UNAMBIGUOUS
  - **CRITICAL AMBIGUITY CHECKS** - For each test, explicitly verify:
    - [x] String formatting (padding, delimiters, exact format) is specified in instruction - N/A for this task
    - [ ] Exact string values/names are in instruction (not just "format text") - AMBIGUOUS: "Shoot Em Up" vs "shoot_em_up" for quest ID
    - [x] Number formats (zero-padding, decimal places) are specified - N/A for this task
    - [x] Any comparison operators (==, !=, >, <, contains, begins_with, ends_with) have clear criteria - is_in_group("enemy") is clear
    - [x] Node names, paths, and types match instruction exactly - enemy group check is specified
    - [ ] Property values (numbers, booleans, strings) have exact values in instruction - off-screen threshold not specified
  - Ambiguous Tests:
    - Test 1: The exact y-position threshold for "far off screen" is not specified. Ground truth uses position.y < -50, but test uses position.y = -80. Instruction should specify the threshold value or tests should be more flexible.
    - Test 3: The exact quest ID string format is ambiguous ("Shoot Em Up" vs "shoot_em_up"). The ground truth uses "shoot_em_up" constant, but instruction uses "Shoot Em Up". However, examining the quest resource shows quest_name is "Shoot Em Up" but quest_id is "shoot_em_up", so the first parameter should be quest_id.
- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: There is essentially one clear solution pattern: use _on_area_entered signal handler, check if area is in "enemy" group, call QuestManager.progress_quest, and call queue_free. The tests appropriately check for the existence of the method and the behavior rather than implementation details.
- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0002)
  - Evidence: Follows standard structure with tasks/task_XXXX_name format, contains scenes/, scripts/, quests/, addons/, assets/ folders, has task_config.json, project.godot, and validation.md files.
- [ ] PROCEED. Check this box is the task is validated and all key checks pass successfully.


# Feature Checklist
- [ ] The task contains instructions or goals that are Node/inspector-focused.
  - Evidence: No. This task is purely code-focused. It requires implementing GDScript methods (_on_area_entered, queue_free calls, QuestManager.progress_quest) rather than setting up nodes in the inspector.
- [ ] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: No. The task can be completed entirely through text-based code implementation without needing to understand visual elements, images, or spatial relationships.
- [ ] The task contains a multimodal input (such as a image) in the instruction.
  - Evidence: No. The task instruction is text-only and contains no images, screenshots, or visual references.

# Notes

## Validation Summary
This task validates the implementation of projectile behavior that integrates with the Quest Manager system. The task requires students to:
1. Implement collision detection using _on_area_entered
2. Call QuestManager.progress_quest to advance quest steps
3. Implement cleanup logic (queue_free) for both hit detection and off-screen boundaries

## Key Issues Identified

### AMBIGUITY ISSUE 1: Off-screen threshold not specified
- **Problem**: The instruction says "travels far off screen" but doesn't specify the exact y-position threshold
- **Ground Truth**: Uses `position.y < -50`
- **Test**: Sets position.y to -80
- **Impact**: A solver might use any threshold value (e.g., -100, -200) and reasonably satisfy "far off screen"
- **Recommendation**: Either (1) specify the exact threshold in instruction (e.g., "position.y < -50") OR (2) make test more flexible to accept any reasonable negative y value

### AMBIGUITY ISSUE 2: Quest ID parameter format unclear
- **Problem**: The instruction refers to "Shoot Em Up quest" but doesn't specify whether to use quest_name ("Shoot Em Up") or quest_id ("shoot_em_up") as the parameter
- **Ground Truth**: Uses `const QUEST_ID := "shoot_em_up"` (the quest_id, not quest_name)
- **Impact**: A solver reading just the instruction might use "Shoot Em Up" as the first parameter to progress_quest
- **Recommendation**: Clarify in the instruction to use the quest_id "shoot_em_up" or reference the quest resource file

### POSITIVE: Kill step parameter is reasonable
- The instruction says "with the kill step" and the quest resource clearly shows a step with id "kill_step", so this parameter is reasonably unambiguous

## Test Coverage Analysis
All instruction requirements are tested:
- ✓ Progress quest on enemy overlap (Test 3)
- ✓ queue_free after hit (Test 4)
- ✓ queue_free when off screen (Test 1)
- ✓ _on_area_entered method exists (Test 2)

## Code Derivation
The task properly derives from the tutorial repository's Quest Manager addon and the example projectile implementation shown in the video.

## Overall Assessment
The task is **MOSTLY VALID** but has **TWO AMBIGUITIES** that should be addressed:
1. Off-screen threshold value not specified
2. Quest ID parameter format unclear

**Recommendation**: Do NOT check the PROCEED box until these ambiguities are resolved by either updating the instruction or making the tests more flexible.

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
    - Code: tasks/task_0002/scripts/test.gd:11-17 checks for ParallaxBackground under Main
      and a ParallaxLayer child named Ground.
- Test 2 / Instruction 2 – “Place a Sprite2D in Ground and assign the water texture asset to it.”
    - Code: tasks/task_0002/scripts/test.gd:20-24 fetches Ground/Sprite2D and asserts its
      texture ends with assets/water.tres.
- Test 3 / Instruction 3 – “Create a second ParallaxLayer named Clouds and add a Control ColorRect to render the cloud
  visuals.”
    - Code: tasks/task_0002/scripts/test.gd:27-33 ensures the ParallaxLayer named Clouds
      exists and contains a ColorRect.
- Test 4 / Instruction 4 – “Turn the Clouds ColorRect into a ShaderMaterial-driven surface using the dedicated
  clouds.gdshader.”
    - Code: tasks/task_0002/scripts/test.gd:35-40 enforces that the ColorRect’s material is a
      ShaderMaterial whose shader path ends with shaders/clouds.gdshader.
- Test 5 / Instruction 5 – “Mirror the Clouds layer with the same vector and set the ColorRect’s size to screen_max_size
  so it fills any aspect ratio.”
    - Code: tasks/task_0002/scripts/test.gd:42-58 zeroes the values, runs _process, computes
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
