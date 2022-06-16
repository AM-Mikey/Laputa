extends Node2D


const BONK: = preload("res://src/Effect/BonkParticle.tscn")

const FLOOR_NORMAL: = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 4.0




var snap_vector = SNAP_DIRECTION * SNAP_LENGTH

enum Jump {NORMAL, RUNNING}
var jump_type


var speed = Vector2(90, 180)
var gravity = 300.0

var velocity = Vector2.ZERO
var acceleration = 2.5
var ground_cof = 0.1
var air_cof = 0.00

#var conveyor_speed = Vector2.ZERO

var can_bonk = true
var bonk_time = 0.4
var coyote_time = 0.05
export var minimum_direction_time = 1.0 #cave story forces you to jump a certain x distance when going max speed before jumping
var jump_starting_move_dir_x: int
export var min_x_velocity = 0.001

var knockback_direction: Vector2
export var knockback_speed = Vector2(40, 100) #(80, 180)
var knockback_velocity = Vector2.ZERO

var move_target = Vector2.ZERO

var starting_direction #for acceleration
var bonk_distance = 4 #this was for corner clipping

var states = {}
var current_state
var is_debug = true


onready var world = get_tree().get_root().get_node("World")
onready var pc = get_parent()
onready var state_label = get_node("States/StateLabel")
onready var sp = get_node("States")

onready var coyote_timer = get_node("CoyoteTimer")
onready var min_dir_timer = get_node("MinDirTimer")
#onready var bonk_timeout = get_node("BonkTimeout")

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
	
	current_state = states["run"]



func _physics_process(_delta):
#	velocity += conveyor_speed
	
	speed = Vector2(90, 180) if not get_parent().is_in_water else Vector2(60, 140)
	gravity = 300.0 if not get_parent().is_in_water else 150.0
	
	if is_debug:
		state_label.text = current_state.name.to_lower()
	current_state.state_process()



func _input(event):
	if not pc.disabled:
		if event.is_action_pressed("fire_automatic"):
			pc.direction_lock = pc.face_dir
		if event.is_action_released("fire_automatic"): 
			pc.direction_lock = Vector2.ZERO
		
		if event.is_action_pressed("debug_fly") or event.is_action_pressed("debug_editor"):
			if current_state != states["fly"]:
				change_state(states["fly"])
			else: change_state(states["run"])
		
		if pc.inspecting: #TODO: why this way?
			if event.is_action_pressed("move_left") \
			or event.is_action_pressed("move_right") \
			or event.is_action_pressed("jump"):
				pc.inspecting = false


func do_coyote_time():
	$CoyoteTimer.start(coyote_time)
	yield($CoyoteTimer, "timeout")
	if not pc.is_on_floor() and current_state ==states["run"]:
		change_state(states["fall"])


func bonk(type):
#	if can_bonk:
#		$BonkTimeout.start(bonk_time)

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
	snap_vector = Vector2.ZERO
	am.play("pc_jump")
	#Check if a running jump. since speed.x is max x velocity, only count as a running jump then
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") and abs(velocity.x) > speed.x * 0.95:
		#jump_type = Jump.RUNNING
		jump_starting_move_dir_x = pc.move_dir.x
		$MinDirTimer.start(minimum_direction_time)
		change_state(states["longjump"])
	else:
		change_state(states["jump"])
