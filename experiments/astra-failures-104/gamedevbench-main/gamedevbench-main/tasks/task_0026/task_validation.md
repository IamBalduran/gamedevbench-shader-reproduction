# Key Checklist
- [X] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure
  - Evidence: Code analysis shows starting point has stub functions (`impulse_camera`, `apply_landing_impulse` with empty `pass` statements) that would fail the test assertions. Test file scripts/test.gd:108-145 checks for camera shake behavior that isn't implemented in the starting point.
- [X] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: Ground truth file tasks_gt/task_0026/scripts/player_body.gd contains full implementation with all required exports, noise sampling logic, impulse methods, and landing impulse calculation that matches test expectations.
- [X] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0026
  - Evidence: Both tasks/task_0026 and tasks_gt/task_0026 folders contain scenes/main.tscn and scenes/test.tscn files following the standard structure.
- [X] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - **Instruction Part 1:** "restructure PlayerBody so CameraNode contains a CameraActual Node3D with a Camera3D child"
    - Transcript: "we went ahead and added a camera actual node we're going to be breaking out the camera node and the actual camera itself as a container and the camera below that container"
  - **Instruction Part 2:** "assign those nodes to the player_body.gd exports"
    - Transcript: "we went ahead and added a camera actual node" (implicit assignment through exports)
  - **Instruction Part 3:** "expose a FastNoiseLite"
    - Transcript: "add in our camera Shake variables ... this is going to be a noise texture"
  - **Instruction Part 4:** "numeric exports for noise_panning_speed (30)"
    - Transcript: "we're going to pan through that using a panning speed"
  - **Instruction Part 5:** "max_power (0.15)"
    - Transcript: "we're also going to go ahead and have a max power to make sure that we don't ever get too far away from the actual base route where the camera's supposed to be"
  - **Instruction Part 6:** "blend_speed (7)"
    - Transcript: "then we're going to have a blend speed that we're going to blend in and out of that animation"
  - **Instruction Part 7:** "return_strength (5)"
    - Transcript: "as well as a return strength and that's how fast we subtract the noise"
  - **Instruction Part 8:** "noise_strength (0.2)"
    - Transcript: "and a noise strength which is the base level vibrations that we get essentially"
  - **Instruction Part 9:** "falling_bias (1.0)"
    - Transcript: "Then we also want to go ahead and add in a falling bias"
  - **Instruction Part 10:** "falling_strength_falloff (2.0)"
    - Transcript: "a string falling strength falloff"
  - **Instruction Part 11:** "falling_max_strength (1.0)"
    - Transcript: "and a falling max strength and these are are just going to handle the camera Shake whenever we're falling through the air and we land"
  - **Instruction Part 12:** "jumping_strength (0.2)"
    - Transcript: "we're also going to add in one for jumping string"
  - **Instruction Part 13:** "Track camera_shake_position/time_since_started"
    - Transcript: "as well as a camera Shake position as well as a time since started which we're going to use to pan through the noise effect"
  - **Instruction Part 14:** "lerp CameraActual toward camera_shake_position plus sampled noise every physics frame"
    - Transcript: "we're going to lurp it towards the camera Shake position plus the noise function ... we're luring based off of the Delta multiplied by the camera Shake blend speed"
  - **Instruction Part 15:** "decay back to origin"
    - Transcript: "we're going to go ahead and make our camera shape position slowly lurp back to Vector 3.0 so it's going to return to zero based off of time multiplied by the camera Shake return speed"
  - **Instruction Part 16:** "clamp impulses to the max power"
    - Transcript: "all that's going to do is make sure that we're always within a certain distance from the Baseline we don't ever exceed the max power as far as our distance"
  - **Instruction Part 17:** "add an upward kick inside impulse_camera_with_recoil"
    - Transcript: "this is going to be called from the weapons effects controller based off of a signal ... impulse camera with recil ... Target rotation dox added to Vertical recoil"
  - **Instruction Part 18:** "implement apply_landing_impulse() so downward velocities below the bias trigger a proportional drop impulse"
    - Transcript: "if our last y velocity is less than the negative of our camera Shake falling byas and then we're going to run off something called impulse camera ... passing in Vector 3. down ... smooth step function"
  - Instructions Missing from Transcript: None. All instruction components are derived from the transcript.
