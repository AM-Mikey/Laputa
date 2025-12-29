extends PhysicsProp

const SPARKLE = preload("res://src/Effect/Sparkle.tscn")

var active_players := []
var touching_ground := false
var bounce_number := 0
var bounce_volumes := [1.0, 0.75, 0.5, 0.25]
var bounce_sparkle_speeds := [[40.0, 50.0], [30.0, 40.0], [20.0, 30.0], [10.0, 20.0]]
var bounce_sparkle_counts := [4, 3, 2, 1]
var default_speed_scale = 1.0
var touched_speed_scale = 6.0
var touched_spin_time = 2.0
var spinup_speed_scale = 12.0
var spinup_spin_time = 0.5
var tween

func setup():
	base_gravity_scale = 0.5
	water_gravity_scale = 0.5
	gravity_scale = base_gravity_scale

func _input(event):
	if event.is_action_pressed("inspect") && !active_players.is_empty():
		for p in active_players:
			if !p.disabled && p.can_input:
				activate()

func _physics_process(_delta):
	if $Ground.is_colliding():
		if !touching_ground:
			sparkle_on_land()
			var volume
			if bounce_volumes.size() >= bounce_number + 1:
				volume = bounce_volumes[bounce_number]
			else:
				volume = 0.0
			am.play("prop_sparkle", self, null, volume)
			bounce_number += 1
			touching_ground = true
	else:
		touching_ground = false

func activate():
	am.play("save")
	sparkle_on_save()
	default_speed_scale = 0.5
	if tween:
		tween.stop()
	tween = get_tree().create_tween()
	tween.tween_property($AnimationPlayer, "speed_scale", spinup_speed_scale, spinup_spin_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	tween = get_tree().create_tween()
	tween.tween_property($AnimationPlayer, "speed_scale", default_speed_scale, touched_spin_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	SaveSystem.write_level_data_to_temp(w.current_level)
	SaveSystem.write_player_data_to_save(w.current_level)
	SaveSystem.copy_level_data_from_temp_to_save()

func sparkle_on_land():
	var sparkle_speeds
	var sparkle_count
	if bounce_sparkle_speeds.size() >= bounce_number + 1:
		sparkle_speeds = bounce_sparkle_speeds[bounce_number]
		sparkle_count = bounce_sparkle_counts[bounce_number]
	else:
		return

	var sparkle_left = SPARKLE.instantiate()
	sparkle_left.direction = Vector2(-1.0, -1.0)
	sparkle_left.global_position = $SparklePos.global_position
	sparkle_left.initial_velocity_min = sparkle_speeds[0]
	sparkle_left.initial_velocity_max = sparkle_speeds[1]
	sparkle_left.amount = sparkle_count
	w.front.add_child(sparkle_left)
	var sparkle_right = SPARKLE.instantiate()
	sparkle_right.direction = Vector2(1.0, -1.0)
	sparkle_right.global_position = $SparklePos.global_position
	sparkle_right.initial_velocity_min = sparkle_speeds[0]
	sparkle_right.initial_velocity_max = sparkle_speeds[1]
	sparkle_right.amount = sparkle_count
	w.front.add_child(sparkle_right)

func sparkle_on_save():
	var sparkle_left = SPARKLE.instantiate()
	sparkle_left.global_position = $SparklePos.global_position
	sparkle_left.direction = Vector2(-1.0, -1.0)

	w.front.add_child(sparkle_left)
	var sparkle_right = SPARKLE.instantiate()
	sparkle_right.direction = Vector2(1.0, -1.0)
	sparkle_right.global_position = $SparklePos.global_position
	w.front.add_child(sparkle_right)

#bounces, only allow activation on the ground
#spins faster when moving past
#spins based on movement speed
#sparkle trail and particles when it hits the ground, have it fall in slow motion for effect, like zelda post boss heart piece
#spins when saving and makes sparkle particles + sfx
#recolor based on scene

### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	active_players.append(body.get_parent())
	if tween:
		tween.stop()
	$AnimationPlayer.speed_scale = touched_speed_scale
	tween = get_tree().create_tween()
	tween.tween_property($AnimationPlayer, "speed_scale", default_speed_scale, touched_spin_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_PlayerDetector_body_exited(body):
	active_players.erase(body.get_parent())
	#$AnimationPlayer.speed_scale = default_speed_scale
