extends Node


@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var gm = pc.get_node("GunManager")

func state_process():
	pc.move_dir = get_move_dir()
	mm.velocity = calc_velocity()
	pc.set_velocity(mm.velocity)
	# TODOConverter3To4 looks that snap in Godot 4 is float, not vector like in Godot 3 - previous value `mm.snap_vector`
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
	pc.move_and_slide()
	var new_velocity = pc.velocity
	
	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
	
	
	
	if pc.is_on_floor() and not pc.is_on_ssp:
		if Input.is_action_pressed("look_down"):
			mm.change_state("run")

	#if pc.is_on_ceiling() and mm.bonk_timeout.time_left == 0:
		#mm.bonk("head")  #TODO: fix multi bonks



### GETTERS ###

func get_move_dir() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))

func calc_velocity() -> Vector2:
	var out = mm.velocity
	#Y
	out.y = pc.move_dir.y * mm.speed.y * 0.5
	#X
	out.x = 0
	if Input.is_action_just_pressed("jump"): #TODO: BIG NONO WHY ARE YOU CHANGING STATE DURING A VELOCITY CALCULATION
		mm.change_state("jump") #TODO fix
		out.y = mm.speed.y * -1.0
	if abs(out.x) < mm.min_x_velocity: out.x = 0 #clamp velocity
	return out



### STATES ###

func enter():
	mm.snap_vector = Vector2.ZERO
	pc.set_collision_mask_value(9, false) #ssp
	gm.disable()
	
func exit():
	pc.set_collision_mask_value(9, true) #ssp
	gm.enable()
