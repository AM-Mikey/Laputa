extends Enemy

enum StartingDirection {LEFT, RIGHT, UP, DOWN}
export(StartingDirection) var starting_direction

var direction_vector: Vector2
export(float) var sight_distance = 200
onready var detection_raycast:RayCast2D = $RayCast2D
onready var state_label = $States/StateLabel
onready var animated_sprite = $AnimatedSprite

export var is_debug = false

#states
var idle_state
var attack_state
var reset_state

var current_state

func _ready():
	hp = 4
	damage_on_contact = 2
	get_direction_vector_from_starting_dir()
	detection_raycast.cast_to = direction_vector * sight_distance
	init_states()	
	pass
	
func _physics_process(delta):
	if is_debug:
		state_label.text = current_state
	current_state.physics_process()
	pass
	
	
func init_states():
	#init idle
	idle_state = $States/Idle
	idle_state.beetle_actor = self
	
	#init attacking state
	attack_state = $States/Attack
	attack_state.beetle_actor = self
	
	#init reset state
	reset_state = $States/Reset
	reset_state.beetle_actor = self
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
			animated_sprite.flip_h = true
		StartingDirection.RIGHT:
			direction_vector = Vector2.RIGHT
			#set starting anim
			animated_sprite.animation = "Idle_Wall"
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
