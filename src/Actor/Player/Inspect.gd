extends Node

onready var world = get_tree().get_root().get_node("World")
onready var pc = get_parent().get_parent().get_parent()
onready var mm = pc.get_node("MovementManager")

onready var sprite = pc.get_node("Sprite")
onready var guns = pc.get_node("Gunmanager/Guns")
onready var ap = pc.get_node("AnimationPlayer")
onready var anim = pc.get_node("AnimationManager")


func state_process():
	mm.velocity = get_velocity()
	var new_velocity = pc.move_and_slide_with_snap(mm.velocity, mm.snap_vector, mm.FLOOR_NORMAL, true)
	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
	
	animate()
	if pc.is_on_wall():
		new_velocity.y = max(mm.velocity.y, new_velocity.y)
	
	
#	if Input.is_action_pressed("move_left") \
#	or Input.is_action_pressed("move_right") \
#	or Input.is_action_pressed("jump"):
#		pc.mm.change_state(pc.mm.cached_state.name.to_lower())


func get_velocity():
	var out = mm.velocity
	
	out.y += mm.gravity * get_physics_process_delta_time()
	
	if pc.is_on_floor():
		out.x = lerp(out.x, 0, mm.ground_cof * 2)
	else:
		out.x = lerp(out.x, 0, mm.air_cof * 2)
	
	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
	
	return out



func animate():
	var animation = "inspect"
	
	if not ap.is_playing() or ap.current_animation != animation:
		ap.play(animation)
		ap.playback_speed = 1
	
	
	var vframe: int
	if pc.look_dir.x < 0: #left
		vframe = 0
	else: #right
		vframe = 1

	sprite.frame_coords.y = vframe


func enter():
	guns.visible = false
	
func exit():
	guns.visible = true
