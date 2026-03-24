extends Node

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var run = pc.get_node("MovementManager/States/Run")

@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")

#TODO: this state is meant to be used for cutscenes involving the player, we might do things like use "moveto" and other states to animate the player in cutscenes. in that case this node becomes pretty useless. All depends on how player is animated in cutscenes.

func state_process(delta):
	#pc.velocity = calc_velocity()
	#pc.move_and_slide()
	#var new_velocity = pc.velocity
	#pc.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
	animate(delta)
	#if pc.is_on_wall():
		#new_velocity.y = max(pc.velocity.y, new_velocity.y)


func animate(delta):
	run.animate(delta)



### GETTERS ###

func calc_velocity():
	pass
	#run.calc_velocity()



### STATES ###

func enter(_prev_state: String) -> void:
	run.play_animation("run")
	guns.visible = false
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)

func exit(_next_state: String) -> void:
	guns.visible = true
