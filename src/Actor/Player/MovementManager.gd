extends Node2D


const BONK: = preload("res://src/Effect/BonkParticle.tscn")

const FLOOR_NORMAL: = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 4.0

const GRAVITY = 300

var snap_vector = SNAP_DIRECTION * SNAP_LENGTH

enum Jump {NORMAL, RUNNING}
var jump_type


var speed = Vector2(90,180)
var acceleration = 2.5 #was 5
var ground_cof = 0.1 #was 0.2
var air_cof = 0.00 # was 0.05






var bonk_time = 0.4
var forgiveness_time = 0.05
export var minimum_direction_time = 1.0 #was 0.5  #cave story forces you to jump a certain x distance when going max speed before jumping
var jump_starting_move_dir_x: int
export var min_x_velocity = 0.001

var knockback_direction: Vector2
export var knockback_speed = Vector2(40, 100) #(80, 180)
var knockback_velocity = Vector2.ZERO


var starting_direction #for acceleration
var bonk_distance = 4 #this was for corner clipping

var states = {}
var current_state
var is_debug = true


onready var world = get_tree().get_root().get_node("World")
onready var pc = get_parent()
onready var state_label = get_node("States/StateLabel")
onready var sp = get_node("States")

onready var min_dir_timer = get_node("MinDirTimer")
onready var forgive_timer = get_node("ForgiveTimer")

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
	
	current_state = states["normal"]



func _physics_process(_delta):
	if is_debug:
		state_label.text = current_state.name.to_lower()
	current_state.state_process()
#
#
#
#	pc.move_dir = get_move_dir()
#
#	if pc.is_on_ceiling() and $BonkTimeout.time_left == 0:
#		bonk("bonk")
#
#
#	if pc.is_on_floor():
#
#		jump_type = Jump.NORMAL
#
#		#if not pc.knockback and not pc.is_on_ladder: this was our check to keep the snap vector 0 allowing jumps
#
#		if $ForgivenessTimer.time_left == 0:
#			snap_vector = SNAP_DIRECTION * SNAP_LENGTH
#			if $BonkTimeout.time_left == 0:
#				bonk("Land")
#
#		if pc.is_on_ladder:
#			if Input.is_action_pressed("look_down"):
#				pc.is_on_ladder = false
#
#		$ForgivenessTimer.start(forgiveness_time)
#
#
#
#
#
#
#	#jump interrupt
#	var is_jump_interrupted = false
#	if pc.velocity.y < 0.0: #$MinimumJumpTimer.time_left == 0 and
#		if not Input.is_action_pressed("jump"):
#			is_jump_interrupted = true
#
#
#
#
#
#
#	if pc.knockback:
#		if knockback_velocity == Vector2.ZERO:
#			knockback_velocity = Vector2(knockback_speed.x * knockback_direction.x, knockback_speed.y * -1)
#			pc.velocity.y = knockback_velocity.y #set knockback y to this ONCE
#
#		pc.velocity.x += knockback_velocity.x
#		knockback_velocity.x /= 2 #???? why after
#
#		if abs(knockback_velocity.x) < 1:
#			knockback_velocity = Vector2.ZERO
#			pc.knockback = false
#
#
#
#	pc.velocity = get_move_velocity(pc.velocity, pc.move_dir, pc.face_dir, is_jump_interrupted)
#	var new_velocity = pc.move_and_slide_with_snap(pc.velocity, snap_vector, FLOOR_NORMAL, true)
#
#	if pc.is_on_wall():
#		new_velocity.y = max(pc.velocity.y, new_velocity.y)
#
#	pc.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
#


func _input(event):
	if not pc.disabled:
		
		if event.is_action_pressed("jump") and $ForgivenessTimer.time_left > 0 \
		or event.is_action_pressed("jump") and pc.is_on_floor():

			jump()
		
		if event.is_action_pressed("fire_automatic"):
			pc.direction_lock = pc.face_dir
		if event.is_action_released("fire_automatic"): 
			pc.direction_lock = Vector2.ZERO
		
		if event.is_action_pressed("debug_fly"):
			if current_state != states["fly"]:
				change_state(states["fly"])
			else: change_state(states["normal"])
		
		if pc.is_inspecting:
			if event.is_action_pressed("move_left") \
			or event.is_action_pressed("move_right") \
			or event.is_action_pressed("jump"):
				pc.is_inspecting = false




