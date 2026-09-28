# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure 
  - Evidence: `uv run gamedevbench validate task_0108` -> FAILED: "TileSet missing tile_type custom data layer" (command output captured 2026-01-24).
- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: `uv run gamedevbench --gt validate task_0108` -> PASSED: "Task completed successfully" (command output captured 2026-01-24).
- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0108
  - Evidence: `tasks/task_0108/scenes/main.tscn`, `tasks/task_0108/scenes/test.tscn`, `tasks_gt/task_0108/scenes/main.tscn`, `tasks_gt/task_0108/scenes/test.tscn`.
- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - Instruction 1 (add tile_type custom data layer type int) / Transcript 1: "add a new custom data layer let's call this tile type ... this will be of a type integer" (`tutorials/Game Dev Artisan/Using Godot 4's TileMaps and Custom Data Layers - Godot Fundamentals/transcript.txt`).
  - Instruction 2 (create TILE_TYPES enum) / Transcript 2: "create a new enumerator we'll call this tile types ... none ... water ... dirt ... grass" (same transcript).
  - Instruction 3 (export gradient textures for water/dirt/grass) / Transcript 3: "add some export variables ... watercolor as a gradient texture 1D ... dirt color ... grass color" (same transcript).
  - Instruction 4 (map gradients and get_gradient_at uses tile_type custom data) / Transcript 4: "create a dictionary using our tile types mapped to our exported variables ... create a static function and we'll get our gradient at our position ... get our tile type using our get custom data at" (same transcript).
  - Instruction 5 (add GPUParticles2D left/right with box emission, direction, spread, gravity off, velocity, damping, scale, amount) / Transcript 5: "add a new type of GPU particles 2D ... set the direction to negative 16 ... set the spread to about 25 ... disable gravity ... initial velocity ... dampening ... scale" plus "about 128 particles per emitter" (same transcript).
  - Instruction 6 (z_index -1 and emitting disabled) / Transcript 6: "set this to the Z index of -1 ... disable the emitters" (same transcript).
  - Instruction 7 (tank uses World.get_gradient_at and assigns color_ramp; enables/disables emission based on movement) / Transcript 7: "World dot get gradient at our Tank's position" and "set the ... color ramp" and "turn the emitting equal to true ... if ... not moving ... set ... to false" (same transcript).
  - Instructions Missing from Transcript: None found.
- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: Repo `scenes/world/world.gd` contains enum/export/dictionary/get_gradient_at matching task/gt `scripts/world.gd` (`tutorials/Game Dev Artisan/Using Godot 4's TileMaps and Custom Data Layers - Godot Fundamentals/repo/scenes/world/world.gd`, `tasks_gt/task_0108/scripts/world.gd`).
  - Evidence: Repo `scenes/entities/tank/tank.gd` uses `World.get_gradient_at`, sets `color_ramp`, and toggles `emitting` similar to task/gt `scripts/tank.gd` (`tutorials/Game Dev Artisan/Using Godot 4's TileMaps and Custom Data Layers - Godot Fundamentals/repo/scenes/entities/tank/tank.gd`, `tasks_gt/task_0108/scripts/tank.gd`).
  - Evidence: Repo `scenes/entities/tank/tank.tscn` defines Left/RightTrackParticles with matching process material settings; gt mirrors these (`tutorials/Game Dev Artisan/Using Godot 4's TileMaps and Custom Data Layers - Godot Fundamentals/repo/scenes/entities/tank/tank.tscn`, `tasks_gt/task_0108/scenes/tank.tscn`).
  - Evidence: Repo `scenes/world/world.tscn` has gradient subresources and tile_type custom data layer; gt mirrors these (`tutorials/Game Dev Artisan/Using Godot 4's TileMaps and Custom Data Layers - Godot Fundamentals/repo/scenes/world/world.tscn`, `tasks_gt/task_0108/scenes/world.tscn`).
- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: Instruction in `tasks/task_0108/task_config.json` is self-contained and references only local files and node names.
- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - Test 1 (world.tscn TileSet custom data layer + gradients), Instruction 1: Checks tile_type layer exists and is int; checks world exports are GradientTexture1D (`tasks/task_0108/scripts/test.gd:16-64`).
  - Test 2 (world.gd enum + get_gradient_at + tile_type), Instruction 2: Checks for `enum TILE_TYPES`, `get_gradient_at`, `tile_type`, and gradient variable references (`tasks/task_0108/scripts/test.gd:66-88`).
  - Test 3 (tank.tscn particle nodes + process material settings), Instruction 3: Checks Left/RightTrackParticles nodes, amount, z_index, emitting false, and material settings (box emission, extents, direction, spread, gravity, velocity, damping, scale) (`tasks/task_0108/scripts/test.gd:90-136`).
  - Test 4 (tank.gd uses World.get_gradient_at + color_ramp + emitting on/off), Instruction 4: Checks `World.get_gradient_at`, `color_ramp`, and enabling/disabling emission (`tasks/task_0108/scripts/test.gd:138-170`).
  - Missing Coverage: None. All instruction requirements are asserted.
- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - Test 1, Assertions: TileSet has custom data layer named `tile_type` with type int; World exports `water_color`, `dirt_color`, `grass_color` as GradientTexture1D. Instruction coverage: explicitly names layer, type, and export names and types.
  - Test 2, Assertions: world.gd includes `enum TILE_TYPES`, a static `get_gradient_at` and reads `tile_type`, and references `water_color`, `dirt_color`, `grass_color`. Instruction coverage: explicitly requires these names and behaviors.
  - Test 3, Assertions: Tank scene has Left/RightTrackParticles GPUParticles2D, amount 128, z_index -1, emitting false, and process material properties (box emission, extents, direction y values, spread 25, gravity zero, initial_velocity_max 4, damping_max 3, scale_min 0.25). Instruction coverage: explicitly lists each property and value.
  - Test 4, Assertions: Tank script calls `World.get_gradient_at`, assigns `process_material.color_ramp`, sets emitting true while moving and false when not moving. Instruction coverage: explicitly calls these out in instruction.
  - **CRITICAL AMBIGUITY CHECKS** - For each test, explicitly verify:
    - [x] String formatting (padding, delimiters, exact format) is specified in instruction
    - [x] Exact string values/names are in instruction (not just "format text")
    - [x] Number formats (zero-padding, decimal places) are specified
    - [x] Any comparison operators (==, !=, >, <, contains, begins_with, ends_with) have clear criteria
    - [x] Node names, paths, and types match instruction exactly
    - [x] Property values (numbers, booleans, strings) have exact values in instruction
  - Ambiguous Tests: None.
- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: Instruction specifies exact names/values; tests align to that single clear solution and do not enforce incidental serialization details.
- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0108)
  - Evidence: Standard structure with `task_config.json`, `scripts/test.gd`, `scenes/main.tscn`, `scenes/test.tscn` under `tasks/task_0108` and mirrored in `tasks_gt/task_0108`.
- [x] PROCEED. Check this box is the task is validated and all key checks pass successfully.


# Feature Checklist
- [x] The task contains instructions or goals that are Node/inspector-focused. 
  - Evidence: Instructions require adding nodes and setting GPUParticles2D process material properties in `scenes/tank.tscn` and exporting gradient textures on the World node.
- [ ] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: Instructions are fully textual and do not require interpreting images/audio.
- [ ] The task contains a multimodal input (such as a image) in the instruction.
  - Evidence: No images or other multimodal inputs are provided in `task_config.json`.

# Notes
- Transcript file is a single line; evidence is from substring matches in `transcript.txt`.

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
      but rather size of it and the size will simply be uh screen Max size and uh screen Max size"
## Matching Test to Instruction

- Test 1 / Instruction 1 – “Add a ParallaxBackground under Main with a ParallaxLayer named Ground.”
    - Code: tasks/task_0108/scripts/test.gd:11-17 checks for ParallaxBackground under Main
      and a ParallaxLayer child named Ground.
- Test 2 / Instruction 2 – “Place a Sprite2D in Ground and assign the water texture asset to it.”
    - Code: tasks/task_0108/scripts/test.gd:20-24 fetches Ground/Sprite2D and asserts its
      texture ends with assets/water.tres.
- Test 3 / Instruction 3 – “Create a second ParallaxLayer named Clouds and add a Control ColorRect to render the cloud
  visuals.”
    - Code: tasks/task_0108/scripts/test.gd:27-33 ensures the ParallaxLayer named Clouds
      exists and contains a ColorRect.
- Test 4 / Instruction 4 – “Turn the Clouds ColorRect into a ShaderMaterial-driven surface using the dedicated
  clouds.gdshader.”
    - Code: tasks/task_0108/scripts/test.gd:35-40 enforces that the ColorRect’s material is a
      ShaderMaterial whose shader path ends with shaders/clouds.gdshader.
- Test 5 / Instruction 5 – “Mirror the Clouds layer with the same vector and set the ColorRect’s size to screen_max_size
  so it fills any aspect ratio.”
    - Code: tasks/task_0108/scripts/test.gd:42-58 zeroes the values, runs _process, computes
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
