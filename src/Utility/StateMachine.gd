extends Node2D

func _ready():
	initialize_states()


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


func _physics_process(_delta):
	current_state.state_process()
