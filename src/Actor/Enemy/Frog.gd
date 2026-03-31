extends Enemy

var tx_toad = preload("res://assets/Actor/Enemy/Toad.png")
var tx_frog = preload("res://assets/Actor/Enemy/Frog.png")

var target

@export var jump_delay = 3.0
@export var difficulty: int = 0:
	set(val):
		match val:
			0:
				$TongueDetection/Collision.disabled = true
			1:
				$TongueDetection/Collision.disabled = false
		difficulty = val
var croak_time = 1.0
var move_dir = Vector2.ZERO
var look_dir = Vector2.LEFT:
	set(val):
		$TongueDetection/Collision.position = $TongueDetection/Collision.shape.size / 2.0 * Vector2(val.x, -1.0)
		look_dir = val

var tongue_damage: float = 2.0
var tongue_range: float = 50.0:
	set(val):
		$TongueDetection/Collision.shape.size = Vector2(val, 12.0)
		$TongueDetection/Collision.position = $TongueDetection/Collision.shape.size / 2.0 * Vector2(look_dir.x, -1.0)
		tongue_range = val
var player_in_vision: bool = false
var player_in_tongue_detection: bool = false

#enum Difficulty {easy, normal, hard}
#export(Difficulty) var difficulty = Difficulty.normal setget _on_difficulty_changed

func setup():
	change_state("idle")
	damage_on_contact = 1
	reward = 2
	hp = 3
	look_dir = look_dir
	tongue_range = tongue_range
	set_floor_stop_on_slope_enabled(true)




func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	if not is_on_floor():
		move_dir.y = 0 #don't allow them to jump if they are midair

	velocity = calc_velocity(move_dir)
	move_and_slide()
	animate()

### STATES ###

func do_idle():
	if (player_in_tongue_detection and $TongueTimer.is_stopped()):
		change_state("tongue_attack")
	elif (player_in_vision):
		change_state("targeting")

func do_targeting():
	if is_on_floor():
		if (difficulty == 1 and player_in_tongue_detection and $TongueTimer.is_stopped()):
			change_state("tongue_attack")
		elif $JumpTimer.time_left == 0.0:
			change_state("jump")
			return
		else:
			look_dir = Vector2(sign(target.get_global_position().x - global_position.x), 0)

func enter_jump(_last_state):
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

func enter_tongue_attack(_prev_state):
	move_dir = Vector2.ZERO
	$Tongue/Collision.disabled = false
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property($Tongue/Collision.shape, "size", Vector2(8.0 + tongue_range, 4.0), 0.3 )
	tween.tween_property($Tongue/Collision, "position", Vector2(-4.0 + tongue_range / 2.0, -4.0) * Vector2(look_dir.x, 1.0), 0.3)
	tween.set_parallel(false)
	tween.tween_property($Tongue/Collision.shape, "size", Vector2(8.0, 4.0), 0.3)
	tween.set_parallel(true)
	tween.tween_property($Tongue/Collision, "position", Vector2(-4.0, -4.0) * Vector2(look_dir.x, 1.0), 0.3)
	await tween.finished
	$Tongue/Collision.disabled = true
	$TongueTimer.start()
	if (player_in_vision):
		change_state("targeting")
	else:
		change_state("idle")

func do_tongue_attack(): # Later on when there's proper sprite, remove this
	$Tongue/Sprite.polygon = from_rectangle_to_polygon(Rect2($Tongue/Collision.position - $Tongue/Collision.shape.size / 2.0, $Tongue/Collision.shape.size))

func from_rectangle_to_polygon(rect: Rect2) -> PackedVector2Array:
	var res: PackedVector2Array = [rect.position, rect.position + Vector2(rect.size.x, 0.0), rect.position + rect.size, rect.position + Vector2(0.0, rect.size.y)]
	return res

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
	target = body.owner
	player_in_vision = true

func _on_PlayerDetector_body_exited(_body):
	target = null
	player_in_vision = false
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

func _on_TongueDetection_body_entered(body: Node2D) -> void:
	player_in_tongue_detection = true

func _on_TongueDetection_body_exited(body: Node2D) -> void:
	player_in_tongue_detection = false
