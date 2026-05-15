extends CanvasLayer

var creature: Node3D = null
var label: Label = null

func _ready():
	label = Label.new()
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	# Find creature in scene
	await get_tree().process_frame
	creature = get_node_or_null("/root/Node3D/Creature")

func _process(_delta):
	if not creature or not label:
		return
	var state_name = creature.State.keys()[creature.current_state]
	label.text = "STATE:     %s\nHUNGER:  %.2f\nCURIOSITY: %.2f\nFEAR:      %.2f" % [
		state_name,
		creature.hunger,
		creature.curiosity,
		creature.fear
	]
