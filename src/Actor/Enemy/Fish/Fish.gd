tool
extends Enemy

const PATH_LINE = preload("res://src/Utility/PathLine.tscn")

var states = {}
var current_state

export var debug = true

var move_dir = Vector2.ZERO
export var jump_height: int = 6 setget on_jump_height_changed
onready var start_pos = position
var jump_pos

export var can_move_x = true
export var x_min = -3 setget on_x_min_changed
export var x_max = 3 setget on_x_max_changed

onready var sp = get_node("States")

func _ready():
	print("ready fish")
	speed = Vector2(20,150)
	damage_on_contact = 1
	#on_jump_height_changed(jump_height)
	update_path_lines()
	initialize_states()



func _physics_process(_delta):
	if Engine.editor_hint:
		pass
	else:
		gravity = 300.0 if not is_in_water else 150.0
		if debug:
			$States/Label.text = current_state.name.to_lower()
		current_state.state_process()



func on_jump_height_changed(new):
	jump_height = new
	jump_pos = Vector2(position.x, position.y + jump_height * -16)
	update_path_lines()

func on_x_min_changed(new):
	x_min = new
	update_path_lines()
	
func on_x_max_changed(new):
	x_max = new
	update_path_lines()
	
func update_path_lines():
	#if Engine.editor_hint or debug:
	for c in get_children():
		if c.name == "VPath" or c.name == "HPath": c.free()
	
	var vline = PATH_LINE.instance()
	vline.name = "VPath"
	vline.default_color = Color.lightgreen
	if Engine.editor_hint: 
		vline.add_point(Vector2.ZERO)
		vline.add_point(Vector2(0, jump_height * -16))
		add_child(vline)
		move_child(vline, 0)
	elif debug and world:
		vline.add_point(position)
		vline.add_point(Vector2(jump_pos))
		world.front.add_child(vline)
	
	$RayCast2D.cast_to = Vector2(0, jump_height * -16)

	var hline = PATH_LINE.instance()
	hline.name = "HPath"
	hline.default_color = Color.red
	if Engine.editor_hint: 
		hline.add_point(Vector2(x_min * 16,0))
		hline.add_point(Vector2(x_max * 16,0))
		add_child(hline)
		move_child(hline, 0)
	elif debug and world:
		hline.add_point(position + Vector2(x_min * 16,0))
		hline.add_point(position + Vector2(x_max * 16,0))
		world.front.add_child(hline)





func change_state(new_state):
	#always enter and exit when changing states
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()





func initialize_states():
	for c in sp.get_children():
		if c.get_class() == "Node":
			states[c.name.to_lower()] = c
	
	change_state(states["idle"])
