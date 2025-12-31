@icon("res://assets/Icon/PropIcon.png")
extends CharacterBody2D
class_name Prop

var sfx_ammo_refill = load("res://assets/SFX/placeholder/snd_get_missile.ogg")
var sfx_deny = load("res://assets/SFX/placeholder/snd_quote_bonkhead.ogg")
var sfx_chest = load("res://assets/SFX/placeholder/snd_chest_open.ogg")


var active_players := []
var rng = RandomNumberGenerator.new()
var inspect_time = 0.2
#var gravity = 300.0

#var is_in_water = false: set = set_is_in_water

#@export var base_gravity: float = 300.0
#@export var water_gravity: float = 150.0
@export var editor_hidden = false

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	#safe_margin = 0.001
	setup()

func setup(): #for children
	pass

func _input(event):
	if event.is_action_pressed("inspect") && !active_players.is_empty():
		for p in active_players:
			if !p.disabled && p.can_input && p.mm.current_state == p.mm.states["run"]:
				var previous_look_dir = p.look_dir
				p.mm.change_state("inspect")
				p.look_dir = Vector2(sign(p.global_position.x - $CollisionShape2D.global_position.x), 0.0)
				activate()
				await get_tree().create_timer(inspect_time).timeout
				p.mm.change_state("run")
				p.look_dir = previous_look_dir

func activate(): #for children
	pass

#func set_is_in_water(val):
	#gravity = base_gravity if !val else water_gravity
	#is_in_water = val
