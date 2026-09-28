# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure
  - Evidence: `uv run gamedevbench validate task_0284` returns `Validation result: FAILED` with `CardStateMachine must enter CardBaseState on ready`.
- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: `uv run gamedevbench --gt validate task_0284` returns `Validation result: PASSED` with `Card dragging enters the correct states, cancels back to hand, and plays over the drop area`.
- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0284
  - Evidence: both `tasks/task_0284/scenes/main.tscn` and `tasks/task_0284/scenes/test.tscn` exist, and the same pair exists under `tasks_gt/task_0284/scenes/`.
- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - Instruction 1 / Transcript 1: the transcript says to initialize the state machine, connect each child's `transition_requested` signal, enter the initial state, and forward input to the active state while ignoring invalid transition requests.
  - Instruction 2 / Transcript 2: the transcript explicitly covers `card_ui.gd` calling `card_state_machine.init(self)`, forwarding `_input` and `_gui_input`, and maintaining `targets` from the drop-area callbacks without duplicates.
  - Instruction 3 / Transcript 3: the transcript includes the base/clicked/dragging/released flow, `original_index`, `ui_layer`, canceling to base on right click, `DRAG_MINIMUM_THRESHOLD := 0.05`, and restoring canceled drags to the hand.
  - Instructions Missing from Transcript: none that affect the task requirements.
- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: the derived implementation is present in the ground-truth copy at `tasks_gt/task_0284/scenes/card_ui/card_state_machine.gd`, `tasks_gt/task_0284/scenes/card_ui/card_ui.gd`, and `tasks_gt/task_0284/scenes/ui/hand.gd`, with the same scene/script layout as the task folder.
- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: the instruction names concrete `res://` paths, node behavior, signal flow, and exact constants; it does not refer to the tutorial or another task.
- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - Test 1, Instruction 1: the initial state and click/drag/play flow are covered.
  - Coverage: `main.tscn`/`BattleUI/Hand`, the three-card harness, the required state nodes, the `original_index` restore path, `ui_layer` reparenting, `targets` handling, and the `0.05` drag threshold are all explicitly named in the instruction and exercised by the test.
- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - For EACH test, list EVERY assertion/check it makes, then verify the instruction specifies that EXACT detail.
  - Test 1, Assertions: main scene instantiates, `BattleUI/Hand` exists, hand has 3 cards, `CardStateMachine` exists, state nodes exist, state machine enters `CardBaseState`, left click enters clicked state, clicked state records `original_index`, mouse motion enters dragging state, dragging reparents into `ui_layer`, left release before threshold is ignored, right click cancels to base, cancel restores hand parent and original slot, drop-area release after threshold removes the card and reduces hand count. The instruction specifies each of these conditions directly or by naming the exact nodes, states, and constants involved.
  - **CRITICAL AMBIGUITY CHECKS** - For each test, explicitly verify:
    - [x] String formatting (padding, delimiters, exact format) is specified in instruction
    - [x] Exact string values/names are in instruction (not just "format text")
    - [x] Number formats (zero-padding, decimal places) are specified
    - [x] Any comparison operators (==, !=, >, <, contains, begins_with, ends_with) have clear criteria
    - [x] Node names, paths, and types match instruction exactly
    - [x] Property values (numbers, booleans, strings) have exact values in instruction
  - Ambiguous Tests: no ambiguous formatting or operator usage; the remaining issue is coverage, not ambiguity.
- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: the instruction fixes the scene names, state names, signal flow, and the `0.05` drag threshold, so there is effectively one implementation path.
- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0284)
  - Evidence: the task uses the standard `scenes/`, `scripts/`, and `task_config.json` layout, and the ground-truth folder mirrors the same structure.
- [x] PROCEED. Check this box is the task is validated and all key checks pass successfully.


# Feature Checklist
- [x] The task contains instructions or goals that are Node/inspector-focused.
  - Evidence: the task is about scene tree wiring, signal connections, exported properties, groups, and inspector-driven node configuration in Godot.
- [ ] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: no direct multimodal reasoning is required beyond reading the transcript and repo files.
- [ ] The task contains a multimodal input (such as a image) in the instruction.
  - Evidence: the instruction does not include an image or other direct multimodal asset.

# Notes

Validation summary:
- Starting-point validation fails as expected.
- Ground-truth validation passes.
- The instruction, transcript, and test are aligned for the card-dragging state-machine flow, including the setup assertions around the hand, state nodes, and drag threshold.

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
    - Code: tasks/task_0284/scripts/test.gd:11-17 checks for ParallaxBackground under Main
      and a ParallaxLayer child named Ground.
- Test 2 / Instruction 2 – “Place a Sprite2D in Ground and assign the water texture asset to it.”
    - Code: tasks/task_0284/scripts/test.gd:20-24 fetches Ground/Sprite2D and asserts its
      texture ends with assets/water.tres.
- Test 3 / Instruction 3 – “Create a second ParallaxLayer named Clouds and add a Control ColorRect to render the cloud
  visuals.”
    - Code: tasks/task_0284/scripts/test.gd:27-33 ensures the ParallaxLayer named Clouds
      exists and contains a ColorRect.
- Test 4 / Instruction 4 – “Turn the Clouds ColorRect into a ShaderMaterial-driven surface using the dedicated
  clouds.gdshader.”
    - Code: tasks/task_0284/scripts/test.gd:35-40 enforces that the ColorRect’s material is a
      ShaderMaterial whose shader path ends with shaders/clouds.gdshader.
- Test 5 / Instruction 5 – “Mirror the Clouds layer with the same vector and set the ColorRect’s size to screen_max_size
  so it fills any aspect ratio.”
    - Code: tasks/task_0284/scripts/test.gd:42-58 zeroes the values, runs _process, computes
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
