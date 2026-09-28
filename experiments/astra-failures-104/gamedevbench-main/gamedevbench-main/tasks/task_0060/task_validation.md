# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench validate $TASK_NAME` and successfully outputs a test failure
  - Evidence: Ran `uv run gamedevbench validate task_0060` and received:
    - Validation result: FAILED
    - Message: "Minimap must be a script instance"
    - This is expected because the starting point minimap.gd is empty (only contains a TODO comment)

- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: Ran `uv run gamedevbench --gt validate task_0060` and received:
    - Validation result: PASSED
    - Message: "Minimap marker logic and zoom control implemented"

- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0060
  - Evidence:
    - `scenes/main.tscn` exists with proper structure: Main node, CanvasLayer/Minimap, Player, Mobs/Mob, Crates/Crate
    - `scenes/test.tscn` exists with TestRunner node and Main instance
    - Both follow the same pattern as task_0060

- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - "export a Player reference" → Transcript line 154: "@export var player: Player"
  - "export... a zoom property with a clamped setter" → Transcript lines 155-156, 357-369: "@export var zoom = 1.5... set = set_zoom... func set_zoom(value): zoom = clamp(value, 0.5, 5)"
  - "cache the grid and marker prototypes" → Transcript lines 157-171: "@onready var grid = $MarginContainer/Grid... @onready var player_marker... @onready var mob_marker... @onready var alert_marker... @onready var icons = {"mob": mob_marker, "alert": alert_marker}"
  - "center the player marker after the first frame" → Transcript lines 205-213: "func _ready(): await get_tree().process_frame... player_marker.position = grid.size / 2"
  - "compute grid_scale from the grid size and viewport" → Transcript lines 208, 224: "grid_scale = grid.size / (get_viewport_rect().size * zoom)"
  - "duplicate and show markers for every node in the minimap_objects group using their minimap_icon keys" → Transcript lines 225-237: "var map_objects = get_tree().get_nodes_in_group("minimap_objects")... for item in map_objects: var new_marker = icons[item.minimap_icon].duplicate()... grid.add_child(new_marker)... new_marker.show()... markers[item] = new_marker"
  - "rotate and position markers each frame relative to the player" → Transcript lines 245-275: "func _process(delta):... player_marker.rotation = player.rotation + PI/2... for item in markers: var obj_pos = (item.position - player.position) * grid_scale + grid.size / 2... markers[item].position = obj_pos"
  - "scaling down and clamping when off the grid" → Transcript lines 283-311: "obj_pos = obj_pos.clamp(Vector2.ZERO, grid.size)... if grid.get_rect().has_point(obj_pos + grid.position): markers[item].scale = Vector2(1, 1) else: markers[item].scale = Vector2(0.75, 0.75)"
  - "remove and erase markers when _on_object_removed is called" → Transcript lines 339-347: "func _on_object_removed(object): if object in markers: markers[object].queue_free()... markers.erase(object)"
  - "handle mouse wheel gui_input to adjust zoom" → Transcript lines 377-389: "func _on_gui_input(event): if event is InputEventMouseButton and event.pressed: if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom += 0.1... if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom -= 0.1"
  - "ensure the world scene connects minimap_objects removed signals to the minimap" → Transcript lines 329-335: "func _ready():... for object in get_tree().get_nodes_in_group("minimap_objects"): object.removed.connect(minimap._on_object_removed)"
  - "while mobs/crates expose minimap_icon and belong to the minimap_objects group" → Transcript lines 125-139: "Add each item that you want to appear on the minimap to a group named "minimap_objects"... var minimap_icon = "mob"... var minimap_icon = "alert""
  - Instructions Missing from Transcript: None - all instruction elements are found in the transcript

- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence:
    - minimap.gd structure and logic directly from anna/data/kidscancode/minimap/Minimap_radar/repo/minimap.gd
    - mob.gd signal and minimap_icon from repo/mob.gd
    - crate.gd signal and minimap_icon from repo/crate.gd
    - world.gd signal connection logic from repo/world.gd (lines 12-13)
    - Scene structure (minimap.tscn) matches repo with Content/Grid hierarchy
    - The ground truth is a simplified version that removes unrelated game mechanics (tilemap, camera limits) while keeping core minimap functionality

- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: The instruction is self-contained and describes all necessary implementation details:
    - Specifies exact property names and types (player: Player, zoom with clamped setter)
    - Specifies exact node paths and caching requirements (grid, marker prototypes)
    - Specifies exact algorithms (grid_scale calculation, marker positioning formula, clamping)
    - Specifies exact method names (_on_object_removed, _on_gui_input)
    - Specifies exact group names (minimap_objects) and property names (minimap_icon)
    - No references to external tutorials or other tasks

- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests.
  - Test 1 (lines 25-27): Checks Minimap exists under CanvasLayer and has _process method → Instruction: "Implement the minimap logic" (implicitly requires script)
  - Test 2 (lines 29-32): Checks Grid TextureRect and PlayerMarker exist → Instruction: "cache the grid and marker prototypes"
  - Test 3 (lines 34-35): Checks Player node exists → Required for instruction: "export a Player reference"
  - Test 4 (lines 38-42): Checks player, zoom, set_zoom, grid_scale, markers properties exist → Instruction: "export a Player reference and a zoom property with a clamped setter... grid_scale... markers dictionary"
  - Test 5 (lines 44-46): Checks PlayerMarker centered on grid → Instruction: "center the player marker after the first frame"
  - Test 6 (lines 48-50): Checks grid_scale calculation → Instruction: "compute grid_scale from the grid size and viewport"
  - Test 7 (lines 53-62): Checks markers duplicated for mob and crate, visible, under Grid → Instruction: "duplicate and show markers for every node in the minimap_objects group"
  - Test 8 (lines 65-69): Checks player marker rotation relative to player → Instruction: "rotate... markers each frame relative to the player"
  - Test 9 (lines 69): Checks marker scale inside grid → Instruction: "scaling down... when off the grid" (tests both states)
  - Test 10 (lines 71-74): Checks marker position clamped and scaled down when outside grid → Instruction: "clamping when off the grid"
  - Test 11 (lines 77-84): Checks zoom adjustment via mouse wheel → Instruction: "handle mouse wheel gui_input to adjust zoom"
  - Test 12 (lines 87-90): Checks marker removal → Instruction: "remove and erase markers when _on_object_removed is called"
  - Missing Coverage: None - all instructions are tested

- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.

  **Test 1 (lines 22-27)**: Scene structure validation
  - Assertions:
    - Main scene exists (line 23)
    - Minimap exists at CanvasLayer/Minimap path (line 26)
    - Minimap has _process method (line 27)
  - Instruction coverage:
    - "Implement the minimap logic" → implies Minimap must be scripted
    - Node path implied by existing scene structure (given in starting point)

  **Test 2 (lines 29-32)**: Grid and PlayerMarker existence
  - Assertions:
    - Grid TextureRect exists at Content/Grid (line 30)
    - PlayerMarker Sprite2D exists under Grid (line 32)
  - Instruction coverage:
    - "cache the grid and marker prototypes" → explicitly mentions these nodes
    - Paths given in existing scene structure

  **Test 3 (lines 34-35)**: Player node existence
  - Assertions:
    - Player node exists under Main (line 35)
  - Instruction coverage:
    - "export a Player reference" → implies Player node must exist
    - Given in starting scene structure

  **Test 4 (lines 38-42)**: Export properties and cached nodes
  - Assertions:
    - has_property "player" (line 38)
    - has_property "zoom" (line 39)
    - has_method "set_zoom" (line 40)
    - has_property "grid_scale" (line 41)
    - has_property "markers" (line 42)
  - Instruction coverage:
    - "export a Player reference" → exact property name "player"
    - "export... a zoom property with a clamped setter" → exact property name "zoom" and "set_zoom" setter
    - "compute grid_scale" → exact property name "grid_scale"
    - "markers for every node in the minimap_objects group" → implies "markers" dictionary

  **Test 5 (lines 44-46)**: PlayerMarker centering
  - Assertions:
    - player_marker.position is within 0.5 pixels of grid.size / 2.0 (lines 44-46)
  - Instruction coverage:
    - "center the player marker after the first frame" → exact behavior: position = grid.size / 2
    - Formula is unambiguous

  **Test 6 (lines 48-50)**: grid_scale calculation
  - Assertions:
    - grid_scale equals grid.size / (viewport_rect.size * zoom) within 0.01 tolerance (lines 48-50)
  - Instruction coverage:
    - "compute grid_scale from the grid size and viewport" → exact formula specified in transcript
    - Formula is unambiguous: grid_scale = grid.size / (get_viewport_rect().size * zoom)

  **Test 7 (lines 53-62)**: Marker duplication and tracking
  - Assertions:
    - Mob and Crate nodes exist (line 55)
    - markers dictionary has mob as key (line 57)
    - markers dictionary has crate as key (line 58)
    - Markers are Sprite2D instances (lines 59-60)
    - Markers are children of grid (line 61)
    - Markers are visible (line 62)
  - Instruction coverage:
    - "duplicate and show markers for every node in the minimap_objects group using their minimap_icon keys" → specifies duplication, visibility, and dictionary tracking
    - "using their minimap_icon keys" → implies icons dictionary maps minimap_icon values to marker prototypes

  **Test 8 (lines 65-68)**: Player marker rotation
  - Assertions:
    - player_marker.rotation equals player.rotation + PI/2 within 0.001 tolerance (line 68)
  - Instruction coverage:
    - "rotate... markers each frame relative to the player" → exact formula from transcript: player.rotation + PI/2

  **Test 9 (lines 69)**: Marker scale inside grid
  - Assertions:
    - mob_marker.scale equals Vector2.ONE when mob is near player (line 69)
  - Instruction coverage:
    - "scaling down... when off the grid" → implies scale is 1 when inside grid, 0.75 when outside
    - Exact values specified in transcript line 304-310

  **Test 10 (lines 71-74)**: Marker position clamping and scale outside grid
  - Assertions:
    - mob_marker.position is clamped to grid.size when mob far away (line 73)
    - mob_marker.scale equals Vector2(0.75, 0.75) when outside grid (line 74)
  - Instruction coverage:
    - "clamping when off the grid" → specifies clamping to grid bounds
    - "scaling down" → exact scale value 0.75 from transcript

  **Test 11 (lines 77-84)**: Zoom control via mouse wheel
  - Assertions:
    - MOUSE_BUTTON_WHEEL_UP increases zoom (line 83)
    - grid_scale updates when zoom changes (line 84)
    - MOUSE_BUTTON_WHEEL_DOWN decreases zoom (line 90)
  - Instruction coverage:
    - "handle mouse wheel gui_input to adjust zoom" → specifies input event type and zoom adjustment
    - Transcript lines 379-382 specify exact behavior: wheel up += 0.1, wheel down -= 0.1

  **Test 12 (lines 93-94)**: Marker removal
  - Assertions:
    - markers dictionary no longer has crate after _on_object_removed(crate) (line 94)
  - Instruction coverage:
    - "remove and erase markers when _on_object_removed is called" → exact method name and behavior

  **CRITICAL AMBIGUITY CHECKS**:
    - [x] String formatting: N/A - no string formatting in this task
    - [x] Exact string values/names: "player", "zoom", "grid_scale", "markers", "minimap_icon", "minimap_objects" all specified in instruction
    - [x] Number formats: Exact values specified: 0.5-5.0 clamp range, 0.75 scale, PI/2 rotation offset
    - [x] Comparison operators: grid.get_rect().has_point() for inside/outside check, clamp() for bounds
    - [x] Node names, paths, and types: All specified - Content/Grid, PlayerMarker, Player type, minimap_objects group
    - [x] Property values: All exact - zoom clamp 0.5-5.0, scale 1 vs 0.75, rotation offset PI/2

  **Ambiguous Tests**: NONE - All test requirements are explicitly specified in the instruction with exact formulas, values, and method names.

- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: There is essentially one solution path clearly defined by the instruction:
    - Export properties with exact names (player, zoom)
    - Setter with exact clamp range (0.5-5.0)
    - Exact formula for grid_scale
    - Exact formula for marker positioning
    - Exact scale values (1.0 inside, 0.75 outside)
    - Exact rotation formula (player.rotation + PI/2)
    - Exact method names (_on_object_removed, _on_gui_input)
    - The tests correctly enforce these requirements without over-constraining implementation details

- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0060)
  - Evidence:
    - Folder: tasks/task_0060/ ✓
    - Ground truth: tasks_gt/task_0060/ ✓
    - Subfolders: scenes/, scripts/, assets/ ✓
    - Required files: task_config.json, scenes/main.tscn, scenes/test.tscn, scripts/test.gd ✓
    - All match the pattern from task_0060

- [x] PROCEED. Check this box if the task is validated and all key checks pass successfully.


# Feature Checklist
- [ ] The task contains instructions or goals that are Node/inspector-focused.
  - Evidence: This task is primarily script-focused. While it references nodes (Grid, PlayerMarker, etc.), the main work is implementing scripting logic for marker tracking, positioning, and zoom control. The node structure is already provided in the scene files.

- [ ] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: No - this task is purely code-based. It requires understanding of 2D positioning, coordinate transformations, and signal connections, but does not require visual analysis or multimodal reasoning.

- [ ] The task contains a multimodal input (such as an image) in the instruction.
  - Evidence: No - the instruction is text-only and does not include any images.

# Notes

## Overall Assessment
This task is **WELL-DESIGNED** and **READY TO PROCEED**. It successfully tests minimap implementation with marker tracking, dynamic positioning, zoom control, and signal-based removal handling.

## Strengths
1. **Clear instruction**: Every required element is explicitly specified with exact property names, formulas, and method names
2. **Comprehensive testing**: Tests cover all aspects of the instruction including edge cases (markers inside/outside grid)
3. **Matches transcript**: All instruction elements are directly derived from the tutorial transcript
4. **Proper difficulty**: Marked as "hard" which is appropriate given the complexity of coordinate transformations, signal connections, and multi-object tracking
5. **Clean starting point**: Provides scene structure but requires full script implementation
6. **Unambiguous requirements**: All numeric values, formulas, and behaviors are explicitly specified

## Key Implementation Requirements
The task requires implementing:
1. **Exports**: `player: Player` and `zoom` with clamped setter (0.5-5.0)
2. **Cached nodes**: grid, player_marker, mob_marker, alert_marker in @onready vars
3. **Icons dictionary**: Maps "mob" → mob_marker, "alert" → alert_marker
4. **Variables**: grid_scale (Vector2), markers (Dictionary)
5. **_ready()**:
   - await get_tree().process_frame
   - player_marker.position = grid.size / 2
   - grid_scale = grid.size / (get_viewport_rect().size * zoom)
   - Duplicate markers for all minimap_objects group members
6. **_process()**:
   - Rotate player_marker by player.rotation + PI/2
   - Update all marker positions with formula: (item.position - player.position) * grid_scale + grid.size / 2
   - Scale markers: 1.0 inside grid, 0.75 outside
   - Clamp marker positions to grid bounds
7. **_on_object_removed()**: Remove and erase markers from dictionary
8. **_on_gui_input()**: Handle mouse wheel to adjust zoom ±0.1
9. **Mob/Crate scripts**: Add minimap_icon property and removed signal
10. **Mob/Crate scenes**: Add to minimap_objects group
11. **World script**: Connect all minimap_objects' removed signals to minimap._on_object_removed

## Transcript Source
The tutorial is a web-based Godot recipe from kidscancode.org, not a video tutorial. The "transcript" is actually the text content of the web page, which provides clear step-by-step instructions with code examples.

## Comparison to Repository
The ground truth solution is a streamlined version of the repository code:
- Removes tilemap and camera limit logic (unrelated to minimap)
- Removes mob collision/bouncing behavior (simplifies for testing)
- Keeps all core minimap functionality intact
- Uses Content/Grid path instead of MarginContainer/Grid (scene structure difference)
- Adds set_player() helper method for flexibility

## Test Coverage Analysis
All 12 test assertions map to specific instruction requirements:
- Properties: player, zoom, set_zoom, grid_scale, markers ✓
- Centering: PlayerMarker at grid.size / 2 ✓
- Grid scale: Formula validation ✓
- Marker duplication: For minimap_objects group ✓
- Rotation: player.rotation + PI/2 ✓
- Scaling: 1.0 inside, 0.75 outside ✓
- Clamping: To grid bounds ✓
- Zoom control: Mouse wheel ± 0.1 ✓
- Removal: _on_object_removed erases from dictionary ✓

No gaps in test coverage identified.
