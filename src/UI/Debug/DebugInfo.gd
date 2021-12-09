extends Control

onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Recruit")
onready var mm = pc.get_node("MovementManager")

func _ready():
	get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()


func _process(delta):
	get_parent().move_child(self, get_parent().get_child_count() - 1)
	
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
	
	$VBox/HBox/C1/A/Velocity.text = str("%4.f" % mm.velocity.x) + "," + str("%4.f" % mm.velocity.y)
	$VBox/HBox/C1/A/Speed.text = str("%4.f" % mm.speed.x) + "," + str("%4.f" % mm.speed.y)
	$VBox/HBox/C1/A/Gravity.text = str("%.f" % mm.gravity)
	$VBox/HBox/C1/A/Pos.text = str("%4.f" % pc.global_position.x) + "," + str("%4.f" % pc.global_position.y)
	$VBox/HBox/C1/A/JumpForgiveness.text = str("%2.2f" % mm.get_node("ForgiveTimer").time_left)

	$VBox/HBox/C1/A/MoveDir.text = str("%2.f" % pc.move_dir.x) + "," + str("%2.f" % pc.move_dir.y)
	$VBox/HBox/C1/A/FaceDir.text = str("%2.f" % pc.face_dir.x) + "," + str("%2.f" % pc.face_dir.y)
	$VBox/HBox/C1/A/ShootDir.text = str("%2.f" % pc.shoot_dir.x) + "," + str("%2.f" % pc.shoot_dir.y)

	#useless since only retrieves player camera, which is at player position \/
	$VBox/HBox/C2/A/CameraPos.text = str("%4.f" % pc.get_node("PlayerCamera").get_camera_screen_center().x) + "," + str("%4.f" % pc.get_node("PlayerCamera").get_camera_screen_center().y)
	$VBox/HBox/C2/A/CameraOffset.text = str("%+0.2f" % pc.get_node("PlayerCamera").offset_h) + "," + str("%+0.2f" % pc.get_node("PlayerCamera").offset_v)


	$VBox/HBox/C2/A/Disabled.text = str(pc.disabled)
	$VBox/HBox/C2/A/Invincible.text = str(pc.invincible)
#	$VBox/HBox/C2/A/DebugFly.text = str(pc.debug_flying)
	$VBox/HBox/C2/A/Floor.text = str(pc.is_on_floor())
	$VBox/HBox/C2/A/Water.text = str(pc.is_in_water)
	$VBox/HBox/C2/A/Ladder.text = str(pc.is_on_ladder)
	$VBox/HBox/C2/A/SSP.text = str(pc.is_on_ssp)
	$VBox/HBox/C2/A/Inspect.text = str(pc.is_inspecting)

	$VBox/HBox/C2/A/Front.text = str(world.get_node("Front").get_child_count())
	$VBox/HBox/C2/A/Middle.text = str(world.get_node("Middle").get_child_count())
	$VBox/HBox/C2/A/Back.text = str(world.get_node("Back").get_child_count())

func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale
