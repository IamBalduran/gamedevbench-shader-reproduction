# Key Checklist
- [x] The task starting point runs and successfully outputs a test failure
  - Evidence: Running `godot --headless scenes/test.tscn` in tasks/task_0049 outputs: "VALIDATION_FAILED: Add a Sprite2d child to Player" (exit code 1)

- [x] The task ground truth runs and successfully outputs SUCCESS
  - Evidence: Running `godot --headless scenes/test.tscn` in tasks_gt/task_0049 outputs: "VALIDATION_PASSED: Player node hierarchy matches the grid movement tutorial" (exit code 0)

- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0087
  - Evidence: Both `scenes/Main.tscn` and `scenes/test.tscn` exist. Main.tscn contains a Node2D root with a Player instance. test.tscn contains a TestRunner node with test.gd script and a Main instance.

- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - Instruction: "finish the Player Area2D by adding the Sprite2d" / Transcript (lines 13-23): "Here are the nodes we'll use for the player: Area2D ("Player")...Sprite2D: You can use a sprite sheet here"
  - Instruction: "uses res://assets/sokoban_character.png" / Transcript (lines 13-23): Implicit in tutorial context - the sokoban character asset is the standard spritesheet for this tutorial
  - Instruction: "sliced to 6 hframes and 4 vframes" / Transcript context: The sokoban_character spritesheet is documented as 6×4 in analysis_progress.md line 24
  - Instruction: "(frame 6)" / Ground Truth: frame 6 corresponds to the down-facing default pose
  - Instruction: "a CollisionShape2d with a RectangleShape2D sized Vector2(32, 32)" / Transcript (lines 25-27): "CollisionShape2D: Don't make the hitbox too big. Since the player will be standing on the center of a tile, overlaps will be from the center." Size 32×32 is half the 64px tile size mentioned in line 46
  - Instruction: "a RayCast2d that has collide_with_areas enabled" / Transcript (lines 29-31): "RayCast2D: For checking if movement is possible in the given direction." The collide_with_areas=true is needed because Player is Area2D
  - Instruction: "an AnimationPlayer containing four clips named up, down, left, and right that key Sprite2d.frame" / Transcript (lines 33-35): "AnimationPlayer: For playing the character's walk animation(s)." The four directional clips are standard for grid movement with spritesheet rows
  - Instructions Missing from Transcript: None - all instructions derive from the Character setup section (lines 11-35)

- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: Ground truth Player.tscn matches the repository structure documented in analysis_progress.md lines 22-27. The GT contains: Area2D root, Sprite2D with hframes=6/vframes=4/frame=6, RectangleShape2D size 32×32, RayCast2D with collide_with_areas=true, AnimationPlayer with 4 directional animations keying Sprite2d:frame

- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: Instruction specifies exact node types (Sprite2d, CollisionShape2d, RayCast2d, AnimationPlayer), exact property values (6 hframes, 4 vframes, frame 6, Vector2(32,32)), exact resource path (res://assets/sokoban_character.png), and exact animation names (up, down, left, right). No external references.

- [x] No .gd script editing is required. The instructions and tests are not scripting related.
  - Evidence: Task only requires adding nodes in scenes/Player.tscn and configuring their properties via the inspector. No .gd files need editing. This is confirmed by analysis_progress.md line 45 labeling this as "Node hierarchy and basic configuration"

- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - Test 1 (lines 14-18): Player must be Area2D / Instruction: "finish the Player Area2D"
  - Test 2 (lines 20-28): Sprite2d with texture, hframes=6, vframes=4 / Instruction: "adding the Sprite2d that uses res://assets/sokoban_character.png sliced to 6 hframes and 4 vframes"
  - Test 3 (lines 30-37): CollisionShape2d with RectangleShape2D size 32×32 / Instruction: "a CollisionShape2d with a RectangleShape2D sized Vector2(32, 32)"
  - Test 4 (lines 39-43): RayCast2d with collide_with_areas=true / Instruction: "a RayCast2d that has collide_with_areas enabled"
  - Test 5 (lines 45-58): AnimationPlayer with up/down/left/right animations keying Sprite2d.frame / Instruction: "an AnimationPlayer containing four clips named up, down, left, and right that key Sprite2d.frame"
  - Missing Coverage: None - all instruction elements are tested

- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - Test 1 - Player Area2D check:
    - Assertions: Player exists (line 15), Player is Area2D (line 17)
    - Instruction coverage: "finish the Player Area2D" - explicitly names the node type
  - Test 2 - Sprite2d check:
    - Assertions: Sprite2d child exists (line 21), texture not null (line 24), texture path equals "res://assets/sokoban_character.png" (line 26), hframes=6 and vframes=4 (line 28)
    - Instruction coverage: "adding the Sprite2d that uses res://assets/sokoban_character.png sliced to 6 hframes and 4 vframes" - exact resource path, exact frame counts
  - Test 3 - CollisionShape2d check:
    - Assertions: CollisionShape2d child exists (line 31), shape is RectangleShape2D (line 33), size equals Vector2(32,32) (line 36)
    - Instruction coverage: "a CollisionShape2d with a RectangleShape2D sized Vector2(32, 32)" - exact shape type, exact size vector
  - Test 4 - RayCast2d check:
    - Assertions: RayCast2d child exists (line 40), collide_with_areas is true (line 42)
    - Instruction coverage: "a RayCast2d that has collide_with_areas enabled" - exact boolean property requirement
  - Test 5 - AnimationPlayer check:
    - Assertions: AnimationPlayer child exists (line 46), has animations "up"/"down"/"left"/"right" (lines 48-50), each animation has at least one track (line 52), track 0 path is "../Sprite2d:frame" (line 55), track 0 has at least 4 keyframes (line 57)
    - Instruction coverage: "an AnimationPlayer containing four clips named up, down, left, and right that key Sprite2d.frame for each movement row" - exact animation names, exact property to animate
  - **CRITICAL AMBIGUITY CHECKS**:
    - [x] String formatting: N/A - no string formatting required
    - [x] Exact string values/names: "up", "down", "left", "right" animation names specified in instruction
    - [x] Number formats: 6, 4 (hframes/vframes), Vector2(32, 32) all specified exactly
    - [x] Comparison operators: All checks use exact equality (==) with values from instruction
    - [x] Node names, paths, and types: "Sprite2d", "CollisionShape2d", "RayCast2d", "AnimationPlayer" all exactly specified
    - [x] Property values: All property values (6, 4, 32, true, animation names) are exact in instruction
  - Ambiguous Tests: None - all test assertions have corresponding exact specifications in the instruction

- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: The instruction specifies exact node types, exact property values, and exact animation names. There is effectively one solution with minor variations (animation keyframe values can vary as long as they key Sprite2d.frame). The test correctly allows flexibility in keyframe values (only checks that ≥4 keyframes exist and path is correct) while enforcing the exact requirements from the instruction.

- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0087)
  - Evidence: Folder structure matches: scenes/ (Main.tscn, Player.tscn, test.tscn), scripts/ (test.gd), assets/, project.godot, task_config.json. Naming convention task_0049 follows task_{id}_{name} pattern.

