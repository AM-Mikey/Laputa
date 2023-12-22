extends Enemy

enum StartingDirection {LEFT, RIGHT, UP, DOWN}
@export var starting_direction: StartingDirection
@export var sight_distance: float = 200
@export var is_debug = false


var starting_state = "idle"
var attack_dir: Vector2
var reset_time = 4.0


@onready var state_label = $States/StateLabel
@onready var animated_sprite = $AnimatedSprite2D

func setup():
	change_state(starting_state)
	hp = 4
	damage_on_contact = 2
#	get_direction_vector_from_starting_dir()
	$RayCast2D.target_position = attack_dir * sight_distance
	
func _physics_process(delta):
	if disabled or dead:
		return
#	if is_debug:
#		state_label.text = str(current_state)
#	current_state.physics_process()
	
	
### STATES ###
	
func do_idle():
	var collision = $RayCast2D.get_collider()
	if collision != null && collision.is_in_group("Players"): #todo check bit instead
		change_state("attack")

func enter_attack():
	#beetle_actor.animated_sprite.playing = true
	#beetle_actor.animated_sprite.animation = state_name
	if attack_dir == Vector2.RIGHT:
		pass
		#beetle_actor.animated_sprite.flip_h = true
	else:
		#beetle_actor.animated_sprite.flip_h = false
		pass
	

func do_attack():
	set_velocity(attack_dir * speed)
	set_up_direction(Vector2.UP)
	move_and_slide()
	if velocity == Vector2.ZERO:
		#wall was hit
		change_state("reset")
	#once wall is hit change state to reset state

func enter_reset():
	attack_dir = attack_dir * Vector2(-1, -1)
	$RayCast2D.target_position = attack_dir * sight_distance

#	if beetle_actor.is_on_floor():
#		beetle_actor.animated_sprite.animation = "Idle_Floor"
#		beetle_actor.animated_sprite.flip_v = false
#
#	if beetle_actor.is_on_ceiling():
#		beetle_actor.animated_sprite.animation = "Idle_Floor"
#		beetle_actor.animated_sprite.flip_v = true
#
#	if beetle_actor.is_on_wall():
#		beetle_actor.animated_sprite.animation = "Idle_Wall"
	await get_tree().create_timer(4.0)
	change_state("idle")

### GETTERS ###

#func get_direction_vector_from_starting_dir():
#	direction_vector = Vector2(0,0)
#	match starting_direction:
#		StartingDirection.LEFT:
#			direction_vector = Vector2.LEFT
#			#set starting anim
#			animated_sprite.animation = "Idle_Wall"
#			animated_sprite.flip_h = true
#		StartingDirection.RIGHT:
#			direction_vector = Vector2.RIGHT
#			#set starting anim
#			animated_sprite.animation = "Idle_Wall"
#		StartingDirection.UP:
#			direction_vector = Vector2.UP
#			#set starting anim.
#			animated_sprite.animation = "Idle_Floor"
#			animated_sprite.flip_v = false
#		StartingDirection.DOWN:
#			direction_vector = Vector2.DOWN
#			#set starting anim
#			animated_sprite.animation = "Idle_Floor"
#			animated_sprite.flip_v = true
