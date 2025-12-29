extends Node


@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var gm = pc.get_node("GunManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var ap = pc.get_node("AnimationPlayer")

func state_process(_delta):
	set_player_directions()
	pc.velocity = calc_velocity()
	pc.move_and_slide()
	var new_velocity = pc.velocity
	pc.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
	if pc.is_on_floor() and not pc.is_on_ssp:
		if Input.is_action_pressed("look_down") and pc.can_input:
			mm.change_state("run")
			return
	animate()


func set_player_directions():
	var input_dir = Vector2.ZERO
	if pc.can_input:
		input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))

	pc.move_dir = Vector2(input_dir)

	if pc.move_dir.x != 0.0:
		pc.look_dir.x = sign(pc.move_dir.x)
	if pc.move_dir.y != 0.0:
		pc.look_dir.y = sign(pc.move_dir.y)

	if input_dir.y == 0:
		pc.shoot_dir = Vector2(pc.look_dir.x, 0)
	else:
		pc.shoot_dir = Vector2(0, pc.look_dir.y)


func animate():
	var animation = "climb"
	var reference_texture = preload("res://assets/Player/Climb.png")
	#for runtime, set the frame counts before the animation starts
	sprite.hframes = int(reference_texture.get_width() / 32.0)
	sprite.vframes = int(reference_texture.get_height() / 32.0)
	sprite.frame_coords.y = get_vframe()
	if not ap.is_playing() or ap.current_animation != animation:
		ap.stop()
		ap.play(animation, 0.0, 1.0)



### GETTERS ###

func calc_velocity() -> Vector2:
	var out = pc.velocity
	#Y
	out.y = pc.move_dir.y * mm.speed.y * 0.5
	#X
	out.x = 0
	if Input.is_action_just_pressed("jump") and pc.can_input: #TODO: BIG NONO WHY ARE YOU CHANGING STATE DURING A VELOCITY CALCULATION
		mm.change_state("jump") #TODO fix
		out.y = mm.speed.y * -1.0
	if abs(out.x) < mm.min_x_velocity: out.x = 0 #clamp velocity
	return out

func get_vframe() -> int:
	var out = 0
	match pc.look_dir.x:
		-1: out = 0
		1: out = 1
	return out



### STATES ###

func enter(_prev_state: String) -> void:
	mm.snap_vector = Vector2.ZERO
	sprite.position = Vector2(0.0, -8.0)
	pc.set_collision_mask_value(10, false) #ssp
	gm.disable() #TODO: why????? A: Not allowing player to shoot on ladder is intentional
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)

func exit(_next_state: String) -> void:
	pc.set_collision_mask_value(10, true) #ssp
	sprite.position = Vector2(0.0, -16.0)
	gm.enable()
