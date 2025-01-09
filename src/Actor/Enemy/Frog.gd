extends Enemy

var tx_toad = preload("res://assets/Actor/Enemy/Toad.png")
var tx_frog = preload("res://assets/Actor/Enemy/Frog.png")

var target

@export var jump_delay = 3.0
var croak_time = 1.0
var move_dir = Vector2.ZERO
var look_dir = Vector2.LEFT

#enum Difficulty {easy, normal, hard}
#export(Difficulty) var difficulty = Difficulty.normal setget _on_difficulty_changed

func setup():
	change_state("idle")
	damage_on_contact = 1
	reward = 2
	hp = 3
	set_floor_stop_on_slope_enabled(true)




func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	if not is_on_floor():
		move_dir.y = 0 #don't allow them to jump if they are midair

	velocity = calc_velocity(velocity, move_dir, speed)
	move_and_slide()
	animate()

### STATES ###

func do_targeting():
	if is_on_floor():
		if $JumpTimer.time_left == 0.0:
			change_state("jump")
			return
		else:
			look_dir = Vector2(sign(target.get_global_position().x - global_position.x), 0)

func enter_jump():
	am.play("enemy_jump", self)
	move_dir = Vector2(sign(target.get_global_position().x - global_position.x), -1)
	look_dir = Vector2(move_dir.x, 0)

func do_jump():
	if is_on_floor():
		move_dir = Vector2.ZERO
		$AnimationPlayer.play("Stand")
		$JumpTimer.start(jump_delay)
		$CroakTimer.start(croak_time)
		if target == null:
			change_state("idle")
			return
		else:
			change_state("targeting")
			return

### SFX ###

func croak():
	am.play("enemy_croak", self)


func animate():
	$Sprite2D.flip_h = true if look_dir.x > 0.0 else false
	if is_on_floor():
		pass
	else:
		if move_dir.y < 0:
			$AnimationPlayer.play("Rise")
		elif move_dir.y > 0:
			$AnimationPlayer.play("Fall")


### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	target = body
	if state == "idle":
		change_state("targeting")

func _on_PlayerDetector_body_exited(_body):
	target = null
	if state == "targeting":
		change_state("idle")

func _on_croak_timer_timeout():
	if state == "targeting":
		$AnimationPlayer.play("Croak")


#func _on_difficulty_changed(new):
#	difficulty = new
#	match difficulty:
#
#		Difficulty.hard:
#			hp = 4
#			reward = 3
#			damage_on_contact = 2
#			$Sprite.modulate = Color(1,1,1)
#			$Sprite.texture = tx_toad
#			speed = Vector2(60, 120)
#
#		Difficulty.normal:
#			hp = 4
#			reward = 2
#			damage_on_contact = 2
#			$Sprite.modulate = Color(1,1,1)
#			$Sprite.texture = tx_frog
#			speed = Vector2(12, 120)
#
#		Difficulty.easy:
#			hp = 2
#			reward = 1
#			damage_on_contact = 1
#			$Sprite.modulate = Color(0, 0.976471, 1)
#			$Sprite.texture = tx_frog
#			speed = Vector2(12, 120)






