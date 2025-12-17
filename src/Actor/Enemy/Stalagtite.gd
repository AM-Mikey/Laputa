extends Enemy

const TX_0 = preload("res://assets/Actor/Enemy/Stalagtite.png")
const TX_1 = preload("res://assets/Actor/Enemy/Stalagtite1.png")
const TX_2 = preload("res://assets/Actor/Enemy/Stalagtite2.png")

var target: Node

var move_dir = Vector2.ZERO
@export var difficulty := 1

var base_damage = 2
var drop_damage: int
var wait_time: float
var ternminal_drop_velocity: float = 320.0

func set_is_in_water(val):
	if (state not in ["hang", "hangactive"]):
		super.set_is_in_water(val)
	is_in_water = val

func setup():
	#print("doing setup")
	match difficulty:
		0:
			hp = 2
			reward = 2
			drop_damage = 4
			wait_time = 0.5
			$Sprite2D.texture = TX_0
		1:
			hp = 2
			reward = 2
			drop_damage = 4
			wait_time = 0.5
			$Sprite2D.texture = TX_1
		2:
			hp = 3
			reward = 4
			drop_damage = 6
			wait_time = 0.1
			$Sprite2D.texture = TX_2
	damage_on_contact = base_damage
	enemy_damage_on_contact = 999
	speed = Vector2.ZERO
	gravity = 0
	change_state("hang")


func _on_physics_process(_delta):
	if state == "stake":
		velocity = Vector2.ZERO
	else:
		velocity = calc_velocity(move_dir)
	velocity.y = min(velocity.y, ternminal_drop_velocity)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()


func enter_hang(_last_state):
	$AnimationPlayer.play("HangIdle")

func do_hang():
	var collider = $RayCast2D.get_collider()
	if collider:
		if collider is TileMapLayer: return
		if collider.get_collision_layer_value(1):
			target = collider.get_parent()
			change_state("hangactive")
			return


func enter_hangactive(_last_state):
	$AnimationPlayer.play("HangActive")
	$StateTimer.start(wait_time)


func enter_drop(_last_state):
	gravity = base_gravity if !is_in_water else water_gravity
	hit_enemies_on_contact = true
	damage_on_contact = drop_damage

func do_drop():
	if is_on_floor():
		if difficulty == 0: #purple
			change_state("stake")
			return
		else:
			change_state("squirm")
			return

func exit_drop(_next_state):
	hit_enemies_on_contact = false

func enter_squirm(_last_state):
	$RayCast2D.queue_free()
	damage_on_contact = base_damage

	$CollisionShape2D.set_deferred("disabled", true)
	$GroundedCollision.set_deferred("disabled", false)

	if target:
		match difficulty:
			1:
				move_dir = Vector2(sign(position.x - target.position.x), 0) #opposite direction of player
			2:
				move_dir = Vector2(sign(target.position.x - position.x), 0) #direction of player
	else:
		# Randomize direction if no target exists
		move_dir = Vector2([-1.0, 1.0].get(randi_range(0, 1)), 0)
	match move_dir:
		Vector2.LEFT: $Sprite2D.flip_h = false
		Vector2.RIGHT: $Sprite2D.flip_h = true
	$AnimationPlayer.play("Squirm")
	await $AnimationPlayer.animation_finished
	change_state("run")


func enter_run(_last_state):
	speed = Vector2(100, 100)
	$AnimationPlayer.play("Run")
	$WallRight.enabled = true
	$WallLeft.enabled = true

func do_run():
	match move_dir:
		Vector2.LEFT:
			$Sprite2D.flip_h = false
			if ($WallLeft.is_colliding()):
				move_dir = Vector2.RIGHT
		Vector2.RIGHT:
			$Sprite2D.flip_h = true
			if ($WallRight.is_colliding()):
				move_dir = Vector2.LEFT


func exit_run(_next_state):
	$WallRight.enabled = false
	$WallLeft.enabled = false


func enter_stake(_last_state):
	$AnimationPlayer.play("Stake")
	await get_tree().process_frame
	$CollisionShape2D.set_deferred("disabled", true) #so it doesn't see itself
	$Standable/CollisionShape2D.set_deferred("disabled", false)


### SIGNALS ###

func _on_state_timer_timeout():
	if state == "hangactive":
		change_state("drop")
