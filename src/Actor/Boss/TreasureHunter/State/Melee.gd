extends State

var melee_lunge_force: = Vector2(250.0, -150.0)
@onready var melee_swing_hitbox = main.get_node("SwingHitbox")

func state_start(_prev_state: StringName):
	main.face_player()
	main.get_node("MeleeDetector").set_deferred("monitoring", false)
	$Startup.start()

func state_end(_next_state: StringName):
	$Startup.stop()
	$GroundMercy.stop()
	$EndLag.stop()
	melee_swing_hitbox.set_deferred("monitoring", false)
	melee_swing_hitbox.set_deferred("monitorable", false)

func state_physics_process(delta: float):
	if $Startup.time_left <= 0.0:
		main.move_and_slide()
		main.velocity.y = main.gravity * delta
		main.velocity.x = lerp(main.velocity.x, 0.0, 0.05)
		if $GroundMercy.time_left <= 0.0 and main.is_on_floor():
			if $EndLag.time_left <= 0.0:
				main.ap.play("idle")
				$EndLag.start()

### SIGNALS ###
func _on_EndLag_timeout() -> void:
	sm.change_state("ground_rush")


func _on_Startup_timeout() -> void:
	$GroundMercy.start()
	melee_swing_hitbox.set_deferred("monitoring", true)
	melee_swing_hitbox.set_deferred("monitorable", true)
	main.velocity = melee_lunge_force
	main.velocity.x *= main.look_dir.x
	main.ap.play("gun_swing")
