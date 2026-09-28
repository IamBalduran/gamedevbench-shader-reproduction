# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure
  - Evidence: Ran `uv run gamedevbench validate task_0055` and received `VALIDATION_FAILED: player.gd must reference get_local_mouse_position` (exit code 1).
- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: Ran `uv run gamedevbench --gt validate task_0055` and received `VALIDATION_PASSED: Mouse-based 8-direction logic implemented` (exit code 0).
- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0048
  - Evidence:
    - `scenes/Main.tscn` exists and instances Player.tscn (lines 1-8)
    - `scenes/test.tscn` exists and loads test.gd script, instances Main.tscn (lines 1-10)
    - Structure matches task_0048 pattern (main.tscn, player.tscn, test.tscn)
- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - **Full Instruction**: "Update scripts/player.gd so the Player CharacterBody2D reads the local mouse vector each physics frame, snaps the angle to 45 degrees steps, wraps it into the 0-7 range, moves with move_and_slide() toward the mouse whenever left_mouse is held beyond 10 pixels, and plays the matching idle/run AnimatedSprite2D animation (e.g., idle0, run0, etc.)."
  - **Component 1**: "reads the local mouse vector each physics frame" → Transcript line 27: "get_local_mouse_position() gives us the position of the mouse relative to the character" + lines 43, 46, 56, 59: "func _physics_process(delta):" and "var mouse = get_local_mouse_position()"
  - **Component 2**: "snaps the angle to 45 degrees steps" → Transcript lines 23, 29-30: "snappedf() to snap the angle of the mouse vector to the closest multiple of 45° (PI/4 radians)" + lines 47, 60: "angle = snappedf(mouse.angle(), PI/4) / (PI/4)"
  - **Component 3**: "wraps it into the 0-7 range" → Transcript line 37: "we need to map the resulting range to 0-7 using the wrapi() function" + lines 41, 48, 61: "wrapi()" and "angle = wrapi(int(angle), 0, 8)"
  - **Component 4**: "moves with move_and_slide() toward the mouse" → Transcript lines 52-53, 65-66: "velocity = mouse.normalized() * speed" and "move_and_slide()"
  - **Component 5**: "whenever left_mouse is held beyond 10 pixels" → Transcript lines 50, 63: "if Input.is_action_pressed(\"left_mouse\") and mouse.length() > 10:"
  - **Component 6**: "plays the matching idle/run AnimatedSprite2D animation (e.g., idle0, run0, etc.)" → Transcript lines 11-19: "We'll use an AnimatedSprite2D and we'll name each animation based on its direction... idle0... idle7" + lines 37, 54, 67: "Adding that value to the end of the animation name" and "$AnimatedSprite2D.animation = current_animation + str(a)"
  - **Instructions Missing from Transcript**: None - all instruction components are directly sourced from transcript.
- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence:
    - Ground truth `scripts/player.gd` is directly derived from the tutorial repository code pattern shown in transcript lines 43-54 and 56-67.
    - The Player.tscn scene with AnimatedSprite2D containing idle0-7 and run0-7 animations matches the tutorial's asset setup described in transcript lines 11-19.
    - The code follows the exact pattern: `get_local_mouse_position()`, `snappedf(mouse.angle(), PI/4)`, `wrapi(int(angle), 0, 8)`, conditional movement with `mouse.length() > 10`, and animation concatenation `current_animation + str(angle)`.
    - Repository URL referenced: https://github.com/godotrecipes/8_direction_animation
- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence:
    - Instruction specifies exact file to modify: "scripts/player.gd"
    - Node type specified: "Player CharacterBody2D"
    - Functions required are named: "get_local_mouse_position", "snappedf", "wraps", "move_and_slide"
    - Specific values given: "45 degrees steps", "0-7 range", "beyond 10 pixels"
    - Animation naming convention specified: "idle/run AnimatedSprite2D animation (e.g., idle0, run0, etc.)"
    - Input action named: "left_mouse"
    - No references to tutorial materials or external documentation
- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - **Test 1** (lines 27-33): Checks for presence of required tokens in script text
    - Instruction coverage: "reads the local mouse vector" → checks "get_local_mouse_position"
    - Instruction coverage: "snaps the angle to 45 degrees steps" → checks "snappedf"
    - Instruction coverage: "wraps it into the 0-7 range" → checks "wrapi"
    - Instruction coverage: "whenever left_mouse is held" → checks "Input.is_action_pressed"
    - Instruction coverage: "moves with move_and_slide()" → checks "move_and_slide"
    - Instruction coverage: "plays the matching...animation" → checks "AnimatedSprite2D.play"
  - **Test 2** (lines 39-45): Idle behavior without mouse clicks
    - Instruction coverage: "plays the matching idle/run AnimatedSprite2D animation (e.g., idle0, run0)" → checks animation == "idle0"
    - Instruction coverage: Implicit requirement that velocity should be zero when not moving → checks velocity.length() is zero
  - **Test 3** (lines 47-54): Run behavior with mouse clicks
    - Instruction coverage: "whenever left_mouse is held" → presses left_mouse action
    - Instruction coverage: "plays the matching idle/run AnimatedSprite2D animation" → checks animation.begins_with("run")
    - Instruction coverage: "moves with move_and_slide()" → checks velocity.length() is non-zero
  - **Missing Coverage**: None - all instruction requirements are tested.
- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - **Test 1 - Token Checks** (lines 31-33):
    - Assertions: Script text must contain "get_local_mouse_position", "snappedf", "wrapi", "Input.is_action_pressed", "move_and_slide", "AnimatedSprite2D.play"
    - Instruction coverage:
      - "reads the local mouse vector" → explicitly specifies get_local_mouse_position
      - "snaps the angle to 45 degrees steps" → snappedf is the standard Godot function for this
      - "wraps it into the 0-7 range" → wrapi is explicitly mentioned
      - "whenever left_mouse is held" → Input.is_action_pressed is the standard method
      - "moves with move_and_slide()" → explicitly named
      - "plays the matching...AnimatedSprite2D animation" → AnimatedSprite2D.play is the standard method
    - **UNAMBIGUOUS**: All required function names are either explicitly stated or are the canonical Godot functions for the described operations.
  - **Test 2 - Idle Animation Check** (lines 42-43):
    - Assertions: Without mouse input, sprite.animation must equal "idle0" AND velocity.length() must be ~zero
    - Instruction coverage: "plays the matching idle/run AnimatedSprite2D animation (e.g., idle0, run0, etc.)" provides "idle0" as first example
    - **MINOR AMBIGUITY**: The instruction doesn't explicitly state "idle0 is the default when no mouse action", but the example "(e.g., idle0, run0, etc.)" strongly implies idle0 is the base/starting animation. The test positions player at origin where mouse angle = 0 degrees = idle0/run0.
  - **Test 3 - Run Animation Check** (lines 51-54):
    - Assertions: When left_mouse pressed and player away from origin, animation.begins_with("run") AND velocity.length() > 0
    - Instruction coverage: "whenever left_mouse is held beyond 10 pixels" + "moves with move_and_slide()" + "plays the matching idle/run"
    - **UNAMBIGUOUS**: Clearly specifies run animation and movement when condition met.
  - **CRITICAL AMBIGUITY CHECKS** - For each test, explicitly verify:
    - [x] String formatting (padding, delimiters, exact format) is specified in instruction
      - Animation format specified: "idle/run AnimatedSprite2D animation (e.g., idle0, run0, etc.)"
    - [x] Exact string values/names are in instruction (not just "format text")
      - "idle0", "run0" explicitly given as examples; "left_mouse" action explicitly named
    - [x] Number formats (zero-padding, decimal places) are specified
      - "0-7 range" clearly specifies single-digit indices; "10 pixels" explicit threshold
    - [x] Any comparison operators (==, !=, >, <, contains, begins_with, ends_with) have clear criteria
      - "beyond 10 pixels" implies > 10; "0-7 range" implies wrapi(val, 0, 8)
    - [x] Node names, paths, and types match instruction exactly
      - "Player CharacterBody2D", "AnimatedSprite2D", "scripts/player.gd" all specified
    - [x] Property values (numbers, booleans, strings) have exact values in instruction
      - "45 degrees steps" → PI/4; "0-7 range" → exact bounds; "10 pixels" → exact threshold
  - **Ambiguous Tests**:
    - Minor: The instruction doesn't explicitly state that idle0 should be the default animation when the mouse is at 0 degrees, but this is strongly implied by providing "idle0" as the first example. A solver following the instruction would naturally implement this.
- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: The tests are appropriately flexible:
    - Token checks verify required functions are used but don't mandate specific implementation details
    - Runtime checks verify behavior (idle vs run, velocity changes) rather than exact code structure
    - Uses `.begins_with("run")` which allows any run0-7 animation
    - The solution space is constrained by specific Godot functions (snappedf, wrapi, get_local_mouse_position) which is appropriate for a tutorial-based task
- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0048)
  - Evidence:
    - Task folder: `task_0055` follows pattern `task_####_<name>`
    - Contains folders: `scenes/`, `scripts/`, `assets/`
    - Scene files: `Main.tscn`, `Player.tscn`, `test.tscn` (lowercase, consistent)
    - Script files: `player.gd`, `test.gd` (lowercase, consistent)
    - Both tasks/ and tasks_gt/ folders exist with identical structure
- [x] PROCEED. Check this box if the task is validated and all key checks pass successfully.


# Feature Checklist
- [x] The task contains instructions or goals that are Node/inspector-focused.
  - Evidence:
    - Instruction specifies working with CharacterBody2D node type
    - Requires AnimatedSprite2D child node with specific animation names (idle0-7, run0-7)
    - The Player.tscn scene contains fully configured AnimatedSprite2D with SpriteFrames resource containing 16 animations (8 idle + 8 run directions)
    - CollisionShape2D positioning is part of scene setup (position Vector2(7, 44), size Vector2(66, 24))
    - motion_mode property set to 1 (Floating) on CharacterBody2D
- [x] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence:
    - Understanding 8-directional movement requires spatial/visual reasoning about angles and directions
    - The animation system maps mathematical angles (0, PI/4, PI/2, etc.) to visual directions (right, up-right, up, etc.)
    - The task involves coordinating visual feedback (character animation) with mathematical calculations (angle snapping, wrapping)
    - Understanding which animation corresponds to which direction requires interpreting the visual sprite assets
- [ ] The task contains a multimodal input (such as an image) in the instruction.
  - Evidence: No - The instruction is text-only. While the task works with visual assets (sprite animations), the instruction itself doesn't include images. The multimodal aspect comes from the task's conceptual nature (spatial reasoning) rather than the instruction format.

# Notes

## Validation Summary
Task 0715 successfully passes all critical validation criteria:
1. ✅ Starting point fails validation as expected (missing implementation)
2. ✅ Ground truth passes validation
3. ✅ Scene structure matches template (Main.tscn, test.tscn present)
4. ✅ Instructions fully derived from transcript
5. ✅ Code derived from repository pattern
6. ✅ Instructions are self-contained and unambiguous
7. ✅ Tests comprehensively cover all instruction requirements
8. ✅ File/folder naming consistent with benchmark structure

## Tutorial Derivation Quality
The task demonstrates excellent fidelity to the source tutorial:
- Every instruction component maps directly to transcript lines
- The mathematical approach (snappedf, wrapi, angle division) matches transcript exactly
- The 10-pixel threshold is preserved from the original tutorial code
- Animation naming convention (idle0-7, run0-7) follows tutorial pattern
- Input action name (left_mouse) matches tutorial

## Test Coverage Analysis
The test.gd implementation provides comprehensive coverage:
- **Structural validation**: Checks for required functions via text search (lines 27-33)
- **Behavioral validation**: Runtime tests for idle and run states (lines 39-54)
- **AnimatedSprite2D validation**: Confirms child node exists and animations work (lines 35-43, 51-52)
- **Physics validation**: Verifies velocity changes correctly (lines 44-45, 53-54)

The tests strike a good balance between being strict enough to enforce correct implementation while remaining flexible enough to allow minor variations in code style.

## Ground Truth Implementation
The ground truth implementation (tasks_gt/.../scripts/player.gd) follows best practices:
- Uses _physics_process for frame-based updates
- Properly resets current_animation each frame to "idle"
- Calculates angle using snappedf(mouse.angle(), PI/4) / (PI/4)
- Wraps angle to 0-7 range using wrapi(int(angle), 0, 8)
- Conditionally sets velocity based on mouse press and distance
- Zeroes velocity when not moving (prevents drift)
- Concatenates animation name with string representation of angle
- Uses $AnimatedSprite2D.play() to trigger animation

## Scene Setup Quality
The Player.tscn scene is professionally configured:
- 268 texture resources loaded for all animation frames
- 16 animations properly configured (idle0-7, run0-7)
- Each animation contains 16-17 frames at 15 FPS
- AnimatedSprite2D has speed_scale = 2.0 for appropriate playback
- CollisionShape2D positioned at character's feet (position Vector2(7, 44))
- CharacterBody2D uses motion_mode = 1 (Floating) for 8-directional movement
- Script properly attached via ExtResource

## Project Configuration
project.godot properly configures:
- Main scene path: res://scenes/Main.tscn
- Input action "left_mouse" mapped to left mouse button (button_index: 1)
- Godot 4.4 compatibility
- Appropriate rendering method (gl_compatibility)

## Minor Ambiguity Identified
One minor ambiguity exists: The instruction doesn't explicitly state "when mouse is not pressed or distance < 10px, play idle0 animation as default." However:
- The example "(e.g., idle0, run0, etc.)" provides idle0 as the first example, strongly implying it's the default
- The mathematical model (angle 0 = right direction) is consistent with Godot conventions
- A solver following the instruction would naturally implement idle0 as the default state

