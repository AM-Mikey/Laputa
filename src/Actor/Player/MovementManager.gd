extends Node2D


const BONK: = preload("res://src/Effect/BonkParticle.tscn")

const FLOOR_NORMAL: = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 4.0

var snap_vector = SNAP_DIRECTION * SNAP_LENGTH

var speed = Vector2(90, 180)
var gravity = 300.0
var velocity = Vector2.ZERO
var acceleration = 2.0 #was 2.5, changed 10.26.22
var ground_cof = 0.1
var air_cof = 0.00

#var conveyor_speed = Vector2.ZERO

var on_ceiling = false

var coyote_time = 0.05
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

@onready var coyote_timer = get_node("CoyoteTimer")
@onready var min_dir_timer = get_node("MinDirTimer")

func _ready():
	initialize_states()


func change_state(new_state: String, do_cache_state = true):
	if current_state:
		if do_cache_state: cached_state = current_state
		current_state.exit()
	current_state = states[new_state]
	current_state.enter()





func initialize_states():
	for c in sp.get_children():
		if c.get_class() == "Node":
			states[c.name.to_lower()] = c
	
	change_state("run")



func _physics_process(_delta):
	if is_debug:
		state_label.text = current_state.name.to_lower()
	if pc.disabled: return
	
	#velocity += conveyor_speed
	speed = Vector2(90, 180) if not get_parent().is_in_water else Vector2(60, 140)
	gravity = 300.0 if not get_parent().is_in_water else 150.0
	
	if pc.is_on_ceiling():
		if not on_ceiling:
			var ceiling_normal = pc.get_slide_collision(pc.get_slide_collision_count() - 1).get_normal()
			bonk("head", ceiling_normal)
		on_ceiling = true
	else:

		on_ceiling = false
		
	current_state.state_process()


func check_ssp():
	if world.current_level != null:
		if world.current_level.has_node("Tiles"):
			for layer in world.current_level.get_node("Tiles").get_children():
				if layer is TileMap:
					var tile_pos = layer.local_to_map(Vector2(pc.position.x, pc.position.y + 8))
					var tile = layer.get_cell_source_id(0, tile_pos)
					if layer.tile_set.tile_get_shape_one_way(tile, 0):
						print("player is on ssp"
						)
						pc.is_on_ssp = true


func _input(event):
	if not pc.disabled:
		if event.is_action_pressed("fire_automatic"):
			pc.direction_lock = pc.look_dir
		if event.is_action_released("fire_automatic"): 
			pc.direction_lock = Vector2i.ZERO


func do_coyote_time():
	$CoyoteTimer.start(coyote_time)
	await $CoyoteTimer.timeout
	if not pc.is_on_floor() and current_state == states["run"]:
		pc.is_in_coyote = false
		change_state("fall")


func bonk(type, normal):
	var effect = BONK.instantiate()
	effect.position = pc.position
	effect.type = type
	effect.normal = normal
	world.get_node("Front").add_child(effect)



func jump():
	if pc.is_crouching: return
	
	snap_vector = Vector2.ZERO
	am.play("pc_jump")
	#Check if a running jump. since speed.x is max x velocity, only count as a running jump then
	if abs(velocity.x) > speed.x * 0.95:
		if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") and pc.controller_id == 0 or \
		Input.is_action_pressed("sasuke_left") or Input.is_action_pressed("sasuke_right") and pc.controller_id == 1:
			jump_starting_move_dir_x = sign(pc.move_dir.x)
			$MinDirTimer.start(minimum_direction_time)
			change_state("longjump")
	else:
		change_state("jump")



### SIGNALS ###

func _on_CrouchDetector_body_entered(_body):
	pc.is_crouching = true

func _on_CrouchDetector_body_exited(_body):
	pc.is_crouching = false
