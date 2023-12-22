extends Node2D

@export var start_state: NodePath
var current_state

func _ready():
	initialize_states()

func _physics_process(_delta):
	current_state.state_process()
	if get_parent().debug:
		$Label.text = current_state.name.to_lower()


func initialize_states():
	var new_state = get_node_or_null(start_state)
	if new_state: 
		change_state(new_state.name)
	else:
		change_state(get_child(1).name) #first after label


func change_state(state_name):
	#always enter and exit when changing states
	if current_state:
		current_state.exit()
	current_state = get_node(state_name.capitalize())
	current_state.enter()
