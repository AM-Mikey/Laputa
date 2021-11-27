extends Enemy

enum StartingDirection {LEFT, RIGHT, UP, DOWN}
export(StartingDirection) var starting_direction

var direction_vector: Vector2

onready var state_label = $States/StateLabel
onready var animated_sprite = $AnimatedSprite

export var is_debug = false
export(float) var idle_wait_time = 2
export(float) var reset_wait_time = 1

#states
var idle_state
var attack_state
var reset_state

var current_state

func _ready():
	hp = 4
	damage_on_contact = 2
	get_direction_vector_from_starting_dir()
	init_states()
	
	pass
	
func _physics_process(delta):
	if is_debug:
		state_label.text = current_state.state_name
	current_state.physics_process()
	pass
	
	
func init_states():
	#init idle
	idle_state = $States/Idle
	idle_state.beetle_actor = self
	idle_state.get_node("Timer").wait_time = idle_wait_time
	
	#init attacking state
	attack_state = $States/Attack
	attack_state.beetle_actor = self
	
	#init reset state
	reset_state = $States/Reset
	reset_state.beetle_actor = self
	reset_state.get_node("Timer").wait_time = reset_wait_time
	#choose starting state
	change_state(idle_state)
	
	
func change_state(new_state):
	#always enter and exit when changing states
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()
	
func get_direction_vector_from_starting_dir():
	direction_vector = Vector2(0,0)
	match starting_direction:
		StartingDirection.LEFT:
			direction_vector = Vector2.LEFT
			#set starting anim
			animated_sprite.animation = "Idle_Wall"
		StartingDirection.RIGHT:
			direction_vector = Vector2.RIGHT
			#set starting anim
			animated_sprite.animation = "Idle_Wall"
			animated_sprite.flip_h = true
		StartingDirection.UP:
			direction_vector = Vector2.UP
			#set starting anim.
			animated_sprite.animation = "Idle_Floor"
			animated_sprite.flip_v = false
		StartingDirection.DOWN:
			direction_vector = Vector2.DOWN
			#set starting anim
			animated_sprite.animation = "Idle_Floor"
			animated_sprite.flip_v = true
	pass
	
func swap_direction_vector():
	if direction_vector == Vector2.LEFT:
		direction_vector = Vector2.RIGHT
		return
		
	if direction_vector == Vector2.RIGHT:
		direction_vector = Vector2.LEFT
		return
		
	if direction_vector == Vector2.UP:
		direction_vector = Vector2.DOWN
		return
		
	if direction_vector == Vector2.DOWN:
		direction_vector = Vector2.UP
		return
#
#if beetle_actor.is_on_floor():
#		#use floor idle
#		beetle_actor.animated_sprite.animation = "Idle_Floor"
#		beetle_actor.animated_sprite.flip_v = false
#		pass
#	if beetle_actor.is_on_ceiling():
#		beetle_actor.animated_sprite.animation = "Idle_Floor"
#		#use ceiling idle
#		beetle_actor.animated_sprite.flip_v = true
#		pass
#
#	if beetle_actor.is_on_wall():
#		beetle_actor.animated_sprite.animation = "Idle_Wall"
#		#use wall idle
#		pass
