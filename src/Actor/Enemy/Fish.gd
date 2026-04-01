extends Enemy

const ICON = preload("res://assets/Actor/Enemy/FishIcon.png")
const PATH_LINE = preload("res://src/Utility/PathLine.tscn")
const BONK = preload("res://src/Effect/BonkParticle.tscn")

var move_dir = Vector2.LEFT
@export var swim_dir_x = -1: set = on_swim_dir_x_changed
@export var jump_height: int = 6: set = on_jump_height_changed
var normal_damage = 1
var attack_damage = 4

var jump_pos: Vector2 = global_position

@export var can_move_x = true
var x_min = -3
var x_max = 3
var did_bonk: bool = false

@onready var start_pos = global_position
@onready var ap: AnimationPlayer = get_node("AnimationPlayer")
@onready var rc: RayCast2D = get_node("RayCast2D")


func setup():
	print("setup fish")
	change_state("idle")
	do_bubbles = false
	if debug: print("ready fish")
	speed = Vector2(20, 150)
	hp = 3
	damage_on_contact = normal_damage
	for c in get_children():
		if c.is_in_group("Waypoints"):
			match c.tag_name:
				"jump":
					rc.target_position.y = c.position.y
	for c in w.current_level.get_node("Waypoints").get_children():
		if c.owner_id == id:
			match c.tag_name:
				"left":
					x_min = c.position.x - start_pos.x
				"right":
					x_max = c.position.x - start_pos.x
	update_path_lines()

func on_swim_dir_x_changed(new):
	swim_dir_x = new
	if (get_node_or_null("Sprite2D")):
		$Sprite2D.scale.x = new
	move_dir.x = new

func on_jump_height_changed(new):
	if (get_node_or_null("RayCast2D")):
		$RayCast2D.target_position.y = -new * 16
	jump_height = new
	update_path_lines()


func bonk():
	if (did_bonk or get_slide_collision_count() == 0):
		return

	var slide_collision: KinematicCollision2D = get_last_slide_collision()
	var bonk_effect = BONK.instantiate()
	#print("Fish bonked ", slide_collision.get_normal())
	bonk_effect.normal = slide_collision.get_normal()
	bonk_effect.global_position.x = global_position.x
	bonk_effect.global_position.y = global_position.y + 13.0
	w.get_node("Front").add_child(bonk_effect)
	did_bonk = true

func calc_velocity(dir, _do_gravity = true, _do_acceleration = true, _do_friction = true) -> Vector2:
	match state:
		"idle", "swim":
			var out = velocity

			out.x = speed.x * dir.x

			return out
		"attack":
			var out = velocity

			out.y += gravity * get_physics_process_delta_time()
			if dir.y < 0:
				out.y = speed.y * dir.y
			elif is_on_ceiling() and !did_bonk:
				out.y = 0

			return out
		"fall":
			var out = velocity
			if (is_on_ceiling() and !did_bonk):
				out.y = 0
			else:
				out.y += gravity * get_physics_process_delta_time()

			return out
	return Vector2.ZERO


#region STATES
#region Idle
func enter_idle(_prev_state: String):
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if can_move_x:
		change_state("swim")
	else:
		get_parent().get_parent().get_node("AnimationPlayer").play("Idle")


func do_idle():
	velocity = calc_velocity(move_dir)
	move_and_slide()

	var collision = get_node("RayCast2D").get_collider()
	if collision != null:
		if (collision is not TileMapLayer and collision.get_collision_layer_value(1)):
			if (abs(collision.global_position.x - rc.global_position.x) <= 1):
				if (debug): print("fish got target")
				change_state("attack")
				return
#endregion

#region Swim
func enter_swim(_prev_state: String, _arg: Dictionary = {}):
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	move_dir.x = swim_dir_x
	ap.play("Idle")

func exit_swim(_next_state: String, _arg: Dictionary = {}):
	move_dir = Vector2.ZERO
	velocity = Vector2.ZERO

func do_swim():
	var collision = rc.get_collider()
	if collision != null:
		if (collision is not TileMapLayer and collision.get_collision_layer_value(1)):
			if (abs(collision.global_position.x - rc.global_position.x) <= 1): #Prevent the fish target just the side of player hitbox
				if debug: print("fish got target")
				change_state("attack")
				return

	if is_on_wall() and (move_and_collide(Vector2.RIGHT, true) or move_and_collide(Vector2.LEFT, true)):
		swim_dir_x = -swim_dir_x
	else:
		if global_position.x < start_pos.x + x_min:
			swim_dir_x = 1
		if global_position.x > start_pos.x + x_max:
			swim_dir_x = -1

	velocity = calc_velocity(move_dir)
	move_and_slide()
#endregion

#region Attack
func enter_attack(_prev_state: String):
	damage_on_contact = attack_damage
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	jump_pos = global_position
	ap.play("Target")
	did_bonk = false

	await ap.animation_finished
	move_dir = Vector2.UP

func do_attack():
	if position.y <= jump_pos.y - jump_height * 16 + speed.y * 0.3 or is_on_ceiling():
		if (is_on_ceiling()):
			bonk()
		change_state("fall")
		return

	velocity = calc_velocity(move_dir)
	move_and_slide()
#endregion

func exit_attack(_prev_state):
	damage_on_contact = normal_damage

#region Fall
func exit_fall(_next_state: String):
	velocity = Vector2.ZERO

func do_fall():
	if (velocity.y > 0):
		if (ap.current_animation != "Fall"):
			ap.play("Fall")
	else:
		if (ap.current_animation != "Rise"):
			ap.play("Rise")

	if (is_on_ceiling()):
		bonk()

	if !(global_position.y >= jump_pos.y - 5 or is_on_floor()):
		velocity = calc_velocity(move_dir)
		move_and_slide()
	else:
		#var tween = get_tree().create_tween()
		#tween.tween_property(main, "position", Vector2(main.position.x, main.start_pos.y), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		#await tween.finished
		var collision: KinematicCollision2D = move_and_collide(jump_pos - global_position)
		if (collision):
			global_position += collision.get_travel()
		else:
			global_position.y = jump_pos.y
		if (can_move_x):
			change_state("swim")
		else:
			change_state("idle")
		return

#endregion
#endregion

func update_path_lines():
	#if Engine.editor_hint or debug:
	if !(debug or Engine.is_editor_hint()):
		return
	for c in get_children():
		if c.name == "VPath" or c.name == "HPath": c.free()

	var vline = PATH_LINE.instantiate()
	vline.name = "VPath"
	vline.default_color = Color.LIGHT_GREEN
	if Engine.is_editor_hint():
		vline.add_point(Vector2.ZERO)
		vline.add_point(Vector2(0, jump_height * -16))
	elif debug and world:
		vline.add_point(global_position)
		vline.add_point(global_position + Vector2(0, jump_height * -16))
	add_child(vline)
	move_child(vline, 0)

	var hline = PATH_LINE.instantiate()
	hline.name = "HPath"
	hline.default_color = Color.RED
	#if Engine.is_editor_hint():
		#hline.add_point(Vector2(x_min, -4))
		#hline.add_point(Vector2(x_max, -4))
	#elif debug and world:
		#hline.add_point(global_position + Vector2(x_min, -4))
		#hline.add_point(global_position + Vector2(x_max, -4))
	add_child(hline)
	move_child(hline, 0)
