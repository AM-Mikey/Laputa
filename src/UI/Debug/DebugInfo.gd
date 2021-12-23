extends Control
#TODO: this scene doesnt pass mouse input for some reason.

onready var world = get_tree().get_root().get_node("World")

func _ready():
	get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()
	
	if is_instance_valid(world.get_node("Recruit")):
		var pc = world.get_node("Recruit")
		pc.connect("weapons_updated", self, "on_weapons_updated")
		on_weapons_updated(pc.weapon_array)
	
	if world.is_release:
		$VBox/General/Label.text = "Laputa " + world.internal_version + " (" + world.release_version+ ")"
	else:
		$VBox/General/Label.text = "Laputa " + world.internal_version + " (" + world.development_stage+ ")"



func _physics_process(delta):
	get_parent().move_child(self, get_parent().get_child_count() - 1)
	$VBox/General/FPS.text = str(Engine.get_frames_per_second()) + " fps" 
	$VBox/General/Screen.text = str(OS.get_window_size().x) + "x" + str(OS.get_window_size().y)
	
	
	if is_instance_valid(world.get_node("Recruit")):
		var pc = world.get_node("Recruit")
		var mm = pc.get_node("MovementManager")

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


		$VBox/HBox/C2/A/CameraPos.text = str("%4.f" % pc.get_node("PlayerCamera").get_camera_screen_center().x) + "," + str("%4.f" % pc.get_node("PlayerCamera").get_camera_screen_center().y)
		$VBox/HBox/C2/A/CameraOffset.text = str("%+0.2f" % pc.get_node("PlayerCamera").offset_h) + "," + str("%+0.2f" % pc.get_node("PlayerCamera").offset_v)

		$VBox/HBox/C2/A/Disabled.text = str(pc.disabled)
		$VBox/HBox/C2/A/Invincible.text = str(pc.invincible)
		$VBox/HBox/C2/A/Floor.text = str(pc.is_on_floor())
		$VBox/HBox/C2/A/Inspect.text = str(pc.is_inspecting)
		$VBox/HBox/C2/A/SSP.text = str(pc.is_on_ssp)
		$VBox/HBox/C2/A/Water.text = str(pc.is_in_water)
		
		$VBox/HBox/C2/A/Front.text = str(world.get_node("Front").get_child_count())
		$VBox/HBox/C2/A/Middle.text = str(world.get_node("Middle").get_child_count())
		$VBox/HBox/C2/A/Back.text = str(world.get_node("Back").get_child_count())




func on_weapons_updated(weapon_array):
	for c in $VBox/General/Arrays/Weapon.get_children():
		if c.name != "Label":
			c.queue_free()
	for w in weapon_array:
		var label = Label.new()
		label.text = w.resource_name
		$VBox/General/Arrays/Weapon.add_child(label)



func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale
