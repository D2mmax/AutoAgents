extends Node3D

func _ready():
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		$Camera3D.current = true
	_spawn_food(5)
	# Respawn food every 15 seconds
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.autostart = true
	timer.timeout.connect(_on_respawn_timer)
	add_child(timer)

func _on_respawn_timer():
	var food_count = get_tree().get_nodes_in_group("food").size()
	if food_count < 3:
		_spawn_food(3 - food_count)

func _spawn_food(count: int):
	for i in range(count):
		var food = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.2
		mesh.height = 0.4
		food.mesh = mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.0, 0.05, 0.0)
		mat.emission_enabled = true
		mat.emission = Color(0.0, 1.0, 0.4)
		mat.emission_energy_multiplier = 2.5
		food.material_override = mat
		food.add_to_group("food")
		add_child(food)
		food.global_position = Vector3(
			randf_range(-8.0, 8.0),
			randf_range(-3.0, 3.0),
			randf_range(-8.0, 8.0)
		)
