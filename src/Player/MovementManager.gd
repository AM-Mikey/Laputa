extends Node2D

const LAND: = preload("res://src/Effect/LandParticle.tscn")

const FLOOR_NORMAL: = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 4.0

var snap_vector = SNAP_DIRECTION * SNAP_LENGTH

var speed = Vector2(0, 0)
var crouch_speed = 70.0
var acceleration = 10.0
var ground_cof = 0.15
var air_cof = 0.02
var gravity = 0.0
var terminal_velocity = 500.0
var did_ceiling_step = false
@export var debug = true

@export var base_speed = Vector2(90, 170)
@export var water_speed = Vector2(60, 140)
@export var base_gravity = 300
@export var water_gravity = 150

@export var coyote_time = 0.05 #0.05
@export var minimum_direction_time = 1.0 #cave story forces you to jump a certain x distance when going max speed before jumping
var jump_starting_move_dir_x: int
@export var min_x_velocity = 0.01 #0.001


var knockback_direction: Vector2
@export var knockback_speed = Vector2(40, 80) #(80, 180)
var knockback_velocity = Vector2.ZERO

var move_target = Vector2.ZERO

var starting_direction #for acceleration

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
		current_state.exit(new_state)
	current_state = states[new_state]
	current_state.enter(current_state.name.to_lower())


func _physics_process(_delta):
	if pc.disabled: return
	if is_debug:
		state_label.text = current_state.name.to_lower()
	speed = base_speed if not get_parent().is_in_water else water_speed
	gravity = base_gravity if not get_parent().is_in_water else water_gravity
	do_ceiling_push_check()
	pc.is_on_ssp = get_is_on_ssp()
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

func land():
	am.play("pc_land")
	pc.is_in_coyote = false
	if pc.is_in_water: return
	var effect = LAND.instantiate()
	effect.position = pc.position
	world.get_node("Front").add_child(effect)

func jump():
	if pc.is_crouching: return
	snap_vector = Vector2.ZERO
	change_state("jump")
	# Coyote Time debug
	if not pc.is_on_floor() and debug:
		am.play("gun_sword")
		var effect = LAND.instantiate()
		effect.position = pc.position
		world.get_node("Front").add_child(effect)

func drop():
	$States/Jump.is_dropping = true
	change_state("jump")
	pc.set_collision_mask_value(10, false)
	await get_tree().create_timer(0.1).timeout
	pc.set_collision_mask_value(10, true)

### HELPERS ###

func do_ceiling_push_check():
	if current_state == states["jump"] \
	or current_state == states["knockback"]:
		if pc.get_node("CeilingL").is_colliding() \
		and not pc.get_node("ClearenceLF").is_colliding() \
		and pc.velocity.y < 0 \
		and not pc.move_dir.x < 0:
			pc.global_position.x += 2.0 if not pc.get_node("ClearenceLH").is_colliding() else 4.0
			pc.get_node("CollisionShape2D").set_deferred("disabled", false)

		elif pc.get_node("CeilingR").is_colliding() \
		and not pc.get_node("ClearenceRF").is_colliding() \
		and pc.velocity.y < 0 \
		and not pc.move_dir.x > 0:
			pc.global_position.x -= 2.0 if not pc.get_node("ClearenceRH").is_colliding() else 4.0
			pc.get_node("CollisionShape2D").set_deferred("disabled", false)


func get_is_on_ssp() -> bool:
	var out = false
	var p = pc.get_node("SSPCasts")
	if p.get_node("SSPLeft").is_colliding() || p.get_node("SSPRight").is_colliding():
		if !p.get_node("WorldLeft").is_colliding() && !p.get_node("WorldRight").is_colliding():
			out = true
	#elif p.get_node("SSPLeft").is_colliding():
		#if !p.get_node("WorldLeft").is_colliding() and !p.get_node("WorldRight").is_colliding():
			#out = true
	#elif p.get_node("SSPRight").is_colliding():
		#if !p.get_node("WorldLeft").is_colliding() and !p.get_node("WorldRight").is_colliding():
			#out = true
	return out


func disable_collision_shapes(array):
	for shape in array:
		shape.set_deferred("disabled", true)
		shape.visible = false

func enable_collision_shapes(array):
	for shape in array:
		shape.set_deferred("disabled", false)
		shape.visible = true





### SIGNALS ###

func _on_CrouchDetector_body_entered(_body):
	if !pc.forbid_crouching:
		pc.is_crouching = true
		if current_state != states["run"]: return

		var disable = [
			pc.get_node("CollisionShape2D"),
			pc.get_node("Hurtbox/CollisionShape2D")]
		var enable = [
			pc.get_node("CrouchingCollision"),
			pc.get_node("Hurtbox/CrouchingCollision")]
		disable_collision_shapes(disable)
		enable_collision_shapes(enable)


func _on_CrouchDetector_body_exited(_body):
	if pc.is_crouching:
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
		change_state("jump")
