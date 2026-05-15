extends Node3D

const SEGMENT_COUNT = 12
const SEGMENT_DISTANCE = 0.2
const SEGMENT_RADIUS = 0.12

var head: MeshInstance3D
var segments: Array = []
var velocity: Vector3 = Vector3(1, 0, 0)
var time: float = 0.0

const BOUNDS = 13.0

# Needs  b
var hunger: float = 0.0
var curiosity: float = 0.0

# Needs rates
const HUNGER_RATE = 0.05
const CURIOSITY_RATE = 0.008
const HAND_FLEE_RANGE = 0.3

# Distance thresholds
const CURIOUS_RANGE = 8.0
const ORBIT_RANGE = 2.5
const FLEE_RANGE = 1.2
const FOOD_DETECT_RANGE = 12.0
const FOOD_EAT_RANGE = 0.6
const HUNGER_THRESHOLD = 0.3

# Speed constants
const DRIFT_SPEED = 2.0
const HUNT_SPEED = 4.0
const FLEE_SPEED = 5.5
const ORBIT_SPEED = 3.0
const SEARCH_SPEED = 3.5

# State durations
const FEEDING_DURATION = 0.8
const DISPLAYING_DURATION = 7.0
const AGITATED_DURATION = 4.0
const CURIOUS_DURATION = 3.5
const FLEEING_DURATION = 3.0
const MIN_STATE_DURATION = 1.5

# Orbit
var orbit_angle: float = 0.0
const ORBIT_RADIUS = 2.5

# References
var player_head: Node3D = null
var left_hand: Node3D = null
var right_hand: Node3D = null
var food_target: Node3D = null
var time_since_eaten: float = 0.0

enum State {DRIFTING, CURIOUS, HUNTING, FEEDING, ORBITING, FLEEING, AGITATED, DISPLAYING, SEARCHING}
var current_state: State = State.DRIFTING
var state_timer: float = 0.0

# Colour per state
const STATE_COLOURS = {
	"DRIFTING":   Color(0.4, 0.0, 1.0),
	"CURIOUS":    Color(0.0, 0.8, 1.0),
	"HUNTING":    Color(1.0, 0.4, 0.0),
	"FEEDING":    Color(0.0, 1.0, 0.3),
	"ORBITING":   Color(0.8, 0.0, 1.0),
	"FLEEING":    Color(1.0, 0.0, 0.1),
	"AGITATED":   Color(1.0, 0.2, 0.0),
	"DISPLAYING": Color(1.0, 1.0, 0.0),
	"SEARCHING":  Color(1.0, 0.7, 0.0),
}

# HUD label attached to camera
var hud_label: Label3D = null

func _ready():
	head = get_node("Head")
	_create_segments()
	# Assign references FIRST before any await
	var origin = get_node_or_null("/root/Node3D/XROrigin3D")
	if origin:
		player_head = origin.get_node_or_null("XRCamera3D")
		left_hand   = origin.get_node_or_null("LeftHand")
		right_hand  = origin.get_node_or_null("RightHand")
	if not player_head:
		player_head = get_node_or_null("/root/Node3D/Camera3D")
	# Wait for XR to fully initialise then attach HUD
	await get_tree().create_timer(2.0).timeout
	_setup_hud_label()

func _setup_hud_label():
	if not player_head:
		print("HUD: player_head is null, cannot attach label")
		return
	hud_label = Label3D.new()
	hud_label.font_size = 16
	hud_label.modulate = Color.WHITE
	hud_label.no_depth_test = true
	hud_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# Top-left corner of view, fixed relative to camera
	hud_label.position = Vector3(-0.55, 0.32, -2.5)
	player_head.add_child(hud_label)
	print("HUD label attached to: ", player_head.name)

func _update_hud_label():
	if not hud_label:
		return
	hud_label.text = "STATE: %s\nHUNGER:    %.2f\nCURIOSITY: %.2f" % [
		State.keys()[current_state], hunger, curiosity
	]

# ─── Segment creation ─────────────────────────────────────────────────────────

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

