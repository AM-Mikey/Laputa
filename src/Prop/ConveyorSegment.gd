extends Prop

const ICON = preload("res://assets/Prop/ConveyorIcon.png")

var toggled := true
var direction := Vector2.LEFT
var speed := 10.0

var acceleration = 40.0
var current_speed := 0.0
var target_speed := 0.0
var animation_direction := Vector2.LEFT

var segment: = "middle"
var trigger_parent: Node


func setup(): #Reminder: no function called can use await
	target_speed = _get_target_speed()
	current_speed = target_speed
	animation_direction = direction
	_apply_velocity()
	set_animation()
	set_physics_process(current_speed != target_speed)
	w.emit_signal("finished_spawn_entities_step")


func _physics_process(delta):
	target_speed = _get_target_speed()
	if current_speed == target_speed:
		set_physics_process(false)
		return
	current_speed = move_toward(current_speed, target_speed, acceleration * delta)
	_apply_velocity()
	set_animation()
	if current_speed == target_speed:
		set_physics_process(false)

func update_segment():
	target_speed = _get_target_speed()
	if current_speed != target_speed:
		set_physics_process(true)


func _get_target_speed() -> float:
	return speed * direction.x if toggled else 0.0

func _apply_velocity():
	$StaticBody2D.constant_linear_velocity.x = current_speed

func set_animation():
	var moving_dir: Vector2 = Vector2.LEFT if current_speed < 0.0 else Vector2.RIGHT
	if moving_dir != animation_direction || !$AnimationPlayer.is_playing():
		animation_direction = moving_dir
		match segment:
			"left":
				if direction == Vector2.LEFT:
					$AnimationPlayer.play("LeftCCW")
				elif direction == Vector2.RIGHT:
					$AnimationPlayer.play("LeftCW")
			"middle":
				if direction == Vector2.LEFT:
					$AnimationPlayer.play("MidCCW")
				elif direction == Vector2.RIGHT:
					$AnimationPlayer.play("MidCW")
			"right":
				if direction == Vector2.LEFT:
					$AnimationPlayer.play("RightCCW")
				elif direction == Vector2.RIGHT:
					$AnimationPlayer.play("RightCW")
	$AnimationPlayer.speed_scale = abs(current_speed) / 10.0



### SIGNALS ###

func _on_PlayerDetector_body_entered(_body):
	#rumble continuous
	pass
