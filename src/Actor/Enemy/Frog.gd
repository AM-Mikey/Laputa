extends Enemy

const ICON = preload("res://assets/Actor/Enemy/FrogIcon.png")
const TX_0 = preload("res://assets/Actor/Enemy/Frog.png")
const TX_1 = preload("res://assets/Actor/Enemy/Frog1.png")

var target
var see_target: bool = false

@export var jump_delay = 3.0
@export var difficulty := 1
var max_difficulty := 1
@export var croak_time = 1.0
var move_dir = Vector2.ZERO
var look_dir = Vector2.LEFT:
	set(val):
		$TongueDetection.target_position.x = (8.0 + tongue_range) * val.x
		look_dir = val

@export var tongue_damage: float = 2.0
var tongue_range: float = 50.0:
	set(val):
		$TongueDetection.target_position.x = (8.0 + val) * look_dir.x
		tongue_range = val
var tongue_speed := 150.0
var tongue_tween: Tween

func setup():
	change_state("idle")
	look_dir = $LookVector.direction
	tongue_range = abs($TongueRange.position.x)
	set_floor_stop_on_slope_enabled(true)
	match difficulty:
		0:
			$TongueDetection.enabled = false
			hp = 3
			reward = 2
			damage_on_contact = 1
			$Sprite2D.texture = TX_0
			speed = Vector2(60, 120)
		1:
			$TongueDetection.enabled = true
			hp = 4
			reward = 3
			damage_on_contact = 2
			$Sprite2D.texture = TX_1
			speed = Vector2(12, 120)


func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	if !is_on_floor():
		move_dir.y = 0 #don't allow them to jump if they are midair

	velocity = calc_velocity(move_dir)
	move_and_slide()
	animate()

	if (target):
		see_target = check_to_see_player(target)



### STATES ###

func do_idle(_delta):
	if difficulty == 1 && is_on_floor() && tongue_detection_see_player() && $TongueTimer.is_stopped():
		change_state("tongue_attack")
		return
	elif (see_target):
		change_state("targeting")
		return

func do_targeting(_delta):
	if is_on_floor():
		if difficulty == 1 && tongue_detection_see_player() && $TongueTimer.is_stopped():
			change_state("tongue_attack")
			return
		elif $JumpTimer.time_left == 0.0:
			change_state("jump")
			return
		elif !see_target:
			change_state("idle")
			return
		elif target:
			look_dir = Vector2(sign(target.global_position.x - global_position.x), 0)



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
		if see_target:
			change_state("targeting")
			return
		else:
			change_state("idle")
			return



func enter_tongue_attack(_prev_state):
	var tongue_time: float = tongue_range / tongue_speed
	$Tongue/CollisionShape2D.shape.size = Vector2(8.0, 4.0)
	$Tongue/CollisionShape2D.position = Vector2(4.0, -4.0) * Vector2(look_dir.x, 1.0)
	$Tongue/Sprite.visible = true
	move_dir = Vector2.ZERO
	$Tongue/CollisionShape2D.disabled = false
	$Tongue/WorldCast.target_position.x = 8.0 * look_dir.x
	$Tongue/WorldCast.enabled = true
	tongue_tween = create_tween()
	tongue_tween.set_parallel()
	tongue_tween.tween_property($Tongue/CollisionShape2D.shape, "size", Vector2(8.0 + tongue_range, 4.0), tongue_time)
	tongue_tween.tween_property($Tongue/CollisionShape2D, "position", Vector2(4.0 + tongue_range / 2.0, -4.0) * Vector2(look_dir.x, 1.0), tongue_time)
	tongue_tween.tween_property($Tongue/WorldCast, "target_position:x", (8.0 + tongue_range) * look_dir.x, tongue_time)

func do_tongue_attack(_delta):
	# Later on when there's proper sprite, remove all thing related to $Tongue/Sprite
	$Tongue/Sprite.polygon = from_rectangle_to_polygon(Rect2($Tongue/CollisionShape2D.position - $Tongue/CollisionShape2D.shape.size / 2.0, $Tongue/CollisionShape2D.shape.size))

	if tongue_tween:
		if !tongue_tween.is_running() || $Tongue/WorldCast.is_colliding():
			change_state("tongue_retract")
			return

func exit_tongue_attack(_next_state):
	if (tongue_tween):
		tongue_tween.kill()
		tongue_tween = null



func enter_tongue_retract(_prev_state):
	var tongue_time: float = abs($Tongue/WorldCast.target_position.x - (8.0 * look_dir.x)) / tongue_speed
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property($Tongue/CollisionShape2D.shape, "size", Vector2(8.0, 4.0), tongue_time)
	tween.tween_property($Tongue/CollisionShape2D, "position", Vector2(4.0, -4.0) * Vector2(look_dir.x, 1.0), tongue_time)
	tween.tween_property($Tongue/WorldCast, "target_position:x", 8.0 * look_dir.x, tongue_time)
	await tween.finished
	$Tongue/WorldCast.enabled = false
	$Tongue/CollisionShape2D.disabled = true
	$Tongue/Sprite.visible = false
	$TongueTimer.start()
	if (see_target):
		change_state("targeting")
	else:
		change_state("idle")

func do_tongue_attack_retract(_delta):
	# Later on when there's proper sprite, remove this
	$Tongue/Sprite.polygon = from_rectangle_to_polygon(Rect2($Tongue/CollisionShape2D.position - $Tongue/CollisionShape2D.shape.size / 2.0, $Tongue/CollisionShape2D.shape.size))



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

func check_to_see_player(player) -> bool:
	var raycast_parameter: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	raycast_parameter.from = global_position + Vector2(0.0, -14.0)
	raycast_parameter.to = player.global_position
	raycast_parameter.collide_with_areas = false
	raycast_parameter.collide_with_bodies = true
	raycast_parameter.collision_mask = 8 + 256 # world and breakable block
	var raycast_result: Dictionary = get_world_2d().direct_space_state.intersect_ray(raycast_parameter)
	if !(raycast_result.is_empty()):
		return false
	return true

func tongue_detection_see_player() -> bool:
	if !($TongueDetection.is_colliding()):
		return false
	var collider = $TongueDetection.get_collider()
	if (collider):
		if (collider is not TileMapLayer):
			if (collider.get_collision_layer_value(1)):
				return true
	return false

func from_rectangle_to_polygon(rect: Rect2) -> PackedVector2Array:
	var res: PackedVector2Array = [rect.position, rect.position + Vector2(rect.size.x, 0.0), rect.position + rect.size, rect.position + Vector2(0.0, rect.size.y)]
	return res



### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	target = body.owner

func _on_PlayerDetector_body_exited(_body):
	target = null
	see_target = false

func _on_croak_timer_timeout():
	if state == "targeting":
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
