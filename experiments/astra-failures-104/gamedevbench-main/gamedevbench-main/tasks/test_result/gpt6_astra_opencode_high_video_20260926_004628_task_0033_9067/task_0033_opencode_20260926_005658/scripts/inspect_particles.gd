extends SceneTree

func _initialize():
	print("Collision enum: ", ParticleProcessMaterial.COLLISION_RIGID)
	print("Constant sub-emission enum: ", ParticleProcessMaterial.SUB_EMITTER_CONSTANT)
	print("Billboard particle enum: ", BaseMaterial3D.BILLBOARD_PARTICLES)
	var material = ParticleProcessMaterial.new()
	for property in material.get_property_list():
		var name = property.name
		if "sub_emitter" in name or "collision" in name or "angle" in name or "angular_velocity" in name or "particle_flag" in name or "turbulence" in name or name == "direction" or name == "spread":
			print(name, " = ", material.get(name))
	quit()
