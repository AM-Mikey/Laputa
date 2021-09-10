extends Control

onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Recruit")


func _process(delta):
	if world.is_release:
		$VBox/General/Label.text = "Laputa " + world.internal_version + " (" + world.release_version+ ")"
	else:
		$VBox/General/Label.text = "Laputa " + world.internal_version + " (" + world.development_stage+ ")"
	$VBox/General/FPS.text = str(Engine.get_frames_per_second()) + " fps" 
	$VBox/General/Screen.text = str(OS.get_window_size().x) + "x" + str(OS.get_window_size().y)
	
	
	
	$VBox/HBox/C1/A/HP.text = str("%2.f" % pc.hp) + "/" + str("%2.f" % pc.max_hp)
	$VBox/HBox/C1/A/TotalXP.text = str(pc.total_xp)
	$VBox/HBox/C1/A/WeaponXP.text = str("%2.f" % pc.weapon_array.front().xp) + "/" + str("%2.f" % pc.weapon_array.front().max_xp)
	$VBox/HBox/C1/A/WeaponCooldown.text = str("%2.2f" % pc.get_node("WeaponManager/CooldownTimer").time_left)
	
	$VBox/HBox/C1/A/Velocity.text = str("%4.f" % pc.velocity.x) + "," + str("%4.f" % pc.velocity.y)
	$VBox/HBox/C1/A/Speed.text = str("%4.f" % pc.speed.x) + "," + str("%4.f" % pc.speed.y)
	$VBox/HBox/C1/A/Pos.text = str("%4.f" % pc.global_position.x) + "," + str("%4.f" % pc.global_position.y)
	$VBox/HBox/C1/A/JumpForgiveness.text = str("%2.2f" % pc.get_node("ForgivenessTimer").time_left)

	$VBox/HBox/C1/A/MoveDir.text = str("%2.f" % pc.move_dir.x) + "," + str("%2.f" % pc.move_dir.y)
	$VBox/HBox/C1/A/FaceDir.text = str("%2.f" % pc.face_dir.x) + "," + str("%2.f" % pc.face_dir.y)
	$VBox/HBox/C1/A/ShootDir.text = str("%2.f" % pc.shoot_dir.x) + "," + str("%2.f" % pc.shoot_dir.y)

	#useless since only retrieves player camera, which is at player position \/
	$VBox/HBox/C2/A/CameraPos.text = str("%4.f" % pc.get_node("PlayerCamera").global_position.x) + "," + str("%4.f" % pc.get_node("PlayerCamera").global_position.y)
	$VBox/HBox/C2/A/CameraOffset.text = str("%4.2f" % pc.get_node("PlayerCamera").offset_h) + "," + str("%4.2f" % pc.get_node("PlayerCamera").offset_v)


	$VBox/HBox/C2/A/Disabled.text = str(pc.disabled)
	$VBox/HBox/C2/A/Invincible.text = str(pc.invincible)
	$VBox/HBox/C2/A/DebugFly.text = str(pc.debug_flying)
	$VBox/HBox/C2/A/Floor.text = str(pc.is_on_floor())
	$VBox/HBox/C2/A/Water.text = str(pc.is_in_water)
	$VBox/HBox/C2/A/Ladder.text = str(pc.is_on_ladder)
	$VBox/HBox/C2/A/SSP.text = str(pc.is_on_ssp)
