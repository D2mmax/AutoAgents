extends Node3D

# Planet data: [node_name, radius]
const PLANETS = [
	["SmallPlanet", 1.0],
	["MediumPlanet", 1.5],
	["LargePlanet", 2.0],
]

func _ready():
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		$Camera3D.current = true
	_setup_planet_colliders()
	_spawn_food(5)
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.autostart = true
	timer.timeout.connect(_on_respawn_timer)
	add_child(timer)

func _setup_planet_colliders():
	for planet_data in PLANETS:
		var planet = get_node_or_null(planet_data[0])
		var radius = planet_data[1]
		if not planet:
			continue
		# Wrap in StaticBody3D
		var body = StaticBody3D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		planet.add_child(body)
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = radius
		col.shape = shape
		body.add_child(col)
		print("Collider added to: ", planet_data[0])

func _on_respawn_timer():
	var food_count = get_tree().get_nodes_in_group("food").size()
	if food_count < 3:
		_spawn_food(3 - food_count)

func _spawn_food(count: int):
	for i in range(count):
		_spawn_food_near_planet()

func _spawn_food_near_planet():
	var planet_data = PLANETS[randi() % PLANETS.size()]
	var planet = get_node_or_null(planet_data[0])
	var planet_radius = planet_data[1]
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
	if planet:
		# Spawn well clear of planet surface — min 2.5 units beyond radius
		var offset = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var spawn_dist = planet_radius + randf_range(2.5, 4.0)
		food.global_position = planet.global_position + offset * spawn_dist
	else:
		food.global_position = Vector3(randf_range(-8.0, 8.0), randf_range(-3.0, 3.0), randf_range(-8.0, 8.0))
