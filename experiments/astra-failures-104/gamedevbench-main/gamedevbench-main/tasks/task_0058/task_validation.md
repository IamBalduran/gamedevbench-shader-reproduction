# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure
  - Evidence: Running `uv run gamedevbench validate task_0058` produces:
    - `Validation result: FAILED`
    - `Message: Margins should be 20 on all sides`
    - This is expected because the starting point's audio_demo.tscn only contains a minimal MarginContainer without the required UI structure

- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: Running `uv run gamedevbench --gt validate task_0058` produces:
    - `Validation result: PASSED`
    - `Message: Audio demo UI lists sounds, wires buttons, and reflects AudioManager stats`

- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0058
  - Evidence:
    - `tasks/task_0058/scenes/main.tscn` exists and instances AudioDemo
    - `tasks/task_0058/scenes/test.tscn` exists with TestRunner node and AudioDemo instance
    - Both files follow the same pattern as task_0001

- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - **Main instruction breakdown:**
    - **"Create res://scenes/audio_demo.tscn with a MarginContainer root named AudioDemo"**
      - Transcript: "This project reads a folder full of audio files and generates a grid of buttons"
      - The repo contains audio_demo.tscn with MarginContainer root named AudioDemo (lines 6 in repo/audio_demo.tscn)

    - **"fills the screen, uses 20px margins on all sides"**
      - Repo shows: `theme_override_constants/margin_left = 20`, `margin_top = 20`, `margin_right = 20`, `margin_bottom = 20` (lines 12-15 in repo/audio_demo.tscn)

    - **"attaches res://scripts/audio_demo.gd exporting sound_dir defaulting to res://assets"**
      - Repo shows: `script = ExtResource("1_f3j3j")` pointing to audio_demo.gd (line 16)
      - Repo shows: `sound_dir = "res://assets"` (line 17)
      - Repo code shows: `@export_dir var sound_dir` (line 4 in repo/audio_demo.gd)

    - **"Add a CenterContainer with a GridContainer child set to two columns with 10px horizontal and vertical separation for dynamically added Buttons"**
      - Repo shows CenterContainer → GridContainer hierarchy (lines 19-26 in repo/audio_demo.tscn)
      - Repo shows: `columns = 2` (line 26)
      - Repo shows: `h_separation = 10`, `v_separation = 10` (lines 24-25)
      - Transcript: "generates a grid of buttons. Click the button to play the sound"

    - **"Add a CanvasLayer with an HBoxContainer top bar containing four Labels"**
      - Repo shows CanvasLayer → HBoxContainer structure (lines 28-34)
      - Four labels present: Label, Label2, VSeparator, Label4, Label3 (lines 37-71)
      - Transcript: "At the top, you can see the audio manager's live statistics"

    - **"'Available Streams:', a count label, a VSeparator, and a 'Queue:' label with its own count"**
      - Repo Label text: "Available Streams:" (line 41)
      - Repo Label2 text: "0" (line 49) - count label
      - Repo VSeparator exists (line 53)
      - Repo Label4 text: "Queue:" (line 61)
      - Repo Label3 text: "0" (line 69) - queue count

    - **"all using the Poppins-Medium font at size 24"**
      - All labels use: `theme_override_fonts/font = ExtResource("1")` pointing to Poppins-Medium.ttf
      - All labels use: `theme_override_font_sizes/font_size = 24`

    - **"Implement audio_demo.gd so _ready() scans sound_dir for .wav/.ogg files"**
      - Repo code (lines 6-16 in repo/audio_demo.gd): DirAccess.open, list_dir_begin, checks for .wav/.ogg extensions

    - **"adds a Button for each with its text set to the filename, Poppins font override"**
      - Repo code (lines 19-25): creates Button, adds to GridContainer, sets text to file_name
      - Line 23: `b.add_theme_font_override("font", load("res://assets/Poppins-Medium.ttf"))`

    - **"pressed connected to on_audio_button_pressed, which calls AudioManager.play() on the file path"**
      - Repo code line 25: `b.pressed.connect(on_audio_button_pressed.bind(b))`
      - Repo code lines 28-31: on_audio_button_pressed builds path and calls AudioManager.play(path)

    - **"Ensure _process() updates the count labels to reflect AudioManager.available.size() and AudioManager.queue.size()"**
      - Repo code lines 34-37: _process updates Label2 and Label3 with AudioManager.available.size() and queue.size()
      - Transcript: "you can see the audio manager's live statistics"

  - **Instructions Missing from Transcript:** None - all instructions are directly derived from the example project described in the transcript and visible in the repository code

- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence:
    - **audio_demo.tscn structure**: Directly matches `anna/data/kidscancode/audio_manager/Audio Manager/repo/audio_demo.tscn`
      - MarginContainer setup (lines 6-17)
      - CenterContainer/GridContainer (lines 19-26)
      - CanvasLayer/HBoxContainer with Labels (lines 28-71)
    - **audio_demo.gd script**: Directly matches `anna/data/kidscancode/audio_manager/Audio Manager/repo/audio_demo.gd`
      - sound_dir export (line 4)
      - _ready() directory scanning (lines 6-16)
      - add_button() implementation (lines 19-25)
      - on_audio_button_pressed() implementation (lines 28-31)
      - _process() stats update (lines 34-37)
    - **audio_manager.gd**: Directly matches `anna/data/kidscancode/audio_manager/Audio Manager/repo/audio_manager.gd`
      - Pool management with available/queue arrays
      - _ready(), _process(), play(), on_stream_finished() methods

- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: The instruction completely describes:
    - The exact scene structure and node hierarchy
    - All property values (margins, columns, spacing, font, font size)
    - The exact label texts
    - The complete logic for scanning files, creating buttons, and updating stats
    - The exported variable and its default value
    - The method names and their implementations
    - No references to "the tutorial", "the video", or other external resources

- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - **Test 1 (lines 13-15)**: AudioDemo must be MarginContainer with audio_demo.gd script
    - **Instruction**: "Create res://scenes/audio_demo.tscn with a MarginContainer root named 'AudioDemo'...attaches res://scripts/audio_demo.gd"

  - **Test 2 (lines 18-19)**: sound_dir should default to "res://assets"
    - **Instruction**: "exporting sound_dir defaulting to res://assets"

  - **Test 3 (lines 21-23)**: Margins should be 20 on all sides
    - **Instruction**: "uses 20px margins on all sides"

  - **Test 4 (lines 25-30)**: CenterContainer exists, GridContainer exists
    - **Instruction**: "Add a CenterContainer with a GridContainer child"

  - **Test 5 (lines 31-32)**: GridContainer should use two columns
    - **Instruction**: "set to two columns"

  - **Test 6 (lines 33-34)**: GridContainer spacing should be 10
    - **Instruction**: "with 10px horizontal and vertical separation"

  - **Test 7 (lines 36-38)**: CanvasLayer missing
    - **Instruction**: "Add a CanvasLayer"

  - **Test 8 (lines 39-41)**: HBoxContainer missing
    - **Instruction**: "with an HBoxContainer top bar"

  - **Test 9 (lines 43-60)**: Four labels with specific texts and Poppins-Medium font at size 24
    - **Instruction**: "containing four Labels: 'Available Streams:', a count label, a VSeparator, and a 'Queue:' label with its own count, all using the Poppins-Medium font at size 24"
    - Labels tested: "Available Streams:", "0", "Queue:", "0"

  - **Test 10 (lines 61-62)**: AudioManager autoload must be present
    - **Instruction**: Implied by "calls AudioManager.play()" and "_process() updates...AudioManager.available.size()"

  - **Test 11 (lines 64-75)**: sound_dir contains .wav/.ogg files
    - **Instruction**: "scans sound_dir for .wav/.ogg files"

  - **Test 12 (lines 77-82)**: Button count must match audio files
    - **Instruction**: "adds a Button for each"

  - **Test 13 (lines 84-91)**: Buttons must connect pressed to on_audio_button_pressed, button labels list filenames
    - **Instruction**: "adds a Button for each with its text set to the filename...pressed connected to on_audio_button_pressed"

  - **Test 14 (lines 93-103)**: Available count label must reflect AudioManager.available size, Queue label must reflect queue size
    - **Instruction**: "updates the count labels to reflect AudioManager.available.size() and AudioManager.queue.size()"

  - **Test 15 (lines 105-117)**: Button press should enqueue audio, labels should update after playback
    - **Instruction**: "on_audio_button_pressed, which calls AudioManager.play() on the file path. Ensure _process() updates the count labels"

  - **Missing Coverage:** None - all tests correspond to instruction requirements

- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - **Test 1**: Check AudioDemo is MarginContainer with audio_demo.gd
    - **Assertions**:
      - `demo is MarginContainer`
      - `demo.get_script().resource_path.ends_with("scripts/audio_demo.gd")`
    - **Instruction coverage**: "Create res://scenes/audio_demo.tscn with a MarginContainer root named 'AudioDemo'...attaches res://scripts/audio_demo.gd"
    - ✓ UNAMBIGUOUS - exact node type and script path specified

  - **Test 2**: Check sound_dir default value
    - **Assertions**: `demo.sound_dir != "res://assets"`
    - **Instruction coverage**: "exporting sound_dir defaulting to res://assets"
    - ✓ UNAMBIGUOUS - exact default value specified

  - **Test 3**: Check margins are 20px
    - **Assertions**:
      - `demo.get_theme_constant("margin_left") != 20`
      - `demo.get_theme_constant("margin_top") != 20`
      - `demo.get_theme_constant("margin_right") != 20`
      - `demo.get_theme_constant("margin_bottom") != 20`
    - **Instruction coverage**: "uses 20px margins on all sides"
    - ✓ UNAMBIGUOUS - exact margin values specified

  - **Test 4**: Check CenterContainer and GridContainer exist
    - **Assertions**:
      - `center is CenterContainer`
      - `grid is GridContainer`
    - **Instruction coverage**: "Add a CenterContainer with a GridContainer child"
    - ✓ UNAMBIGUOUS - exact node types and hierarchy specified

  - **Test 5**: Check GridContainer columns
    - **Assertions**: `grid.columns != 2`
    - **Instruction coverage**: "set to two columns"
    - ✓ UNAMBIGUOUS - exact column count specified

  - **Test 6**: Check GridContainer spacing
    - **Assertions**:
      - `grid.get_theme_constant("h_separation") != 10`
      - `grid.get_theme_constant("v_separation") != 10`
    - **Instruction coverage**: "with 10px horizontal and vertical separation"
    - ✓ UNAMBIGUOUS - exact spacing values specified

  - **Test 7**: Check CanvasLayer exists
    - **Assertions**: `canvas exists and is CanvasLayer`
    - **Instruction coverage**: "Add a CanvasLayer"
    - ✓ UNAMBIGUOUS - node type specified

  - **Test 8**: Check HBoxContainer exists
    - **Assertions**: `bar is HBoxContainer`
    - **Instruction coverage**: "with an HBoxContainer top bar"
    - ✓ UNAMBIGUOUS - node type and parent specified

  - **Test 9**: Check labels text, font, and size
    - **Assertions**:
      - `label.text != "Available Streams:"` (Label)
      - `label.text != "0"` (Label2)
      - `label.text != "Queue:"` (Label4)
      - `label.text != "0"` (Label3)
      - `font.resource_path.ends_with("assets/Poppins-Medium.ttf")`
      - `label.get_theme_font_size("font_size") != 24`
    - **Instruction coverage**: "containing four Labels: 'Available Streams:', a count label, a VSeparator, and a 'Queue:' label with its own count, all using the Poppins-Medium font at size 24"
    - ✓ UNAMBIGUOUS - exact label texts, font file, and font size specified

  - **Test 10**: Check AudioManager autoload exists
    - **Assertions**: `/root/AudioManager` exists
    - **Instruction coverage**: Implicit in "calls AudioManager.play()" - autoload pattern is standard in Godot
    - ✓ UNAMBIGUOUS - AudioManager singleton required by instruction

  - **Test 11**: Check sound_dir can be opened and contains audio files
    - **Assertions**:
      - `DirAccess.open(demo.sound_dir)` succeeds
      - Files with .wav or .ogg extensions exist
    - **Instruction coverage**: "scans sound_dir for .wav/.ogg files"
    - ✓ UNAMBIGUOUS - exact file extensions specified

  - **Test 12**: Check button count matches audio files
    - **Assertions**: `buttons.size() != audio_files.size()`
    - **Instruction coverage**: "adds a Button for each"
    - ✓ UNAMBIGUOUS - "for each" implies 1:1 mapping

  - **Test 13**: Check buttons are connected and have correct text
    - **Assertions**:
      - `b.is_connected("pressed", Callable(demo, "on_audio_button_pressed"))`
      - `button_names == audio_files` (sorted)
    - **Instruction coverage**: "adds a Button for each with its text set to the filename...pressed connected to on_audio_button_pressed"
    - ✓ UNAMBIGUOUS - exact signal connection method and text source specified

  - **Test 14**: Check labels update with AudioManager stats
    - **Assertions**:
      - `Label2.text != str(audio_manager.available.size())`
      - `Label3.text != str(audio_manager.queue.size())`
    - **Instruction coverage**: "updates the count labels to reflect AudioManager.available.size() and AudioManager.queue.size()"
    - ✓ UNAMBIGUOUS - exact property access and conversion to string specified

  - **Test 15**: Check button press enqueues audio and stats update
    - **Assertions**:
      - `audio_manager.queue.size() == 0` after button press (should be > 0)
      - `audio_manager.available.size() != audio_manager.num_players - 1` after processing
      - Labels reflect updated stats
    - **Instruction coverage**: "on_audio_button_pressed, which calls AudioManager.play() on the file path. Ensure _process() updates the count labels"
    - ✓ UNAMBIGUOUS - exact method to call and behavior specified

  - **CRITICAL AMBIGUITY CHECKS**:
    - [x] String formatting (padding, delimiters, exact format) is specified in instruction
      - Label texts are explicitly specified: "Available Streams:", "Queue:", and count labels use str() conversion
    - [x] Exact string values/names are in instruction (not just "format text")
      - Yes: "Available Streams:", "Queue:", filename as button text
    - [x] Number formats (zero-padding, decimal places) are specified
      - N/A - counts are just str() conversion, no special formatting required
    - [x] Any comparison operators (==, !=, >, <, contains, begins_with, ends_with) have clear criteria
      - All comparisons match instruction: exact values, sizes, existence checks
    - [x] Node names, paths, and types match instruction exactly
      - Yes: AudioDemo, CenterContainer, GridContainer, CanvasLayer, HBoxContainer, Label, Label2, VSeparator, Label4, Label3
    - [x] Property values (numbers, booleans, strings) have exact values in instruction
      - Yes: margins=20, columns=2, spacing=10, font_size=24, sound_dir="res://assets"

  - **Ambiguous Tests:** None - all test checks have exact specifications in the instruction

- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: The instruction specifies the exact solution:
    - Exact node hierarchy and names
    - Exact property values
    - Exact method implementations (_ready scans directory, adds buttons, on_audio_button_pressed calls AudioManager.play, _process updates labels)
    - The tests enforce this single solution appropriately
    - No flexibility is needed because the instruction is prescriptive

- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0058)
  - Evidence:
    - Both tasks follow the structure: `tasks/task_XXXX_name/` and `tasks_gt/task_XXXX_name/`
    - Both have `project.godot`, `task_config.json` in root
    - Both have `scenes/` folder with `main.tscn`, `test.tscn`, and scene files
    - Both have `scripts/` folder with game scripts and `test.gd`
    - Both have `assets/` folder

- [x] PROCEED. Check this box is the task is validated and all key checks pass successfully.


# Feature Checklist
- [x] The task contains instructions or goals that are Node/inspector-focused.
  - Evidence:
    - Requires creating specific node hierarchy: MarginContainer → CenterContainer → GridContainer, CanvasLayer → HBoxContainer → Labels
    - Requires setting inspector properties: margins, columns, spacing, font overrides, font sizes, anchors
    - Requires configuring exported variable (sound_dir)

- [x] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence:
    - Must understand the relationship between UI layout (visual) and code behavior (logic)
    - Must understand how buttons dynamically populate a grid (spatial/visual reasoning)
    - Must understand how label updates reflect AudioManager state (temporal/state reasoning)
    - Must understand the connection between file system scanning and UI generation

- [ ] The task contains a multimodal input (such as a image) in the instruction.
  - Evidence: No images are included in the instruction. The instruction is text-only.

# Notes

## Task Overview
This task asks the user to create an audio demo UI that:
1. Scans a directory for audio files (.wav/.ogg)
2. Generates a grid of buttons dynamically, one per audio file
3. Displays live statistics showing AudioManager's available stream count and queue size
4. Connects button presses to the AudioManager to play sounds

## Code Derivation
The task is directly derived from the KidsCanCode audio_manager example project. The tutorial presents an AudioManager autoload pattern that solves the problem of audio being cut off when the emitter node is freed. The example project demonstrates this with a UI that lists audio files and shows statistics.

## Repository Analysis
- **Source repo**: `anna/data/kidscancode/audio_manager/Audio Manager/repo/`
- **Key files**:
  - `audio_manager.gd`: Pool-based audio manager with available/queue arrays
  - `audio_demo.gd`: UI controller that scans directory, creates buttons, updates stats
  - `audio_demo.tscn`: Scene with MarginContainer, grid layout, and stats bar

## Transcript Coverage
The transcript describes:
- The problem: audio players being removed with their parent nodes
- The solution: a pooled AudioManager autoload
- The example project: "reads a folder full of audio files and generates a grid of buttons. Click the button to play the sound. At the top, you can see the audio manager's live statistics."

The instruction covers the example project portion, which is explicitly described in the transcript. All UI elements and behavior match the transcript description.

## Test Coverage Analysis
The test.gd file thoroughly validates:
- Scene structure (node types, hierarchy, names)
- Properties (margins, columns, spacing, fonts, font sizes)
- Label texts and values
- Button generation (count, texts, connections)
- Integration with AudioManager (autoload presence, play() calls, stat updates)
- Dynamic behavior (button press enqueues sound, labels update)

## Validation Results
- **Starting point**: FAILED (as expected) - minimal scene structure provided
- **Ground truth**: PASSED - complete implementation matches all requirements

## Instruction Quality
The instruction is comprehensive and unambiguous:
- Specifies exact node types and hierarchy
- Provides exact property values (20px, 2 columns, 10px spacing, size 24)
- Specifies exact label texts
- Describes complete implementation logic for all methods
- No references to external materials
- Single prescriptive solution

## Potential Concerns
None identified. The task is well-designed, clearly specified, and properly validated.
