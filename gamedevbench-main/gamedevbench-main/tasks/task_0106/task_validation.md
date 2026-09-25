# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure 
  - Evidence: `uv run gamedevbench validate task_0106` -> FAILED with `outline_effect.gd missing 'RenderingServer.get_rendering_device()'`.
- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: `uv run gamedevbench --gt validate task_0106` -> PASSED, `Task completed successfully`.
- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0106
  - Evidence: `tasks/task_0106/scenes/main.tscn`, `tasks/task_0106/scenes/test.tscn`, `tasks_gt/task_0106/scenes/main.tscn`, `tasks_gt/task_0106/scenes/test.tscn`.
- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - “Implement the OutlineEffect compositor script ...” / “create a script for our compositor effect ... make sure it extends compositor effect ... give it a class name ... let's just call it outline effect ... give an at tool”
  - “... outline.glsl compute shader ... depth-based outline effect.” / “create the Shader ... outline.glsl ... depth based outline ... compare the depth of nearby pixels and if there's a great difference between them then we draw an outline”
  - “script must create the RenderingDevice compute pipeline” / “rendering device ... compute pipeline create and then the Shader”
  - “initialize a storage buffer for parameters” / “parameter storage buffer ... storage buffer create with the size of the data and then the data itself”
  - “add a depth sampler” / “add in a sampler for a depth texture ... depth sampler ... sampler create”
  - “in the render callback bind the parameter buffer, color image, and depth texture uniforms, then dispatch the compute shader” / “create a uniform ... color layer uniform ... depth layer uniform ... bindings ... uniform set ... compute list bind ... dispatch it”
  - “shader must declare the params buffer (including inverse projection matrix)” / “add to parameters a mat4 ... inverse projection matrix ... pass inverse projection matrix”
  - “read from the color image and depth texture” / “specify the color uniform ... uniform image2D ... color image” and “specify our depth texture ... sampler”
  - “convert depth to linear space” / “depth texture is not linear ... convert it to linear ... get linear depth”
  - “compare neighboring depths using a sample radius” / “compare the depth of nearby pixels ... specify a sample size”
  - “write the outlined color back to the color image” / “imageStore ... render black ... outline ... color image”
  - Instructions Missing from Transcript: None found.
- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: `tutorials/DevPoodle/Making a 3D Outline Effect - Using Godot Engine/repo/outline_compositor_effect/outline_effect.gd` matches `tasks_gt/task_0106/scripts/outline_effect.gd` (no diff).
  - Evidence: `tutorials/DevPoodle/Making a 3D Outline Effect - Using Godot Engine/repo/outline_compositor_effect/outline.glsl` matches `tasks_gt/task_0106/outline.glsl` (only newline difference).
- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: `tasks/task_0106/task_config.json` explicitly names all required identifiers and bindings (e.g., `@tool`, `class_name OutlineEffect`, `binding = 0`, `uniform image2D color_image`, `sampler2D depth_texture`, `sample_size`, `gl_GlobalInvocationID`, `imageStore`, `get_linear_depth`).
- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - Evidence: Every string asserted in `tasks/task_0106/scripts/test.gd` is listed verbatim in the instruction, and the instruction does not introduce extra requirements beyond those checks.
  - No test adjustments needed.
- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - Evidence: The instruction enumerates exact tokens for script setup (`@tool`, `extends CompositorEffect`, `class_name OutlineEffect`, `RenderingServer.get_rendering_device()`, `rd.compute_pipeline_create`, `storage_buffer_create`, `sampler_create`, `get_render_scene_buffers`, `get_internal_size`, `get_color_layer(0)`, `get_depth_layer(0)`, `buffer_update`, `uniform_set_create`, `compute_list_dispatch`) and shader requirements (`#[compute]`, `layout(local_size_x = 8`, `binding = 0`, `readonly buffer Params`, `mat4 inv_proj_mat`, `uniform image2D color_image`, `sampler2D depth_texture`, `get_linear_depth`, `gl_GlobalInvocationID`, `imageStore`, `sample_size`).
  - **CRITICAL AMBIGUITY CHECKS** - For each test, explicitly verify:
    - [x] String formatting (padding, delimiters, exact format) is specified in instruction
    - [x] Exact string values/names are in instruction (not just "format text")
    - [x] Number formats (zero-padding, decimal places) are specified
    - [x] Any comparison operators (==, !=, >, <, contains, begins_with, ends_with) have clear criteria
    - [x] Node names, paths, and types match instruction exactly
    - [x] Property values (numbers, booleans, strings) have exact values in instruction
  - Ambiguous Tests: None found; all string-contains checks are anchored by exact tokens in the instruction.
- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: The instruction intentionally constrains the solution to the exact tokens asserted by the tests, so the required solution is uniquely decipherable.
- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0106)
  - Evidence: `tasks/task_0106/` and `tasks_gt/task_0106/` use the standard layout (`assets`, `scenes`, `scripts`, `project.godot`, `task_config.json`).
- [x] PROCEED. Check this box is the task is validated and all key checks pass successfully.


# Feature Checklist
- [ ] The task contains instructions or goals that are Node/inspector-focused. 
  - Evidence: Instruction is focused on code/shader implementation, not Node/inspector edits.
- [ ] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence: Instruction is textual and code-focused only.
- [ ] The task contains a multimodal input (such as a image) in the instruction.
  - Evidence: No images or other multimodal inputs in the instruction.

# Notes

- Validation failures are expected for the starting task due to placeholder script/shader. The instruction and tests need alignment on exact identifiers, bindings, and shader/local size details.

# Examples

## Matching task instruction to transcript

- (Included above in Key Checklist)
## Matching Test to Instruction

- See Key Checklist “tests match instructions” and “unambiguous” sections.
## Identifying Ambiguous Tests (CRITICAL)

- See Key Checklist “Ambiguous Tests” section.
