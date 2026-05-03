extends Node3D

const SEGMENT_COUNT = 12
const SEGMENT_DISTANCE = 0.4
const SEGMENT_RADIUS = 0.12

var head: MeshInstance3D
var segments: Array = []
var velocity: Vector3 = Vector3(1, 0, 0)
var time: float = 0.0
const BOUNDS = 10.0

# Needs
var hunger: float = 0.0
var curiosity: float = 0.0
var fear: float = 0.0
# Needs rates
const HUNGER_RATE = 0.02
const CURIOSITY_RATE = 0.01
const FEAR_DRAIN_RATE = 0.05
# Thresholds
const CURIOUS_RANGE = 5.0
const ORBIT_RANGE = 3.5
const FLEE_RANGE = 1.0
const FOOD_DETECT_RANGE = 8.0
const HUNGER_THRESHOLD = 0.7
# State durations
const FEEDING_DURATION = 0.8
const DISPLAYING_DURATION = 7.0
const AGITATED_DURATION = 4.0
const CURIOUS_DURATION = 3.5
const FLEEING_DURATION = 3.0
const MIN_STATE_DURATION = 3.0
# References
var player_head: Node3D = null
var left_hand: Node3D = null
var right_hand: Node3D = null
var food_target: Node3D = null
# Hunger timer
var time_since_eaten: float = 0.0
enum State {DRIFTING, CURIOUS, HUNTING, FEEDING, ORBITING, FLEEING, AGITATED, DISPLAYING, SEARCHING}
var current_state: State = State.DRIFTING
var state_timer: float = 0.0
func _ready():
	head = get_node("Head")
	_create_segments()
	#Get player references from main scene
	var origin = get_node("/root/Node3D/XROrigin3D")
	player_head = origin.get_node("XRCamera3D")
	left_hand = origin.get_node("LeftHand")
	right_hand = origin.get_node("RightHand")

func _update_needs(delta):
	#Hunger Grows over time
	hunger = min(hunger + HUNGER_RATE * delta,1.0)
	time_since_eaten += delta
	
	#Curiosity grows when alone, faster near player
	var dist_to_player = head.global_position.distance_to(player_head.global_position)
	if dist_to_player < CURIOUS_RANGE * 2:
		curiosity = min(curiosity + CURIOSITY_RATE * 3 * delta, 1.0)
	else:
		curiosity = min(curiosity + CURIOSITY_RATE * delta, 1.0)
	#Fear drains naturally over time
	fear = max(fear - FEAR_DRAIN_RATE * delta, 0.0)
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
	_update_needs(delta)
	_update_state(delta)
	_update_segments()

func _update_head(delta):
	var noise_x = sin(time * 0.7) * cos(time * 0.4) 
	var noise_y = sin(time * 0.5 + 1.3) * cos(time * 0.6)
	var noise_z = sin(time * 0.3 + 2.1) * cos(time * 0.8)
	var steer = Vector3(noise_x, noise_y, noise_z) * 0.8
	velocity += steer * delta
	velocity = velocity.normalized() * 2.0
	head.global_position += velocity * delta
	_apply_bounds()
	if velocity.length() > 0.01:
		head.look_at(head.global_position + velocity, Vector3.UP)

func _update_segments():
	for i in range(segments.size()):
		var target = head.global_position if i == 0 else segments[i-1].global_position
		var diff = target - segments[i].global_position
		if diff.length() > SEGMENT_DISTANCE:
			segments[i].global_position += diff.normalized() * (diff.length() - SEGMENT_DISTANCE)

func _apply_bounds():
	var pos = head.global_position
	if pos.x > BOUNDS or pos.x < -BOUNDS:
		velocity.x *= -1
	if pos.y > BOUNDS or pos.y < -BOUNDS:
		velocity.y *= -1
	if pos.z > BOUNDS or pos.z < -BOUNDS:
		velocity.z *= -1



func _state_drifting(delta):
	_update_head(delta)

func _state_curious(delta):
	pass

func _state_hunting(delta):
	pass

func _state_feeding(delta):
	pass

func _state_orbiting(delta):
	pass

func _state_fleeing(delta):
	pass

func _state_agitated(delta):
	pass

func _state_displaying(delta):
	pass

func _state_searching(delta):
	pass

func _update_state(delta):
	state_timer += delta
	match current_state:
		State.DRIFTING:
			_state_drifting(delta)
		State.CURIOUS:
			_state_curious(delta)
		State.HUNTING:
			_state_hunting(delta)
		State.FEEDING:
			_state_feeding(delta)
		State.ORBITING:
			_state_orbiting(delta)
		State.FLEEING:
			_state_fleeing(delta)
		State.AGITATED:
			_state_agitated(delta)
		State.DISPLAYING:
			_state_displaying(delta)
		State.SEARCHING:
			_state_searching(delta)

func change_state(new_state: State):
	current_state = new_state
	state_timer = 0.0
