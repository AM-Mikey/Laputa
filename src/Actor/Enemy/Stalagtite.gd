extends Enemy

var target: Node

var move_dir = Vector2.ZERO
@export var difficulty = 2

var base_gravity

var base_damage = 2
var drop_damage = 4

func _ready():
	state = "hang"
	hp = 2
	reward = 2
	damage_on_contact = base_damage
	speed = Vector2.ZERO
	base_gravity = gravity
	gravity = 0


func _physics_process(_delta):
	if disabled or dead:
		return
	velocity = calculate_move_velocity(velocity, move_dir, speed)
	set_velocity(velocity)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()
	velocity = velocity


func enter_hang():
	$AnimationPlayer.play("HangIdle")

func do_hang():
	if $RayCast2D.get_collider():
		if $RayCast2D.get_collider().get_collision_layer_value(0):
			target = $RayCast2D.get_collider()
			change_state("drop")


func enter_drop():
	gravity = base_gravity
	damage_on_contact = drop_damage

func do_drop():
	if is_on_floor():
		change_state("squirm")


func enter_squirm():
	$RayCast2D.queue_free()
	#yield(get_tree().create_timer(0.01), "timeout") #delay to change damage back to base
	damage_on_contact = base_damage
	
	match difficulty:
		1:
			rng.randomize()
			move_dir = Vector2(sign(rng.randf_range(-1.0, 1.0)), 0) #random
		2:
			move_dir = Vector2(sign(target.position.x - position.x), 0) #direction of player
	match move_dir:
		Vector2.LEFT: $AnimationPlayer.play("SquirmLeft")
		Vector2.RIGHT: $AnimationPlayer.play("SquirmRight")
	await $AnimationPlayer.animation_finished
	change_state("run")


func enter_run():
	speed = Vector2(100, 100)

func do_run():
	match move_dir:
		Vector2.LEFT:
			$AnimationPlayer.play("RunLeft")
		Vector2.RIGHT:
			$AnimationPlayer.play("RunRight")
	if is_on_wall():
			move_dir.x *= -1








func calculate_move_velocity(velocity: Vector2, move_dir, speed) -> Vector2:
	var out: = velocity
	
	out.x = speed.x * move_dir.x
	out.y += gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = speed.y * move_dir.y

	return out