func _add_segment():
	var seg = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = SEGMENT_RADIUS * 0.3
	mesh.height = mesh.radius * 2
	seg.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.0, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.5, 1.0)
	mat.emission_energy_multiplier = 1.5
	seg.material_override = mat
	add_child(seg)
	seg.global_position = segments[-1].global_position if segments.size() > 0 else head.global_position
	segments.append(seg)

func _set_colour(c: Color):
	# Update head
	var head_mat = head.material_override as StandardMaterial3D
	if head_mat:
		head_mat.emission = c * 1.5
	# Update segments
	for i in range(segments.size()):
		var t = float(i) / float(segments.size())
		var mat = segments[i].material_override as StandardMaterial3D
		if mat:
			mat.emission = c.lerp(c * 0.2, t)

# ─── Movement helpers ─────────────────────────────────────────────────────────

func _update_head(delta):
	var noise_x = sin(time * 0.7) * cos(time * 0.4)
	var noise_y = sin(time * 0.5 + 1.3) * cos(time * 0.6)
	var noise_z = sin(time * 0.3 + 2.1) * cos(time * 0.8)
	var steer = Vector3(noise_x, noise_y, noise_z) * 0.8
	velocity += steer * delta
	velocity = velocity.normalized() * DRIFT_SPEED
	head.global_position += velocity * delta
	_apply_bounds()
	if velocity.length() > 0.01:
		head.look_at(head.global_position + velocity, Vector3.UP)

func _seek(target_pos: Vector3, speed: float, delta: float):
	var desired = (target_pos - head.global_position).normalized() * speed
	velocity += (desired - velocity) * delta * 3.0
	velocity = velocity.normalized() * speed
	head.global_position += velocity * delta
	_apply_bounds()
	if velocity.length() > 0.01:
		head.look_at(head.global_position + velocity, Vector3.UP)

func _get_nearest_hand_position() -> Vector3:
	var best_pos = player_head.global_position if player_head else Vector3.ZERO
	var min_dist = INF
	if left_hand:
		var d = head.global_position.distance_to(left_hand.global_position)
		if d < min_dist:
			min_dist = d
			best_pos = left_hand.global_position
	if right_hand:
		var d = head.global_position.distance_to(right_hand.global_position)
		if d < min_dist:
			min_dist = d
			best_pos = right_hand.global_position
	return best_pos

func _flee_from(target_pos: Vector3, speed: float, delta: float):
	var away = (head.global_position - target_pos).normalized() * speed
	velocity += (away - velocity) * delta * 3.0
	velocity = velocity.normalized() * speed
	head.global_position += velocity * delta
	_apply_bounds()
	if velocity.length() > 0.01:
		head.look_at(head.global_position + velocity, Vector3.UP)

func _update_segments():
	for i in range(segments.size()):
		var target = head.global_position if i == 0 else segments[i - 1].global_position
		var diff = target - segments[i].global_position
		if diff.length() > SEGMENT_DISTANCE:
			segments[i].global_position += diff.normalized() * (diff.length() - SEGMENT_DISTANCE)

func _apply_bounds():
	var pos = head.global_position
	var margin = 3.0
	var force = Vector3.ZERO
	if pos.x > BOUNDS - margin: force.x -= (pos.x - (BOUNDS - margin)) / margin
	if pos.x < -BOUNDS + margin: force.x += ((-BOUNDS + margin) - pos.x) / margin
	if pos.y > BOUNDS - margin: force.y -= (pos.y - (BOUNDS - margin)) / margin
	if pos.y < -BOUNDS + margin: force.y += ((-BOUNDS + margin) - pos.y) / margin
	if pos.z > BOUNDS - margin: force.z -= (pos.z - (BOUNDS - margin)) / margin
	if pos.z < -BOUNDS + margin: force.z += ((-BOUNDS + margin) - pos.z) / margin
	velocity += force * 5.0

