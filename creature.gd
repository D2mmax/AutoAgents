extends Node3D

const SEGMENT_COUNT = 12
const SEGMENT_DISTANCE = 0.4
const SEGMENT_RADIUS = 0.12

var head: MeshInstance3D
var segments: Array = []
var velocity: Vector3 = Vector3(1, 0, 0)
var time: float = 0.0

func _ready():
	head = get_node("Head")
	_create_segments()

func _create_segments():
	for i in range(SEGMENT_COUNT):
		var seg = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		var t = float(i) / float(SEGMENT_COUNT)
		mesh.radius = lerp(SEGMENT_RADIUS, SEGMENT_RADIUS * 0.3, t)
		mesh.height = mesh.radius * 2
		seg.mesh = mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.05, 0.0, 0.1)
		mat.emission_enabled = true
		mat.emission = Color(0.4, 0.0, 1.0).lerp(Color(0.0, 0.5, 1.0), t)
		mat.emission_energy_multiplier = 1.5
		seg.material_override = mat
		add_child(seg)
		seg.global_position = head.global_position - Vector3(i * SEGMENT_DISTANCE, 0, 0)
		segments.append(seg)

func _process(delta):
	time += delta
	_update_head(delta)
	_update_segments()

func _update_head(delta):
	var noise_x = sin(time * 0.7) * cos(time * 0.4) 
	var noise_y = sin(time * 0.5 + 1.3) * cos(time * 0.6)
	var noise_z = sin(time * 0.3 + 2.1) * cos(time * 0.8)
	var steer = Vector3(noise_x, noise_y, noise_z) * 0.8
	velocity += steer * delta
	velocity = velocity.normalized() * 2.0
	head.global_position += velocity * delta
	if velocity.length() > 0.01:
		head.look_at(head.global_position + velocity, Vector3.UP)

func _update_segments():
	for i in range(segments.size()):
		var target = head.global_position if i == 0 else segments[i-1].global_position
		var diff = target - segments[i].global_position
		if diff.length() > SEGMENT_DISTANCE:
			segments[i].global_position += diff.normalized() * (diff.length() - SEGMENT_DISTANCE)
