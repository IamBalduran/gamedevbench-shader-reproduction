# Key Checklist
- [x] The task starting point runs with `uv run gamedevbench  validate $TASK_NAME` and successfully outputs a test failure 
  - Evidence: `uv run gamedevbench validate task_0107` → FAILED with `Surface material is not a ShaderMaterial`.
- [x] The task ground truth runs with `uv run gamedevbench --gt validate $TASK_NAME` and successfully outputs SUCCESS
  - Evidence: `uv run gamedevbench --gt validate task_0107` → PASSED with `View model shader applied and configured`.
- [x] In every task, there exists a valid `main.tscn` and `test.tscn` similar to tasks_gt/task_0107
  - Evidence: `tasks/task_0107/scenes/main.tscn` and `tasks/task_0107/scenes/test.tscn`.
- [x] The task instruction matches the tutorial transcript (See example for documentation). The task instructions must be a subset of the tutorial transcript.
  - Instruction 1 / Transcript 1: "Find MeshInstance3D nodes under the view model and replace each surface material with a ShaderMaterial that uses res://shaders/weapon_clip_and_fov_shader.gdshader." / Transcript: "replaces all of the materials in your view model with this Shader material ... weapon clip and fov Shader ... pointing to the same location".
  - Instruction 2 / Transcript 2: "Copy the base material albedo/metallic/roughness parameters into the shader." / Transcript: "copying over all of the ... properties of the materials from your original weapon view model materials to this new Shader clip fix material".
  - Instruction 3 / Transcript 3: "Set the viewmodel_fov shader parameter to 54.0 when applying the shader." / Transcript: "here we set the knife's view model to 54 fov".
  - Instructions Missing from Transcript: None.
- [x] The task code is directly derived from the repository code. Please document where the derived code is.
  - Evidence: `tasks_gt/task_0107/scripts/weapon_manager.gd` mirrors `tutorials/Majikayo Games/Godot 4.3 Weapon View Model Clip Shader Tutorial + Shader Transform Pipeline Overview/repo/FPSController/weapon_manager/weapon_manager.gd` (function `apply_clip_and_fov_shader_to_view_model`, mesh iteration, shader swap, parameter copy). Shader path adapted from repo `res://FPSController/weapon_manager/weapon_clip_and_fov_shader.gdshader` to task `res://shaders/weapon_clip_and_fov_shader.gdshader`.
- [x] The task instruction is clear, unambiguous, and self-contained. There are no references to the tutorial or other tasks
  - Evidence: Instruction specifies view model mesh scope, shader path, parameters to copy, and viewmodel_fov value; no tutorial references.
- [x] The tests in `test.gd` match the instructions. All tests are contained in the instruction. Similarly, all instructions are in the tests. Explain how to adjust the tests themselves to match the instructions.
  - Test 1 (Shader material swap + shader path), Instruction: "replace each surface material with a ShaderMaterial that uses res://shaders/weapon_clip_and_fov_shader.gdshader".
  - Test 2 (viewmodel_fov == 54.0), Instruction: "set the viewmodel_fov shader parameter to 54.0".
  - Test 3 (albedo copy), Instruction: "copy the base material albedo ... parameters into the shader".
  - Test 4 (metallic copy), Instruction: "copy the base material ... metallic ... parameters into the shader".
  - Test 5 (roughness copy), Instruction: "copy the base material ... roughness parameters into the shader".
  - Missing Coverage: None.
- [x] Each test in `test.gd` is unambiguously defined in the instructions. With just the instruction and the task code (without looking at the tests), it is unambiguously possible to satisfy each test condition.
  - Test 1, Assertions: surface 0 material is ShaderMaterial; shader exists; shader.resource_path == res://shaders/weapon_clip_and_fov_shader.gdshader. Instruction coverage: "replace each surface material with a ShaderMaterial that uses res://shaders/weapon_clip_and_fov_shader.gdshader".
  - Test 2, Assertions: shader parameter "viewmodel_fov" equals 54.0 +/- 0.01. Instruction coverage: "set the viewmodel_fov shader parameter to 54.0".
  - Test 3, Assertions: shader parameter "albedo" equals base material albedo. Instruction coverage: "copy the base material albedo ... into the shader".
  - Test 4, Assertions: shader parameter "metallic" equals base material metallic. Instruction coverage: "copy the base material ... metallic ... into the shader".
  - Test 5, Assertions: shader parameter "roughness" equals base material roughness. Instruction coverage: "copy the base material ... roughness ... into the shader".
  - **CRITICAL AMBIGUITY CHECKS** - For each test, explicitly verify:
    - [x] String formatting (padding, delimiters, exact format) is specified in instruction (N/A - no string formatting tests).
    - [x] Exact string values/names are in instruction (shader path and shader parameter names).
    - [x] Number formats (zero-padding, decimal places) are specified (viewmodel_fov is specified as 54.0).
    - [x] Any comparison operators (==, !=, >, <, contains, begins_with, ends_with) have clear criteria (exact equality for shader path + numeric values).
    - [x] Node names, paths, and types match instruction exactly (tests locate any MeshInstance3D under a view model node; no hardcoded names).
    - [x] Property values (numbers, booleans, strings) have exact values in instruction (shader path, viewmodel_fov, parameter copy).
  - Ambiguous Tests: None.
- [x] If there are multiple solutions to the problem, the tests in `test.gd` are flexible to allow multiple solutions. Mark this as completed if there is only one solution to the problem and that solution is clearly decipherable from the instructions.
  - Evidence: Tests validate only outcomes (shader swap + copied parameters) and do not mandate a specific implementation.
- [x] The folder and file names are consistent with other tasks (tasks_gt/task_0107)
  - Evidence: Task uses standard layout (`assets`, `scenes`, `scripts`, `shaders`, `project.godot`, `task_config.json`).
- [x] PROCEED. Check this box is the task is validated and all key checks pass successfully.


# Feature Checklist
- [x] The task contains instructions or goals that are Node/inspector-focused. 
  - Evidence: Instruction targets view model meshes/materials and shader parameters.
- [ ] The task contains or requires multimodal reasoning or understanding to complete.
  - Evidence
- [ ] The task contains a multimodal input (such as a image) in the instruction.
  - Evidence

# Notes
- Removed shadow casting requirement from instruction and tests to match transcript.
- Updated tests to avoid hardcoded node names and to verify metallic/roughness parameter copying.