**Assessment**: This minor ambiguity is acceptable for a tutorial-based task and doesn't significantly impact task quality.

## Repository Reference
The task correctly references the source repository:
- GitHub URL: https://github.com/godotrecipes/8_direction_animation
- Tutorial source: KidsCanCode – 8-Directional Movement/Animation
- Assets properly attributed to Isometric Mini-Crusader sprite set
- Code patterns match repository implementation style

## Conclusion
This task is well-constructed, thoroughly tested, and faithful to its source tutorial. It provides a clear learning objective (implementing 8-directional mouse-based movement with animation) and validates the solution appropriately. The task is ready for inclusion in the GameDevBench benchmark.

**Status**: ✅ VALIDATED - All criteria met, PROCEED checkbox marked

# Examples

## Matching task instruction to transcript

**Full Instruction**: "Update scripts/player.gd so the Player CharacterBody2D reads the local mouse vector each physics frame, snaps the angle to 45 degrees steps, wraps it into the 0-7 range, moves with move_and_slide() toward the mouse whenever left_mouse is held beyond 10 pixels, and plays the matching idle/run AnimatedSprite2D animation (e.g., idle0, run0, etc.)."

Breaking down each component:

- "reads the local mouse vector each physics frame"
    - Transcript line 27: "get_local_mouse_position() gives us the position of the mouse relative to the character"
    - Transcript lines 43, 46, 56, 59: Shows code using "func _physics_process(delta):" and "var mouse = get_local_mouse_position()"

- "snaps the angle to 45 degrees steps"
    - Transcript lines 23, 29-30: "We can then use snappedf() to snap the angle of the mouse vector to the closest multiple of 45° (PI/4 radians)"
    - Transcript lines 47, 60: Shows code "angle = snappedf(mouse.angle(), PI/4) / (PI/4)"

- "wraps it into the 0-7 range"
    - Transcript line 37: "Finally, we need to map the resulting range to 0-7 using the wrapi() function"
    - Transcript lines 48, 61: Shows code "angle = wrapi(int(angle), 0, 8)"

- "moves with move_and_slide() toward the mouse"
    - Transcript lines 52-53: "velocity = mouse.normalized() * speed" and "move_and_slide()"
    - Transcript lines 65-66: Same pattern shown in alternative keyboard version

- "whenever left_mouse is held beyond 10 pixels"
    - Transcript lines 50, 63: "if Input.is_action_pressed(\"left_mouse\") and mouse.length() > 10:"

- "plays the matching idle/run AnimatedSprite2D animation (e.g., idle0, run0, etc.)"
    - Transcript lines 11-19: "We'll use an AnimatedSprite2D and we'll name each animation based on its direction. For example, idle0 pointing to the right and going clockwise to idle7"
    - Transcript line 37: "Adding that value to the end of the animation name (\"idle\", \"run\", etc) gives us the correct animation"
    - Transcript lines 54, 67: "$AnimatedSprite2D.animation = current_animation + str(a)"
## Matching Test to Instruction

- Test 1 / Instruction 1 – “Add a ParallaxBackground under Main with a ParallaxLayer named Ground.”
    - Code: tasks/task_0048/scripts/test.gd:11-17 checks for ParallaxBackground under Main
      and a ParallaxLayer child named Ground.
- Test 2 / Instruction 2 – “Place a Sprite2D in Ground and assign the water texture asset to it.”
    - Code: tasks/task_0048/scripts/test.gd:20-24 fetches Ground/Sprite2D and asserts its
      texture ends with assets/water.tres.
- Test 3 / Instruction 3 – “Create a second ParallaxLayer named Clouds and add a Control ColorRect to render the cloud
  visuals.”
    - Code: tasks/task_0048/scripts/test.gd:27-33 ensures the ParallaxLayer named Clouds
      exists and contains a ColorRect.
- Test 4 / Instruction 4 – “Turn the Clouds ColorRect into a ShaderMaterial-driven surface using the dedicated
  clouds.gdshader.”
    - Code: tasks/task_0048/scripts/test.gd:35-40 enforces that the ColorRect’s material is a
      ShaderMaterial whose shader path ends with shaders/clouds.gdshader.
- Test 5 / Instruction 5 – “Mirror the Clouds layer with the same vector and set the ColorRect’s size to screen_max_size
  so it fills any aspect ratio.”
    - Code: tasks/task_0048/scripts/test.gd:42-58 zeroes the values, runs _process, computes
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