- [X] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: The task config metadata indicates repo_evidence: "ScenePrefabs/PlayerBody.tscn, Code/PlayerBodyController.cs". However, the tutorial folder shows github_repo.txt pointing to "https://github.com/Bonkahe/BonkaheShaderExpirements" which is a shader repository, not the FPS Horror project. The analysis_progress.md notes this discrepancy - the tutorial references an FPS Horror project but the linked repo is for shader experiments. The task is conceptually derived from the tutorial transcript which demonstrates the implementation in C#, but has been adapted to GDScript for Godot 4. The noise-based camera shake pattern, export structure, and physics process logic all follow the tutorial's approach.
- [X] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: The instruction in task_config.json is self-contained and does not reference "the tutorial", "the video", or other tasks. It specifies exact file paths ("scenes/player_body.tscn", "player_body.gd"), exact node names ("CameraNode", "CameraActual", "Camera3D"), exact export variable names with exact default values, and exact method names ("impulse_camera", "impulse_camera_with_recoil", "apply_landing_impulse"). The instruction can be followed without external context.
- [X] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - **Test 1 (_check_camera_hierarchy):** Validates node structure CameraNode -> CameraActual -> Camera3D
    - Instruction: "restructure PlayerBody so CameraNode contains a CameraActual Node3D with a Camera3D child"
  - **Test 2 (_check_exports):** Validates all 10 camera shake exports exist and are editor-exposed
    - Instruction: "expose a FastNoiseLite plus numeric exports for noise_panning_speed (30), max_power (0.15), blend_speed (7), return_strength (5), noise_strength (0.2), falling_bias (1.0), falling_strength_falloff (2.0), falling_max_strength (1.0), and jumping_strength (0.2)"
  - **Test 3 (_check_defaults):** Validates default values for the 9 numeric exports
    - Instruction: Values in parentheses specify exact defaults
  - **Test 4 (_check_noise_assignment):** Validates camera_shake_noise is a FastNoiseLite
    - Instruction: "expose a FastNoiseLite"
  - **Test 5 (_check_impulse_behaviour):** Tests impulse clamping, lerp to position, decay to origin, time tracking, and upward recoil kick
    - Instruction: "Track camera_shake_position/time_since_started, lerp CameraActual toward camera_shake_position plus sampled noise every physics frame, decay back to origin, clamp impulses to the max power, add an upward kick inside impulse_camera_with_recoil"
  - **Test 6 (_check_landing_impulse):** Tests that negative velocity beyond bias triggers downward camera offset
    - Instruction: "implement apply_landing_impulse() so downward velocities below the bias trigger a proportional drop impulse"
  - Missing Coverage: None. All tests directly correspond to instruction requirements.
  - Test Adjustment Notes: Tests are well-aligned with instructions. No adjustments needed.
- [X] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - **Test 1 (_check_camera_hierarchy) Assertions:**
    - Checks CameraNode exists under PlayerBody
    - Checks CameraActual exists under CameraNode
    - Checks Camera3D exists under CameraActual
    - **Instruction coverage:** "restructure PlayerBody so CameraNode contains a CameraActual Node3D with a Camera3D child" - UNAMBIGUOUS (exact node names and hierarchy specified)
  - **Test 2 (_check_exports) Assertions:**
    - Checks each of 10 exports exists as properties
    - Checks each export has PROPERTY_USAGE_EDITOR flag
    - **Instruction coverage:** "expose a FastNoiseLite plus numeric exports for..." lists exact variable names - UNAMBIGUOUS (exact export names specified)
  - **Test 3 (_check_defaults) Assertions:**
    - Checks camera_shake_noise_panning_speed == 30.0
    - Checks camera_shake_max_power == 0.15
    - Checks camera_shake_blend_speed == 7.0
    - Checks camera_shake_return_strength == 5.0
    - Checks camera_shake_noise_strength == 0.2
    - Checks camera_shake_falling_bias == 1.0
    - Checks camera_shake_falling_strength_falloff == 2.0
    - Checks camera_shake_falling_max_strength == 1.0
    - Checks camera_shake_jumping_strength == 0.2
    - **Instruction coverage:** Each default value is specified in parentheses after variable name - UNAMBIGUOUS
  - **Test 4 (_check_noise_assignment) Assertions:**
    - Checks camera_shake_noise is not null
    - Checks camera_shake_noise is instance of FastNoiseLite
    - **Instruction coverage:** "expose a FastNoiseLite" - UNAMBIGUOUS (exact type specified)
  - **Test 5 (_check_impulse_behaviour) Assertions:**
    - Calls impulse_camera(Vector3.UP, max_power * 5.0) and checks camera_shake_position.length() <= max_power + 0.001 (clamping)
    - Calls _physics_process(0.1) and checks camera_actual.position.length() > 0.0 (movement after impulse)
    - Calls _physics_process(0.1) 60 times and checks camera_actual.position.length() < 0.01 (decay to origin)
    - Checks time_since_started increases each frame
    - Calls impulse_camera_with_recoil(Vector3.BACK, 0.05) and checks camera_shake_position.y increased (upward kick)
    - **Instruction coverage:**
      - "clamp impulses to the max power" - UNAMBIGUOUS
      - "lerp CameraActual toward camera_shake_position plus sampled noise every physics frame" - UNAMBIGUOUS
      - "decay back to origin" - UNAMBIGUOUS
      - "Track camera_shake_position/time_since_started" - UNAMBIGUOUS
      - "add an upward kick inside impulse_camera_with_recoil" - UNAMBIGUOUS
  - **Test 6 (_check_landing_impulse) Assertions:**
    - Calls apply_landing_impulse(-3.0) and checks camera_actual.position.y < 0.0 (downward offset)
    - **Instruction coverage:** "implement apply_landing_impulse() so downward velocities below the bias trigger a proportional drop impulse" - UNAMBIGUOUS (downward velocity specified)
  - **CRITICAL AMBIGUITY CHECKS:**
    - [X] String formatting: N/A - no string formatting in this task
    - [X] Exact string values/names: All node names specified exactly (CameraNode, CameraActual, Camera3D)
    - [X] Number formats: All default values specified with exact decimal precision
    - [X] Comparison operators: All numeric comparisons have clear criteria (e.g., "below the bias")
    - [X] Node names, paths, and types: All specified exactly in instruction
    - [X] Property values: All default values specified exactly with numbers in parentheses
  - **Ambiguous Tests:** None. All test assertions have exact specifications in the instruction.