#func debug_fly():
#	if not pc.debug_flying:
#		print("debug fly: ON")
#		pc.debug_flying = true
#		pc.invincible = true
#		pc.is_in_water = false
#		pc.is_on_ladder = false
#	else:
#		print("debug fly: OFF")
#		pc.debug_flying = false
#		pc.invincible = false


func bonk(type):
	$BonkTimeout.start(bonk_time)
	
	var bonk = BONK.instance()
	bonk.position = pc.position
	bonk.normal = pc.get_slide_collision(pc.get_slide_count() - 1).normal
	match type:
		"bonk":
			bonk.position.y -=16
			bonk.type = "bonk"
		"land":
			bonk.type = "land"
	world.get_node("Front").add_child(bonk)



func jump():
	#$MinimumJumpTimer.start(minimum_jump_time) 
	snap_vector = Vector2.ZERO
	$JumpSound.play()
	#Check if a running jump. since speed.x is max x velocity, only count as a running jump then
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") and abs(pc.velocity.x) > pc.speed.x * 0.95:
		jump_type = Jump.RUNNING
		jump_starting_move_dir_x = pc.move_dir.x
		$MinimumDirectionTimer.start(minimum_direction_time)








func get_move_dir() -> Vector2:
	if not pc.disabled:
		if pc.is_on_ladder:
			return Vector2(
				Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
				Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
				)
		else:
			return Vector2(
				Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
				
				-1.0 if Input.is_action_just_pressed("jump") and $ForgivenessTimer.time_left > 0 or Input.is_action_just_pressed("jump") and pc.is_on_floor() 
				else 0.0)
	
	else: #disabled
		return Vector2.ZERO



func get_move_velocity(velocity, move_dir, _face_dir, is_jump_interrupted) -> Vector2:
	var out = velocity
	var friction = false
	
	
	if pc.is_on_ladder:
		out.y = move_dir.y * pc.speed.y/2
		out.x = 0
		if Input.is_action_just_pressed("jump"):
			pc.is_on_ladder = false
			out.y = pc.speed.y * -1.0
	
	
	elif pc.is_in_water:
# warning-ignore:integer_division
		out.y += (GRAVITY/2) * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = (pc.speed.y * 0.75) * move_dir.y
		if is_jump_interrupted:
# warning-ignore:integer_division
			out.y += (GRAVITY/2) * get_physics_process_delta_time()
		
		if move_dir.x != 0:
			out.x = min(abs(out.x) + pc.acceleration, (pc.speed.x/2))
			out.x *= move_dir.x
		else:
			friction = true


	elif jump_type == Jump.RUNNING:
		out.y += GRAVITY * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = pc.speed.y * move_dir.y
		if is_jump_interrupted:
			out.y += GRAVITY * get_physics_process_delta_time()
		
		if move_dir.x == jump_starting_move_dir_x *-1: #if we turn around, cancel minimumdirectiontimer
			$MinimumDirectionTimer.stop()
		
		if not $MinimumDirectionTimer.is_stopped(): #still doing minimum x movement in jump #
			#print("still doing minimum x movement")
			out.x = pc.speed.x
			out.x *= jump_starting_move_dir_x
		
		
		elif move_dir.x != 0: #try this as an "if" instead, if it's not working
			if move_dir.x != jump_starting_move_dir_x:
				out.x = min(abs(out.x) + pc.acceleration, (pc.speed.x * 0.5))
				out.x *= pc.move_dir.x
				#$MinimumDirectionTimer.start(0)
			else:
				out.x = min(abs(out.x) + pc.acceleration, pc.speed.x)
				out.x *= pc.move_dir.x
		else:
			friction = true
	
	
	#normal
	else:
		out.y += GRAVITY * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = speed.y * pc.move_dir.y
		if is_jump_interrupted:
			out.y += GRAVITY * get_physics_process_delta_time()

		if move_dir.x != 0:
			out.x = min(abs(out.x) + acceleration, speed.x)
			out.x *= pc.move_dir.x
		else:
			friction = true



	if pc.is_on_floor():
		if friction:
			out.x = lerp(out.x, 0, ground_cof)
	else:
		if friction:
			out.x = lerp(out.x, 0, air_cof)


	if abs(out.x) < min_x_velocity: #clamp velocity
		out.x = 0
		
	return out



