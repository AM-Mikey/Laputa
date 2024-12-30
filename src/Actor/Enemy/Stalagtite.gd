extends Enemy

var target: Node

var move_dir = Vector2.ZERO
@export var difficulty:= 1

var base_gravity: int

var base_damage = 2
var drop_damage: int
var wait_time: float

func setup():
	print("doing setup")
	match difficulty:
		0: 
			hp = 2
			reward = 2
			drop_damage = 4
			wait_time = 0.5
			$Sprite2D.self_modulate = Color.GREEN_YELLOW #replace with palette swap shader
		1: 
			hp = 2
			reward = 2
			drop_damage = 4
			wait_time = 0.5
		2:
			hp = 3
			reward = 4
			drop_damage = 6
			wait_time = 0.1
			$Sprite2D.self_modulate = Color.RED
	damage_on_contact = base_damage
	speed = Vector2.ZERO
	base_gravity = gravity
	gravity = 0
	change_state("hang")


func _on_physics_process(_delta):
	velocity = calculate_move_velocity(velocity, move_dir, speed)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()


func enter_hang():
	$AnimationPlayer.play("HangIdle")

func do_hang():
	var collider = $RayCast2D.get_collider()
	if collider:
		if collider is TileMap: return
		if collider.get_collision_layer_value(1):
			target = collider
			change_state("hangactive")


func enter_hangactive():
	$AnimationPlayer.play("HangActive")
	$StateTimer.start(wait_time)


func enter_drop():
	gravity = base_gravity
	damage_on_contact = drop_damage

func do_drop():
	if is_on_floor():
		if difficulty == 0:
			change_state("stake")
		else:
			change_state("squirm")


func enter_squirm():
	$RayCast2D.queue_free()
	damage_on_contact = base_damage
	
	$CollisionShape2D.shape.size = Vector2(14, 14)
	$CollisionShape2D.position += Vector2(0, 1)
	
	match difficulty:
		1:
			rng.randomize()
			move_dir = Vector2(sign(rng.randf_range(-1.0, 1.0)), 0) #random
		2:
			move_dir = Vector2(sign(target.position.x - position.x), 0) #direction of player
	match move_dir:
		Vector2.LEFT: $Sprite2D.flip_h = false
		Vector2.RIGHT: $Sprite2D.flip_h = true
	$AnimationPlayer.play("Squirm")
	await $AnimationPlayer.animation_finished
	change_state("run")


func enter_run():
	speed = Vector2(100, 100)
	$AnimationPlayer.play("Run")

func do_run():
	match move_dir:
		Vector2.LEFT: $Sprite2D.flip_h = false
		Vector2.RIGHT: $Sprite2D.flip_h = true
			
	if is_on_wall():
			move_dir.x *= -1


func enter_stake():
	$AnimationPlayer.play("Stake")
	$Standable/CollisionShape2D.set_deferred("disabled", false)
	

func calculate_move_velocity(velocity: Vector2, move_dir, speed) -> Vector2:
	var out: = velocity
	out.x = speed.x * move_dir.x
	out.y += gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = speed.y * move_dir.y
	return out


### SIGNALS ###

func _on_state_timer_timeout():
	if state == "hangactive":
		change_state("drop")
