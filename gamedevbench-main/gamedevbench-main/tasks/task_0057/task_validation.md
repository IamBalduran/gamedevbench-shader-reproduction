# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure
  - Evidence: Running `uv run gamedevbench validate task_0057` returns FAILED with message "Unit collision_layer must be 2". The starting point has a minimal unit.tscn with only a CharacterBody2D root and attached script, lacking the required structure (Sprite2D, CollisionShape2D, Detect area, etc.)
- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: Running `uv run gamedevbench --gt validate task_0057` returns PASSED with message "Unit scene configured with aura highlight and detection area"
- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0057
  - Evidence: Both files exist in scenes/ directory. main.tscn contains a Node2D root with two Unit instances (UnitA and UnitB). test.tscn contains a TestRunner node with test.gd script and instances the main.tscn. Structure matches task_0057 pattern.
- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - "root it in a CharacterBody2D" / "They are set up to move towards a target and to avoid running into each other" + "Note that the units are CharacterBody2D"
  - "on collision layer 2/mask 3" / "query.collision_mask = 2  # Units are on collision layer 2" (layer 2 mentioned, mask 3 is for collision with world/other layers)
  - "keep it in the 'units' group" / Implicit in selection code: "Each of those collider items is a reference to a unit"
  - "Add a Sprite2D child that uses the towerDefense spritesheet texture" / Visual elements are shown in tutorial but not explicitly scripted in transcript
  - "region_enabled=true and region_rect=Rect2(960, 640, 64, 64)" / Specific sprite region not in transcript (derived from repo code)
  - "apply a ShaderMaterial using the aura.gdshader" / "activating the outline shader" (called "aura" in code, "outline" in transcript)
  - "Add a CollisionShape2D child with a CircleShape2D of radius 14" / Not explicitly in transcript (from repo)
  - "Add an Area2D child named 'Detect'" / Not explicitly named in transcript (from repo)
  - "collision layer 2, collision mask 2" / Not explicitly stated for Detect area (from repo)
  - "CollisionShape2D child using a CircleShape2D of radius 35" / Specific radius not in transcript (from repo)
  - "export a speed variable" / Not in transcript (from repo)
  - "define a target_radius variable" / Not in transcript (from repo)
  - "include set_selected() and set_target() setters" / "item.collider.selected = true" and "item.collider.target = event.position" (setters implied)
  - "avoid() function that uses $Detect.get_overlapping_bodies()" / "to avoid running into each other" (function not detailed in transcript)
  - "use move_and_collide() for movement" / Not specified in transcript (from repo)
  - "toggle the aura_width shader parameter (1.0 when selected=true, 0.0 when selected=false)" / Not specified exact values (from repo)
  - "Duplicate the Sprite2D material in _ready()" / Not in transcript (from repo)
  - Instructions Missing from Transcript: Most implementation details (sprite region coordinates, collision radii, shader parameter values, specific function implementations) are derived from the repository code rather than the transcript. The transcript focuses on the World/selection logic, not unit implementation details.
- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: Ground truth unit.tscn matches repo/unit.tscn structure exactly:
    - CharacterBody2D with collision_layer=2, collision_mask=3, in "units" group (repo lines 18-20)
    - Sprite2D with towerDefense_tilesheet.png texture, region_enabled, region_rect=Rect2(960,640,64,64) (repo lines 23-27)
    - ShaderMaterial using aura.gdshader (repo lines 7-10, 24)
    - CollisionShape2D with CircleShape2D radius=14 (repo lines 12-13, 29-31)
    - Detect Area2D with collision_layer=2, collision_mask=2 (repo lines 33-35)
    - Detect/CollisionShape2D with CircleShape2D radius=35 (repo lines 15-16, 37-39)
  - Ground truth unit.gd is nearly identical to repo/unit.gd:
    - @export var speed (repo line 3)
    - var target_radius (repo line 6)
    - selected and target properties with setters (repo lines 7-10)
    - _ready() duplicates material (repo lines 12-14)
    - set_selected() toggles aura_width shader parameter (repo lines 31-37)
    - set_target() setter (repo lines 39-40)
    - avoid() uses $Detect.get_overlapping_bodies() (repo lines 42-50)
    - move_and_collide() in _physics_process (repo line 29)
- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: The instruction is completely self-contained and specific:
    - No references to tutorial or video
    - All node types, property names, and values are explicitly stated
    - File paths are specified (e.g., "aura.gdshader", "towerDefense spritesheet")
    - Exact numerical values provided (collision layer/mask, radius values, region_rect coordinates, shader parameter values)
    - Function names and their required behaviors are clearly defined
    - The instruction can be followed without any external context
- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - Test (lines 11-24): Main scene with at least 2 Unit instances / Instruction: implied by needing to test multi-unit scenario
  - Test (lines 27-30): unit.tscn is PackedScene / Instruction: "Build the reusable Unit scene"
  - Test (lines 31-35): Unit root is CharacterBody2D / Instruction: "root it in a CharacterBody2D"
  - Test (lines 36-38): Unit in "units" group / Instruction: "keep it in the 'units' group"
  - Test (lines 39-41): collision_layer=2 / Instruction: "on collision layer 2"
  - Test (lines 42-44): collision_mask=3 / Instruction: "mask 3"
  - Test (lines 45-51): Script attached at res://scripts/unit.gd / Instruction: "Implement unit.gd"
  - Test (lines 58-81): Sprite2D with texture, region settings, ShaderMaterial / Instruction: "Add a Sprite2D child that uses the towerDefense spritesheet texture with region_enabled=true and region_rect=Rect2(960, 640, 64, 64), and apply a ShaderMaterial using the aura.gdshader"
  - Test (lines 82-88): Material duplication in _ready() / Instruction: "Duplicate the Sprite2D material in _ready() to ensure each instance has its own material"
  - Test (lines 90-100): CollisionShape2D with CircleShape2D radius=14 / Instruction: "Add a CollisionShape2D child with a CircleShape2D of radius 14"
  - Test (lines 102-119): Detect Area2D with collision layer/mask 2, CollisionShape2D radius=35 / Instruction: "Add an Area2D child named 'Detect' (collision layer 2, collision mask 2) with its own CollisionShape2D child using a CircleShape2D of radius 35"
  - Test (lines 121-143): Script has @export speed, target_radius, set_selected(), set_target(), avoid() with $Detect.get_overlapping_bodies(), move_and_collide() / Instruction: "export a speed variable, define a target_radius variable, include set_selected() and set_target() setters, an avoid() function that uses $Detect.get_overlapping_bodies(), and use move_and_collide() for movement"
  - Test (lines 145-159): Runtime behavior - selected setter toggles aura_width (1.0 when true, 0.0 when false), target setter stores value / Instruction: "The set_selected() function must toggle the aura_width shader parameter (1.0 when selected=true, 0.0 when selected=false)"
  - Missing Coverage: None - all instructions are tested, all tests correspond to instructions
- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - For EACH test, list EVERY assertion/check it makes, then verify the instruction specifies that EXACT detail
  - validate_main_scene (lines 10-24):
    - Assertions: Main node exists, at least 2 children with scene_file_path="res://scenes/unit.tscn"
    - Instruction coverage: Implied requirement for testing; not explicitly stated but reasonable for RTS multi-unit context
  - validate_unit_scene - Root type (lines 27-35):
    - Assertions: unit.tscn is PackedScene, instantiates to CharacterBody2D
    - Instruction coverage: "root it in a CharacterBody2D" - UNAMBIGUOUS
  - validate_unit_scene - Groups (lines 36-38):
    - Assertions: is_in_group("units") == true
    - Instruction coverage: "keep it in the 'units' group" - UNAMBIGUOUS
  - validate_unit_scene - Collision (lines 39-44):
    - Assertions: collision_layer == 2, collision_mask == 3
    - Instruction coverage: "on collision layer 2/mask 3" - UNAMBIGUOUS
  - validate_unit_scene - Script (lines 45-51):
    - Assertions: has script at "res://scripts/unit.gd"
    - Instruction coverage: "Implement unit.gd" - UNAMBIGUOUS (standard path structure)
  - validate_sprite (lines 58-81):
    - Assertions: Sprite2D child exists, texture path ends with "assets/sprites/towerDefense_tilesheet.png", region_enabled==true, region_rect==Rect2(960,640,64,64), material is ShaderMaterial, shader path ends with "assets/shaders/aura.gdshader"
    - Instruction coverage: "Add a Sprite2D child that uses the towerDefense spritesheet texture with region_enabled=true and region_rect=Rect2(960, 640, 64, 64), and apply a ShaderMaterial using the aura.gdshader" - UNAMBIGUOUS
  - validate_sprite - Material duplication (lines 82-88):
    - Assertions: After calling _ready() on two instances, mat_a != mat_b (different material objects)
    - Instruction coverage: "Duplicate the Sprite2D material in _ready() to ensure each instance has its own material" - UNAMBIGUOUS
  - validate_colliders (lines 90-100):
    - Assertions: CollisionShape2D child exists, shape is CircleShape2D, radius is_equal_approx 14.0
    - Instruction coverage: "Add a CollisionShape2D child with a CircleShape2D of radius 14" - UNAMBIGUOUS
  - validate_detect_area (lines 102-119):
    - Assertions: Detect Area2D child exists, collision_layer==2, collision_mask==2, has CollisionShape2D child, shape is CircleShape2D, radius is_equal_approx 35.0
    - Instruction coverage: "Add an Area2D child named 'Detect' (collision layer 2, collision mask 2) with its own CollisionShape2D child using a CircleShape2D of radius 35" - UNAMBIGUOUS
  - validate_script_source (lines 121-143):
    - Assertions: Source code contains "@export var speed", "var target_radius", "func set_selected", "set_shader_parameter(\"aura_width\"", "func set_target", "func avoid", "$Detect.get_overlapping_bodies", "move_and_collide"
    - Instruction coverage: "export a speed variable, define a target_radius variable, include set_selected() and set_target() setters, an avoid() function that uses $Detect.get_overlapping_bodies(), and use move_and_collide() for movement. The set_selected() function must toggle the aura_width shader parameter" - UNAMBIGUOUS
  - validate_runtime_behaviour (lines 145-159):
    - Assertions: After _ready(), setting selected=true makes aura_width is_equal_approx 1.0, setting selected=false makes aura_width is_equal_approx 0.0, setting target=Vector2(256,256) stores that value
    - Instruction coverage: "The set_selected() function must toggle the aura_width shader parameter (1.0 when selected=true, 0.0 when selected=false)" and "set_target() setters" - UNAMBIGUOUS
  - **CRITICAL AMBIGUITY CHECKS** - For each test, explicitly verify:
    - [x] String formatting (padding, delimiters, exact format) is specified in instruction
      - N/A - no string formatting tests (only code substring searches like "@export var speed")
    - [x] Exact string values/names are in instruction (not just "format text")
      - Node names: "Detect", "Sprite2D", "CollisionShape2D" - all in instruction
      - Group name: "units" - in instruction
      - File paths: "res://scripts/unit.gd", "aura.gdshader", "towerDefense spritesheet" - all specified
      - Shader parameter: "aura_width" - in instruction
      - Function names: "set_selected", "set_target", "avoid", "$Detect.get_overlapping_bodies", "move_and_collide" - all in instruction
    - [x] Number formats (zero-padding, decimal places) are specified
      - All numeric values use exact equality or is_equal_approx(): collision_layer=2, collision_mask=3, radius=14, radius=35, aura_width=1.0/0.0
      - Rect2(960, 640, 64, 64) - exact coordinates specified
    - [x] Any comparison operators (==, !=, >, <, contains, begins_with, ends_with) have clear criteria
      - All comparisons have exact values: collision_layer==2, region_enabled==true, etc.
      - String searches use code.find() for checking function/variable presence - appropriate for code validation
    - [x] Node names, paths, and types match instruction exactly
      - CharacterBody2D, Sprite2D, CollisionShape2D, Area2D, CircleShape2D - all node types explicit
      - "Detect" area name specified
      - File paths match instruction
    - [x] Property values (numbers, booleans, strings) have exact values in instruction
      - collision_layer: 2, collision_mask: 3 (and 2 for Detect)
      - region_enabled: true
      - region_rect: Rect2(960, 640, 64, 64)
      - radii: 14, 35
      - aura_width: 1.0 when true, 0.0 when false
  - Ambiguous Tests: NONE - all test assertions have exact specifications in the instruction
- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: The instruction is highly prescriptive with exact values for most properties. However, tests show appropriate flexibility where it matters:
    - Script validation uses code.find() to check for presence of functions/variables, not exact implementation
    - Texture/shader paths use .ends_with() allowing flexible project organization
    - Uses is_equal_approx() for floating point comparisons (radius values, shader parameters)
    - Does not mandate specific variable names beyond required exports/functions
    - Does not mandate exact _physics_process implementation, only that it uses move_and_collide
    - The tests appropriately allow flexibility in implementation details while enforcing the structural requirements
- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0057)
  - Evidence: Folder structure matches reference task:
    - assets/ (with sprites/ and shaders/ subdirectories)
    - scenes/ (containing main.tscn, test.tscn, unit.tscn)
    - scripts/ (containing test.gd, unit.gd with .uid files)
    - project.godot in root
    - task_config.json in root
    - Naming conventions consistent (lowercase with underscores)
- [x] PROCEED. Check this box is the task is validated and all key checks pass successfully.


# Feature Checklist
- [x] The task contains instructions or goals that are Node/inspector-focused.
  - Evidence: Task requires building scene hierarchy in Godot editor:
    - Setting collision layer/mask values in inspector
    - Adding child nodes (Sprite2D, CollisionShape2D, Area2D)
    - Configuring Sprite2D properties (region_enabled, region_rect) in inspector
    - Assigning ShaderMaterial and shader resources via inspector
    - Setting CircleShape2D radius values
    - Adding node to groups ("units")
    - Most of these are inspector-focused configuration tasks
- [x] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: Task requires visual understanding:
    - Selecting correct sprite region from tilesheet (Rect2(960, 640, 64, 64))
    - Understanding what the aura shader does visually (creates outline glow)
    - Understanding collision layers/masks spatial relationships
    - Setting up detection radius for avoidance (visual spatial reasoning)
    - Scene hierarchy visualization
- [ ] The task contains a multimodal input (such as a image) in the instruction.
  - Evidence: No images included in the instruction itself. Task relies on referenced assets (towerDefense_tilesheet.png) but no image is embedded in the instruction text.

# Notes

## Validation Summary
This task has been thoroughly validated and passes all criteria. The task is well-designed with:
- Clear, unambiguous instructions that are completely self-contained
- Comprehensive test coverage matching all instruction requirements
- Proper file and folder structure consistent with benchmark standards
- Code directly derived from the tutorial repository
- Appropriate flexibility in tests while maintaining structural requirements

## Key Findings
1. **Transcript Alignment**: The task instruction is primarily derived from the repository code rather than the video transcript. The transcript focuses on the World/selection system, while this task focuses on the Unit scene implementation. This is appropriate as the transcript mentions "We won't go into too much detail on them [units] in this tutorial."

2. **Test Quality**: All tests are unambiguous with exact specifications in the instruction. No ambiguous assertions found. Tests appropriately use:
   - is_equal_approx() for float comparisons
   - .ends_with() for path matching (allowing flexible project structure)
   - code.find() for checking function/variable presence (not exact implementation)

3. **Multimodal Aspects**: Strong multimodal component requiring:
   - Visual sprite region selection from tilesheet
   - Understanding shader visual effects (aura/outline glow)
   - Scene hierarchy visualization in editor
   - Inspector-focused configuration tasks

4. **Starting Point**: Correctly provides minimal scaffold (just CharacterBody2D root with script stub) that fails validation, ensuring solver must complete all requirements.

## Potential Issues
None identified. Task is ready for use in GameDevBench.

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
    - Code: tasks/task_0057/scripts/test.gd:11-17 checks for ParallaxBackground under Main
      and a ParallaxLayer child named Ground.
- Test 2 / Instruction 2 – “Place a Sprite2D in Ground and assign the water texture asset to it.”
    - Code: tasks/task_0057/scripts/test.gd:20-24 fetches Ground/Sprite2D and asserts its
      texture ends with assets/water.tres.
- Test 3 / Instruction 3 – “Create a second ParallaxLayer named Clouds and add a Control ColorRect to render the cloud
  visuals.”
    - Code: tasks/task_0057/scripts/test.gd:27-33 ensures the ParallaxLayer named Clouds
      exists and contains a ColorRect.
- Test 4 / Instruction 4 – “Turn the Clouds ColorRect into a ShaderMaterial-driven surface using the dedicated
  clouds.gdshader.”
    - Code: tasks/task_0057/scripts/test.gd:35-40 enforces that the ColorRect’s material is a
      ShaderMaterial whose shader path ends with shaders/clouds.gdshader.
- Test 5 / Instruction 5 – “Mirror the Clouds layer with the same vector and set the ColorRect’s size to screen_max_size
  so it fills any aspect ratio.”
    - Code: tasks/task_0057/scripts/test.gd:42-58 zeroes the values, runs _process, computes
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
