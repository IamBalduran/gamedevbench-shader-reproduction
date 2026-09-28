extends Node

func _ready():
    run_validation()

func fail(message:String) -> void:
    print("VALIDATION_FAILED: %s" % message)
    get_tree().quit()

func succeed(message:String) -> void:
    print("VALIDATION_PASSED: %s" % message)
    get_tree().quit()

func run_validation() -> void:
    var explosion_root = get_node_or_null("Main/Explosion")
    if explosion_root == null:
        fail("Explosion node missing")
        return

    var chunks = explosion_root.get_node_or_null("ArcingChunks")
    if chunks == null or not (chunks is GPUParticles3D):
        fail("ArcingChunks GPUParticles3D missing")
        return

    if not is_equal_approx(chunks.lifetime, 3.0):
        fail("ArcingChunks lifetime must be 3 seconds")
        return
    if not chunks.one_shot:
        fail("ArcingChunks needs one_shot enabled")
        return
    if chunks.randomness < 0.6:
        fail("ArcingChunks randomness should be at least 0.6")
        return
    if chunks.material_override == null or not (chunks.material_override is StandardMaterial3D):
        fail("ArcingChunks must use a StandardMaterial3D override")
        return
    var chunk_mat : StandardMaterial3D = chunks.material_override
    if chunk_mat.billboard_mode != BaseMaterial3D.BILLBOARD_ENABLED:
        fail("Chunk material must billboard around camera")
        return
    if chunk_mat.emission_enabled == false or chunk_mat.emission_energy_multiplier < 15.0:
        fail("Chunk material emission should be bright (~18)")
        return

    if chunks.draw_pass_1 == null or not (chunks.draw_pass_1 is QuadMesh):
        fail("ArcingChunks draw pass must be a QuadMesh")
        return

    var chunk_process = chunks.process_material
    if chunk_process == null or not (chunk_process is ParticleProcessMaterial):
        fail("ArcingChunks needs a ParticleProcessMaterial")
        return
    if chunk_process.collision_mode != 1:
        fail("Enable rigid collision on ArcingChunks")
        return
    if chunk_process.collision_bounce < 0.99:
        fail("Collision bounce must be 1 for ricochet")
        return
    if not chunk_process.collision_use_scale:
        fail("collision_use_scale should be enabled")
        return
    if chunk_process.sub_emitter_mode != 1:
        fail("Sub emitter mode must be CONSTANT")
        return
    if chunk_process.sub_emitter_frequency < 90.0:
        fail("Sub emitter frequency should be around 100 Hz")
        return
    if chunk_process.initial_velocity_min > 8.5 or chunk_process.initial_velocity_max < 11.5:
        fail("Chunk velocities should stay in 8–12 m/s range")
        return

    if chunks.sub_emitter != NodePath("../ArcingChunkSmoke"):
        fail("ArcingChunks sub_emitter must point to ../ArcingChunkSmoke")
        return

    var collision_box = explosion_root.get_node_or_null("ArcingChunkCollision")
    if collision_box == null or not (collision_box is GPUParticlesCollisionBox3D):
        fail("GPUParticlesCollisionBox3D needs to exist under Explosion")
        return
    if collision_box.size != Vector3(40, 1, 40):
        fail("Collision box size must be 40×1×40 as in the tutorial")
        return

    var smoke = explosion_root.get_node_or_null("ArcingChunkSmoke")
    if smoke == null or not (smoke is GPUParticles3D):
        fail("ArcingChunkSmoke GPUParticles3D missing")
        return
    if smoke.amount < 900:
        fail("ArcingChunkSmoke should emit hundreds of particles (>=1000)")
        return
    if not is_equal_approx(smoke.lifetime, 3.0):
        fail("ArcingChunkSmoke lifetime should be 3 seconds")
        return
    if smoke.material_override == null or not (smoke.material_override is ShaderMaterial):
        fail("Smoke needs the distortion ShaderMaterial override")
        return
    var shader_mat : ShaderMaterial = smoke.material_override
    var shader = shader_mat.shader
    if shader == null or shader.resource_path != "res://assets/shaders/SmokeShader.gdshader":
        fail("Smoke shader must point to assets/shaders/SmokeShader.gdshader")
        return
    if not shader_mat.get_shader_parameter("NoiseTexture") or shader_mat.get_shader_parameter("NoiseTexture").resource_path != "res://assets/shaders/NoiseResource.tres":
        fail("Smoke shader NoiseTexture parameter must use NoiseResource.tres")
        return

    var smoke_process = smoke.process_material
    if smoke_process == null or not (smoke_process is ParticleProcessMaterial):
        fail("ArcingChunkSmoke needs a ParticleProcessMaterial")
        return
    if not smoke_process.turbulence_enabled:
        fail("Smoke turbulence must be enabled")
        return
    if smoke_process.turbulence_influence_min < 0.004 or smoke_process.turbulence_influence_max < 0.009:
        fail("Smoke turbulence influence should be ~0.005–0.01")
        return
    if smoke_process.scale_curve == null or smoke_process.color_ramp == null:
        fail("Smoke process material requires scale curve and color ramp")
        return

    succeed("Arcing chunk debris and smoke configured with collision + sub emitter")