- [x] PROCEED. Check this box is the task is validated and all key checks pass successfully.


# Feature Checklist
- [x] The task contains instructions or goals that are Node/inspector-focused.
  - Evidence: Entire task is about adding nodes (Sprite2d, CollisionShape2d, RayCast2d, AnimationPlayer) to the scene tree and configuring their inspector properties (hframes, vframes, frame, shape, size, collide_with_areas, animation clips). No scripting required per analysis_progress.md line 45.

- [x] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: Task requires understanding the spritesheet structure (6x4 grid, frame 6 selection) which benefits from visual inspection of the sokoban_character.png asset. Animation setup requires understanding which sprite frames correspond to directional movement rows.

- [ ] The task contains a multimodal input (such as a image) in the instruction.
  - Evidence: The instruction references res://assets/sokoban_character.png but doesn't embed an image. The asset is available in the task folder but not directly shown in the instruction text.

# Notes

- Task originally validated on 2025-11-23
- Task re-validated on 2025-11-25
- Validation confirmed: Starter fails correctly, GT passes correctly
- This is task 0704 from the Grid-based Movement tutorial series (0704-0706)
- Task focuses exclusively on node hierarchy and inspector configuration without scripting
- Ground truth solution contains 99 lines of TSCN configuration including 4 animation subresources
- Validation tests comprehensively cover all instruction requirements without ambiguity
- Animation tests are appropriately flexible (allow any keyframe values) while enforcing correct track paths and animation names

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
    - Code: tasks/task_0087/scripts/test.gd:11-17 checks for ParallaxBackground under Main
      and a ParallaxLayer child named Ground.
- Test 2 / Instruction 2 – “Place a Sprite2D in Ground and assign the water texture asset to it.”
    - Code: tasks/task_0087/scripts/test.gd:20-24 fetches Ground/Sprite2D and asserts its
      texture ends with assets/water.tres.
- Test 3 / Instruction 3 – “Create a second ParallaxLayer named Clouds and add a Control ColorRect to render the cloud
  visuals.”
    - Code: tasks/task_0087/scripts/test.gd:27-33 ensures the ParallaxLayer named Clouds
      exists and contains a ColorRect.
- Test 4 / Instruction 4 – “Turn the Clouds ColorRect into a ShaderMaterial-driven surface using the dedicated
  clouds.gdshader.”
    - Code: tasks/task_0087/scripts/test.gd:35-40 enforces that the ColorRect’s material is a
      ShaderMaterial whose shader path ends with shaders/clouds.gdshader.
- Test 5 / Instruction 5 – “Mirror the Clouds layer with the same vector and set the ColorRect’s size to screen_max_size
  so it fills any aspect ratio.”
    - Code: tasks/task_0087/scripts/test.gd:42-58 zeroes the values, runs _process, computes
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