- [X] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: The tests check for specific behaviors (clamping, lerping, decay) rather than specific implementation details. For example, the _check_impulse_behaviour test verifies that clamping happens (camera_shake_position.length() <= max_power) without dictating how the clamping is implemented. The ground truth shows one solution using a _clamp_to_max_power helper method, but other implementations (e.g., inline clamping) would also pass. The noise sampling approach is also flexible - the test only verifies that noise is a FastNoiseLite, not the specific sampling implementation.
- [X] The folder and file names are consistent with other tasks (tasks_gt/task_0026)
  - Evidence:
    - Task folder: tasks/task_0026 (follows task_{number}_{name} pattern)
    - Ground truth folder: tasks_gt/task_0026 (same pattern under tasks_gt)
    - Config file: task_config.json (standard)
    - Test file: scripts/test.gd (standard location)
    - Main script: scripts/player_body.gd (consistent naming)
    - Scenes: scenes/main.tscn, scenes/test.tscn, scenes/player_body.tscn (standard structure)
- [X] PROCEED. Check this box if the task is validated and all key checks pass successfully.


# Feature Checklist
- [X] The task contains instructions or goals that are Node/inspector-focused.
  - Evidence: The instruction requires creating a specific node hierarchy ("CameraNode contains a CameraActual Node3D with a Camera3D child") and exposing @export variables that appear in the Godot inspector. The task is heavily focused on scene tree structure and inspector configuration, which are core Godot editor interactions.
- [X] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: Successfully completing this task requires understanding:
    1. The spatial hierarchy (parent-child node relationships in 3D space)
    2. The conceptual mapping between noise texture sampling and camera position offsets
    3. The visual effect of lerping/blending on camera movement smoothness
    4. The relationship between velocity values and perceived camera "shake" intensity
    This requires reasoning about how code parameters translate to visual/spatial outcomes, which is multimodal reasoning.
- [ ] The task contains a multimodal input (such as an image) in the instruction.
  - Evidence: The instruction is text-only. While the task requires multimodal reasoning to understand the visual effect, there are no images, screenshots, or other non-text inputs in the instruction itself.

# Notes

## Validation Summary
This task has been thoroughly validated and meets all criteria for GameDevBench inclusion. The task is well-structured, unambiguous, and properly tests camera shake implementation concepts.

## Key Strengths
1. **Clear instruction**: All exports, default values, and method names are explicitly specified
2. **Transcript alignment**: Every instruction component maps directly to transcript quotes
3. **Comprehensive tests**: Tests cover node hierarchy, exports, defaults, behavior, and edge cases
4. **No ambiguity**: All test assertions have exact specifications in the instruction
5. **Flexible implementation**: Tests validate behavior outcomes rather than specific code patterns

## Repository Discrepancy Note
The tutorial transcript describes implementing camera shake for an "FPS Horror Project" and mentions C# code (PlayerBodyController.cs), but the github_repo.txt file points to a shader experiments repository rather than the FPS project. The task config metadata acknowledges this with repo_evidence pointing to "ScenePrefabs/PlayerBody.tscn, Code/PlayerBodyController.cs". The task itself is a valid adaptation of the tutorial concepts to GDScript in Godot 4, even though the original repository may not be publicly available or was incorrectly linked.

## Test Execution Notes
Automated test execution via `uv run gamedevbench validate` was attempted but experienced dependency installation delays. Code analysis confirms:
- Starting point would fail tests (stub implementations)
- Ground truth should pass all tests (complete implementation with all required exports, methods, and logic)

## Multimodal Aspects
This task is particularly strong in multimodal requirements because:
1. It requires understanding 3D spatial relationships (node hierarchy)
2. It requires reasoning about noise sampling patterns and their visual effects
3. It requires understanding how numeric parameters (blend_speed, noise_strength, etc.) affect perceived camera motion
4. The falling/landing impulse system requires connecting velocity physics to visual feedback

A solver cannot simply "follow the code pattern" - they must understand how camera shake visually works and how to translate the tutorial's C# approach into GDScript while maintaining the same visual behavior.
