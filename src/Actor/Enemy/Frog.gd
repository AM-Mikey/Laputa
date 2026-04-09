extends Enemy

const ICON = preload("res://assets/Actor/Enemy/FrogIcon.png")
const TX_0 = preload("res://assets/Actor/Enemy/Frog.png")
const TX_1 = preload("res://assets/Actor/Enemy/Frog1.png")

var target

@export var jump_delay = 3.0
@export var difficulty := 1
var max_difficulty := 1
@export var croak_time = 1.0
var move_dir = Vector2.ZERO
var look_dir = Vector2.LEFT

@export var tongue_damage := 2.0
var tongue_length := 0.0
var tongue_max_length : float
var tongue_speed := 100.0
var tongue_ready_time := 0.5
var tongue_unready_time := 1.0
var tongue_cooldown_time := 6.0

func setup():
	change_state("idle")
	look_dir = $LookVector.direction
	tongue_max_length = abs($TongueRange.position.x)
	$TonguePlayerCast.target_position = Vector2($TongueRange.position.x, 0.0)
	$Tongue/WorldCast.target_position = Vector2($TongueRange.position.x, 0.0)
	var rect = RectangleShape2D.new()
	rect.size = Vector2(tongue_max_length, 2)
	$Tongue/CollisionShape2D.shape = rect
	$Tongue/CollisionShape2D.position = Vector2(look_dir.x * -1 * (tongue_max_length / 2.0), -7)

	set_floor_stop_on_slope_enabled(true)
	match difficulty:
		0:
			$TonguePlayerCast.enabled = false
			hp = 3
			reward = 2
			damage_on_contact = 1
			$Sprite2D.texture = TX_0
			speed = Vector2(60, 130)
		1:
			$TonguePlayerCast.enabled = true
			hp = 4
			reward = 3
			damage_on_contact = 2
			$Sprite2D.texture = TX_1
			speed = Vector2(35, 100)


func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	if !is_on_floor():
		move_dir.y = 0 #don't allow them to jump if they are midair

	velocity = calc_velocity(move_dir)
	move_and_slide()
	animate()




### STATES ###

func do_idle(_delta): #might add tongue ready here as well
	#if difficulty == 1:
		#pass
	if target:
		change_state("jump_ready")
		return

func do_jump_ready(_delta):
	if is_on_floor():
		if $JumpTimer.is_stopped():
			change_state("jump")
			return
		elif target:
			look_dir = Vector2(sign(target.global_position.x - global_position.x), 0)
			$Tongue.scale.x = look_dir.x * -1
			$TonguePlayerCast.scale.x = look_dir.x * -1
			if tongue_player_cast_check() && $TongueCooldown.is_stopped():
				change_state("tongue_ready")
				return
		elif target == null:
			change_state("idle")
			return


func enter_jump(_last_state):
	am.play("enemy_jump", self)
	if (target):
		move_dir = Vector2(sign(target.global_position.x - global_position.x), -1)
	look_dir = Vector2(move_dir.x, 0)

func do_jump(_delta):
	if is_on_floor():
		move_dir = Vector2.ZERO
		$AnimationPlayer.play("Stand")
		$JumpTimer.start(jump_delay)
		$CroakTimer.start(croak_time)
		if target:
			change_state("jump_ready")
			return
		else:
			change_state("idle")
			return

func enter_tongue_ready(_prev_state):
	$AnimationPlayer.play("TongueReady")
	$TongueReadyTimer.start(tongue_ready_time)
	$TongueUnreadyTimer.start(tongue_unready_time)

func do_tongue_ready(_delta):
	if is_on_floor() && tongue_player_cast_check() && $TongueReadyTimer.is_stopped():
		change_state("tongue_out")
		return
	if $TongueUnreadyTimer.is_stopped():
		change_state("tongue_unready")
		return

func enter_tongue_unready(_prev_state):
	$AnimationPlayer.play("TongueUnready")
	await $AnimationPlayer.animation_finished
	change_state("idle") #might go to another state if neccesary
	return

func enter_tongue_out(_prev_state): #TODO: change collision shape scale/position as well, add some effect when lick is successful?
	$TongueCooldown.start(tongue_cooldown_time)
	$AnimationPlayer.play("TongueOut")
	$Tongue/Sprite2D.frame = difficulty
	$Tongue/CollisionShape2D.shape.size.x = 0
	$Tongue/CollisionShape2D.position.x = 0
	$Tongue/CollisionShape2D.disabled = false
	await $AnimationPlayer.animation_finished
	var tween = create_tween()
	var tongue_duration = tongue_max_length / tongue_speed
	tongue_length = 16 #to start with
	tween.tween_property(self, "tongue_length", tongue_max_length, tongue_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func do_tongue_out(_delta):
	var tongue_scale = ((tongue_length - 16)/ 16.0) #16 for the start distance
	$Tongue/Sprite2D.scale.x = max(tongue_scale, 0.0) * -1
	$Tongue/CollisionShape2D.shape.size.x = tongue_length
	$Tongue/CollisionShape2D.position.x = (tongue_length / 2.0) * -1
	if tongue_length == tongue_max_length:
		change_state("tongue_in")

func enter_tongue_in(_prev_state):
	var tween = create_tween()
	var tongue_duration = tongue_max_length / tongue_speed
	tween.tween_property(self, "tongue_length", 16.0, tongue_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tween.finished
	$AnimationPlayer.play("TongueIn")
	await $AnimationPlayer.animation_finished
	$Tongue/CollisionShape2D.disabled = true
	change_state("idle") #might go to another state if neccesary
	return

func do_tongue_in(_delta):
	var tongue_scale = ((tongue_length - 16)/ 16.0) #16 for the start distance
	$Tongue/Sprite2D.scale.x = max(tongue_scale, 0.0) * -1
	$Tongue/CollisionShape2D.shape.size.x = tongue_length
	$Tongue/CollisionShape2D.position.x = (tongue_length / 2.0) * -1


### EFFECT ###

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



### HELPER ###

func tongue_player_cast_check() -> bool:
	if !($TonguePlayerCast.is_colliding()):
		return false
	var collider = $TonguePlayerCast.get_collider()
	if (collider):
		if (collider is not TileMapLayer):
			if (collider.get_collision_layer_value(1)):
				return true
	return false




### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	target = body.owner

func _on_PlayerDetector_body_exited(_body):
	target = null

func _on_croak_timer_timeout():
	if state == "jump_ready":
		$AnimationPlayer.play("Croak")

func _on_Tongue_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_value(18): #enemyhurt
		area.get_parent().hit(tongue_damage, $Tongue.global_position.direction_to(area.global_position))
	elif area.get_collision_layer_value(17): #playerhurt
		area.get_parent().hit(tongue_damage,  $Tongue.global_position.direction_to(area.global_position))
	elif area.get_collision_layer_value(9): #breakable
		area.get_parent().on_break("cut")
		#on_break(break_method) produced two fizzle particles so instead do:
	elif area.get_collision_layer_value(4): #world
		pass
	elif area.get_collision_layer_value(6): #armor
		pass