func _find_food():
	var food_nodes = get_tree().get_nodes_in_group("food")
	if food_nodes.is_empty():
		food_target = null
		return
	var closest_dist = INF
	var closest = null
	for f in food_nodes:
		var d = head.global_position.distance_to(f.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = f
	food_target = closest if closest_dist < FOOD_DETECT_RANGE else null

# ─── Needs ────────────────────────────────────────────────────────────────────

func _update_needs(delta):
	hunger = min(hunger + HUNGER_RATE * delta, 1.0)
	time_since_eaten += delta
	if player_head:
		var d = head.global_position.distance_to(player_head.global_position)
		curiosity = min(curiosity + CURIOSITY_RATE * (3.0 if d < CURIOUS_RANGE * 2 else 1.0) * delta, 1.0)
	# Curiosity drains while orbiting or displaying
	if current_state == State.ORBITING or current_state == State.DISPLAYING:
		curiosity = max(curiosity - 0.05 * delta, 0.0)

# ─── States ───────────────────────────────────────────────────────────────────

func _get_nearest_hand_distance() -> float:
	var min_dist = INF
	if left_hand:
		min_dist = min(min_dist, head.global_position.distance_to(left_hand.global_position))
	if right_hand:
		min_dist = min(min_dist, head.global_position.distance_to(right_hand.global_position))
	return min_dist

func _check_hand_flee():
	if _get_nearest_hand_distance() < HAND_FLEE_RANGE:
		change_state(State.FLEEING)

func _state_drifting(delta):
	_update_head(delta)
	_check_hand_flee()
	if not player_head or state_timer < MIN_STATE_DURATION:
		return
	var dist = head.global_position.distance_to(player_head.global_position)
	var hand_dist = _get_nearest_hand_distance()
	if hand_dist < FLEE_RANGE:
		change_state(State.FLEEING)
	elif dist < ORBIT_RANGE and curiosity > 0.6:
		change_state(State.ORBITING)
	elif dist < CURIOUS_RANGE and curiosity > 0.3:
		change_state(State.CURIOUS)
	elif food_target and hunger > HUNGER_THRESHOLD:
		change_state(State.HUNTING)
	elif hunger > 0.8:
		change_state(State.SEARCHING)

func _state_curious(delta):
	if not player_head:
		change_state(State.DRIFTING)
		return
	var dist = head.global_position.distance_to(player_head.global_position)
	var target = player_head.global_position + (head.global_position - player_head.global_position).normalized() * (ORBIT_RANGE + 1.0)
	_seek(target, 1.5, delta)
	curiosity = min(curiosity + 0.05 * delta, 1.0)
	var hand_dist = _get_nearest_hand_distance()
	if hand_dist < HAND_FLEE_RANGE:
		change_state(State.FLEEING)
	elif dist < ORBIT_RANGE and state_timer > CURIOUS_DURATION:
		change_state(State.ORBITING)
	elif state_timer > CURIOUS_DURATION * 2.5:
		change_state(State.DRIFTING)
	elif food_target and hunger > HUNGER_THRESHOLD:
		change_state(State.HUNTING)

func _state_hunting(delta):
	if not food_target:
		change_state(State.SEARCHING)
		return
	var dist = head.global_position.distance_to(food_target.global_position)
	var speed = lerp(HUNT_SPEED, 1.5, clamp(1.0 - dist / 3.0, 0.0, 1.0))
	_seek(food_target.global_position, speed, delta)
	if dist < FOOD_EAT_RANGE:
		change_state(State.FEEDING)

func _state_feeding(delta):
	_update_head(delta)
	var pulse = abs(sin(state_timer * 8.0))
	_set_colour(Color(0.0, 1.0, 0.3) * (0.4 + pulse * 0.6))
	if state_timer >= FEEDING_DURATION:
		hunger = 0.0
		time_since_eaten = 0.0
		_add_segment()
		if food_target:
			food_target.queue_free()
			food_target = null
		change_state(State.DRIFTING)

func _state_orbiting(delta):
	if not player_head:
		change_state(State.DRIFTING)
		return
	var hand_dist = _get_nearest_hand_distance()
	if hand_dist < HAND_FLEE_RANGE:
		change_state(State.FLEEING)
		return
	orbit_angle += delta * 0.8
	var target = player_head.global_position + Vector3(
		cos(orbit_angle) * ORBIT_RADIUS,
		sin(orbit_angle * 0.5) * 1.2,
		sin(orbit_angle) * ORBIT_RADIUS
	)
	_seek(target, ORBIT_SPEED, delta)
	curiosity = max(curiosity - 0.02 * delta, 0.0)
	if state_timer > DISPLAYING_DURATION * 0.6:
		change_state(State.DISPLAYING)
	elif state_timer > DISPLAYING_DURATION * 2.0:
		change_state(State.DRIFTING)

func _state_fleeing(delta):
	_flee_from(_get_nearest_hand_position(), FLEE_SPEED, delta)
	if state_timer > FLEEING_DURATION:
		change_state(State.AGITATED)

func _state_agitated(delta):
	# Very fast and chaotic, with rapid colour flicker
	var noise_x = sin(time * 2.1) * cos(time * 1.7)
	var noise_y = sin(time * 1.8 + 1.3) * cos(time * 2.3)
	var noise_z = sin(time * 2.4 + 2.1) * cos(time * 1.5)
	velocity += Vector3(noise_x, noise_y, noise_z) * 2.0 * delta
	velocity = velocity.normalized() * DRIFT_SPEED * 2.5
	head.global_position += velocity * delta
	_apply_bounds()
	if velocity.length() > 0.01:
		head.look_at(head.global_position + velocity, Vector3.UP)
	# Flicker between red and white rapidly
	var flicker = abs(sin(state_timer * 15.0))
	_set_colour(Color(1.0, flicker * 0.3, flicker * 0.3))
	if state_timer > AGITATED_DURATION:
		change_state(State.DRIFTING)

func _state_displaying(delta):
	if not player_head:
		change_state(State.DRIFTING)
		return
	# Hypnotic spirograph orbit - two sine waves at different frequencies
	orbit_angle += delta * 1.5
	var r1 = ORBIT_RADIUS * 2.0
	var r2 = ORBIT_RADIUS * 0.8
	var target = player_head.global_position + Vector3(
		cos(orbit_angle) * r1 + cos(orbit_angle * 3.0) * r2,
		sin(orbit_angle * 2.0) * r1 * 0.6,
		sin(orbit_angle) * r1 + sin(orbit_angle * 3.0) * r2
	)
	_seek(target, ORBIT_SPEED * 2.0, delta)
	# Fast rainbow that also pulses brightness
	var brightness = 0.6 + abs(sin(state_timer * 4.0)) * 0.4
	_set_colour(Color.from_hsv(fmod(state_timer * 0.6, 1.0), 1.0, brightness))
	# Head pulses in size
	head.scale = Vector3.ONE * (1.0 + sin(state_timer * 5.0) * 0.4)
	if state_timer > DISPLAYING_DURATION:
		head.scale = Vector3.ONE
		change_state(State.DRIFTING)

func _state_searching(delta):
	var noise_x = sin(time * 1.4) * cos(time * 0.9)
	var noise_y = sin(time * 1.1 + 1.3) * cos(time * 1.3)
	var noise_z = sin(time * 0.9 + 2.1) * cos(time * 1.6)
	velocity += Vector3(noise_x, noise_y, noise_z) * 1.5 * delta
	velocity = velocity.normalized() * SEARCH_SPEED
	head.global_position += velocity * delta
	_apply_bounds()
	if velocity.length() > 0.01:
		head.look_at(head.global_position + velocity, Vector3.UP)
	if food_target:
		change_state(State.HUNTING)
	elif state_timer > 10.0:
		change_state(State.DRIFTING)

# ─── Main loop ────────────────────────────────────────────────────────────────

func _process(delta):
	time += delta
	_update_needs(delta)
	_find_food()
	_update_state(delta)
	_update_segments()
	_update_hud_label()

func _update_state(delta):
	state_timer += delta
	if current_state != State.FEEDING and current_state != State.DISPLAYING:
		var key = State.keys()[current_state]
		if STATE_COLOURS.has(key):
			_set_colour(STATE_COLOURS[key])
	match current_state:
		State.DRIFTING:   _state_drifting(delta)
		State.CURIOUS:    _state_curious(delta)
		State.HUNTING:    _state_hunting(delta)
		State.FEEDING:    _state_feeding(delta)
		State.ORBITING:   _state_orbiting(delta)
		State.FLEEING:    _state_fleeing(delta)
		State.AGITATED:   _state_agitated(delta)
		State.DISPLAYING: _state_displaying(delta)
		State.SEARCHING:  _state_searching(delta)

func change_state(new_state: State):
	current_state = new_state
	state_timer = 0.0
