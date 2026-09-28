extends SceneTree

func _init():
	var basis = Basis.from_euler(Vector3(-0.122173, 3.141593, 0))
	var t = Transform3D(basis, Vector3(0, 0.6, 0.2))
	print("Cam forward (-Z): ", basis.z)
	var inv_t = t.affine_inverse()
	var spheres = {
		"Sphere": Vector3(1.2, 0.2, 3.8),
		"Sphere2": Vector3(-1.4, -0.4, 4.3),
		"Sphere3": Vector3(2.6, 0.1, 4.5),
		"Sphere4": Vector3(-2.8, 0.0, 3.2),
		"Sphere5": Vector3(0.4, 0.5, 4.0),
	}
	for name in spheres:
		var local = inv_t * spheres[name]
		var fov_y = deg_to_rad(110.0)
		var aspect = 1152.0 / 648.0
		var fov_x = 2.0 * atan(tan(fov_y / 2.0) * aspect)
		var lim_y = -local.z * tan(fov_y / 2.0)
		var lim_x = -local.z * tan(fov_x / 2.0)
		print(name, " cam-space=", local.snapped(Vector3(0.001, 0.001, 0.001)), " in-front=", local.z < 0,
			" within-vert-fov=", abs(local.y) < lim_y, " within-horiz-fov=", abs(local.x) < lim_x)
	quit()
