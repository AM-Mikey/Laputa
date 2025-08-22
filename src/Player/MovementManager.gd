extends Node2D

const BONK: = preload("res://src/Effect/BonkParticle.tscn")
const LAND: = preload("res://src/Effect/LandParticle.tscn")

const FLOOR_NORMAL: = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 4.0

var snap_vector = SNAP_DIRECTION * SNAP_LENGTH

var speed = Vector2(90, 180)
var crouch_speed = 70.0
var acceleration = 2.0 #was 2.5, changed 10.26.22
var ground_cof = 0.1
var air_cof = 0.00
var gravity = 300.0
var terminal_velocity = 500.0
var on_ceiling = false

@export var coyote_time = 0.05 #0.05
@export var minimum_direction_time = 1.0 #cave story forces you to jump a certain x distance when going max speed before jumping
var jump_starting_move_dir_x: int
@export var min_x_velocity = 0.01 #0.001


var knockback_direction: Vector2
@export var knockback_speed = Vector2(40, 100) #(80, 180)
var knockback_velocity = Vector2.ZERO

var move_target = Vector2.ZERO

var starting_direction #for acceleration
var bonk_distance = 4 #this was for corner clipping

var states = {}
var current_state: Node
var cached_state: Node
var is_debug = true


@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent()
@onready var state_label = get_node("States/StateLabel")
@onready var sp = get_node("States")

@onready var coyote_timer: Timer = get_node("CoyoteTimer")
@onready var min_dir_timer = get_node("MinDirTimer")

func _ready():
	initialize_states()

func initialize_states():
	for c in sp.get_children():
		if c.get_class() == "Node":
			states[c.name.to_lower()] = c
	change_state("run")
	return

func change_state(new_state: String, do_cache_state = true):
	if current_state:
		if do_cache_state: cached_state = current_state
		current_state.exit()
	current_state = states[new_state]
	current_state.enter()


func _physics_process(_delta):
	if pc.disabled: return
	if is_debug:
		state_label.text = current_state.name.to_lower()
	speed = Vector2(90, 180) if not get_parent().is_in_water else Vector2(60, 140)
	gravity = 300.0 if not get_parent().is_in_water else 150.0
	do_ceiling_push_check()
	if pc.is_on_ceiling():
		if not on_ceiling:
			var ceiling_normal = pc.get_slide_collision(pc.get_slide_collision_count() - 1).get_normal()
			bonk(ceiling_normal)
		on_ceiling = true
	else:
		on_ceiling = false
	current_state.state_process(_delta)


func _input(event):
	if not pc.disabled:
		if event.is_action_pressed("fire_automatic") and pc.can_input:
			pc.direction_lock = pc.look_dir
		if event.is_action_released("fire_automatic"): #bypass can_input 
			pc.direction_lock = Vector2i.ZERO

func do_coyote_time():
	coyote_timer.stop()
	coyote_timer.start(coyote_time)

func bonk(normal):
	var effect = BONK.instantiate()
	effect.position = pc.position
	effect.normal = normal
	world.get_node("Front").add_child(effect)

func land():
	pc.is_in_coyote = false
	if pc.is_in_water: return
	var effect = LAND.instantiate()
	effect.position = pc.position
	world.get_node("Front").add_child(effect)
	
func jump():
	if pc.is_forced_crouching: return
	snap_vector = Vector2.ZERO
	#Check if a running jump. since speed.x is max x velocity, only count as a running jump then
	if abs(pc.velocity.x) > speed.x * 0.95 and pc.can_input:
		if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
			jump_starting_move_dir_x = sign(pc.move_dir.x)
			$MinDirTimer.start(minimum_direction_time)
			change_state("longjump")
			return
	else:
		change_state("jump")
		return



### HELPERS ###

func do_ceiling_push_check():
	if current_state == states["jump"] \
	or current_state == states["longjump"] \
	or current_state == states["fall"] \
	or current_state ==  states["knockback"]:
		if pc.get_node("CeilingL").is_colliding() \
		
		and not pc.get_node("ClearenceLF").is_colliding() \
		and pc.velocity.y < 0:
			pc.global_position.x += 2.0 if not pc.get_node("ClearenceLH").is_colliding() else 4.0
			pc.get_node("CollisionShape2D").set_deferred("disabled", false)
		
		elif pc.get_node("CeilingR").is_colliding() \
		and not pc.get_node("ClearenceRF").is_colliding() \
		and pc.velocity.y < 0:
			pc.global_position.x -= 2.0 if not pc.get_node("ClearenceRH").is_colliding() else 4.0
			pc.get_node("CollisionShape2D").set_deferred("disabled", false)


func check_ssp():
	if world.current_level == null: return
	if world.current_level.has_node("TileMap"):
		var tm = world.current_level.has_node("TileMap")
		var tile_pos = tm.local_to_map(Vector2(pc.position.x, pc.position.y + 8))
		var tile = tm.get_cell_source_id(0, tile_pos)
		if tm.tile_set.tile_get_shape_one_way(tile, 0):
			#print("player is on ssp")
			pc.is_on_ssp = true



### SIGNALS ###

func _on_CrouchDetector_body_entered(_body):
	pc.is_forced_crouching = true
	pc.is_crouching = true
	if current_state != states["run"]: return
	pc.get_node("CollisionShape2D").set_deferred("disabled", true)
	pc.get_node("CrouchingCollision").set_deferred("disabled", false)
	pc.get_node("Hurtbox/CollisionShape2D").set_deferred("disabled", true)
	pc.get_node("Hurtbox/CrouchingCollision").set_deferred("disabled", false)

func _on_CrouchDetector_body_exited(_body):
	pc.is_forced_crouching = false
	#if not Input.is_action_pressed("look_down") and pc.can_input: for if we have manual crouching
	pc.is_crouching = false
	if current_state != states["run"]: return
	pc.get_node("CollisionShape2D").set_deferred("disabled", false)
	pc.get_node("CrouchingCollision").set_deferred("disabled", true)
	pc.get_node("Hurtbox/CollisionShape2D").set_deferred("disabled", false)
	pc.get_node("Hurtbox/CrouchingCollision").set_deferred("disabled", true)


func _on_CoyoteTimer_timeout():
	if not pc.is_in_coyote:
		return
	pc.is_in_coyote = false
	if not pc.is_on_floor() and current_state == states["run"]:
		change_state("fall")
