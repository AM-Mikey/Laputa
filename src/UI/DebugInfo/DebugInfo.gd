extends Control
#TODO: this scene doesnt pass mouse input for some reason.

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))


	if f.pc():
		var pc = f.pc()
		pc.connect("guns_updated", Callable(self, "_on_guns_updated"))
		am.connect("players_updated", Callable(self, "_on_audio_players_updated"))
		_on_guns_updated(pc.guns.get_children())

	if world.is_release:
		$VBox/General/Label.text = "Laputa " + world.internal_version + " (" + world.release_version+ ")"
	else:
		$VBox/General/Label.text = "Laputa " + world.internal_version + " (" + world.development_stage+ ")"
	_resolution_scale_changed(vs.resolution_scale)


func _physics_process(_delta):
	get_parent().move_child(self, get_parent().get_child_count() - 1)
	$VBox/General/FPS.text = str(Engine.get_frames_per_second()) + " fps"
	$VBox/General/Screen.text = str(get_window().get_size().x) + "x" + str(get_window().get_size().y)


	if (f.pc()):
		var pc = f.pc()
		var mm = pc.get_node("MovementManager")
		var active_gun = null
		if pc.guns.get_child(0) != null:
			active_gun = pc.guns.get_child(0)


		$VBox/HBox/C1/A/HP.text = str("%2.f" % pc.hp) + "/" + str("%2.f" % pc.max_hp)
		$VBox/HBox/C1/A/Money.text = str(pc.money)
		$VBox/HBox/C1/A/XP.text = str("%2.f" % active_gun.xp) + "/" + str("%2.f" % active_gun.max_xp)
		$VBox/HBox/C1/A/WeaponCooldown.text = str("%2.2f" % pc.get_node("GunManager/CooldownTimer").time_left)

		$VBox/HBox/C1/A/Velocity.text = str("%4.f" % pc.velocity.x) + "," + str("%4.f" % pc.velocity.y)
		$VBox/HBox/C1/A/Speed.text = str("%4.f" % mm.speed.x) + "," + str("%4.f" % mm.speed.y)
		$VBox/HBox/C1/A/Gravity.text = str("%.f" % pc.mm.gravity)
		$VBox/HBox/C1/A/Pos.text = str("%4.2f" % pc.global_position.x) + "," + str("%4.2f" % pc.global_position.y)
		$VBox/HBox/C1/A/Animation.text = str(pc.get_node("AnimationPlayer").current_animation)
		$VBox/HBox/C1/A/State.text = str(pc.get_node("MovementManager").current_state.name)

		$VBox/HBox/C1/A/MoveDir.text = str("%4.1f" % pc.move_dir.x) + "," + str("%4.1f" % pc.move_dir.y)
		$VBox/HBox/C1/A/LookDir.text = str("%4d" % pc.look_dir.x) + "," + str("%4d" % pc.look_dir.y)
		$VBox/HBox/C1/A/LockDir.text = str("%4d" % pc.direction_lock.x) + "," + str("%4d" % pc.direction_lock.y)
		$VBox/HBox/C1/A/ShootDir.text = str("%4.1f" % pc.shoot_dir.x) + "," + str("%4.1f" % pc.shoot_dir.y)


		$VBox/HBox/C2/A/CameraPos.text = str("%4.f" % pc.get_node("PlayerCamera").get_screen_center_position().x) + "," + str("%4.f" % pc.get_node("PlayerCamera").get_screen_center_position().y)
		$VBox/HBox/C2/A/CameraOffset.text = str("%+0.2f" % pc.get_node("PlayerCamera").drag_horizontal_offset) + "," + str("%+0.2f" % pc.get_node("PlayerCamera").drag_vertical_offset)

		$VBox/HBox/C2/A/Disabled.text = str(pc.disabled)
		$VBox/HBox/C2/A/CanInput.text = str(pc.can_input)
		$VBox/HBox/C2/A/Invincible.text = str(pc.invincible)
		#$VBox/HBox/C2/A/Inspect.text = str(pc.inspecting)
		$VBox/HBox/C2/A/Floor.text = str(pc.is_on_floor())
		$VBox/HBox/C2/A/Wall.text = str(pc.is_on_wall())
		$VBox/HBox/C2/A/Crouch.text = str(pc.is_crouching)
		$VBox/HBox/C2/A/SSP.text = str(pc.is_on_ssp)
		$VBox/HBox/C2/A/Water.text = str(pc.is_in_water)

		$VBox/HBox/C2/A/Front.text = str(world.get_node("Front").get_child_count())
		$VBox/HBox/C2/A/Middle.text = str(world.get_node("Middle").get_child_count())
		$VBox/HBox/C2/A/Back.text = str(world.get_node("Back").get_child_count())

		$VBox/HBox/C2/A/Main.text = str(ms.main_mission_stage)




func _on_guns_updated(guns):
	var array = $VBox/General/Arrays/Guns
	_clear_array(array)
	for g in guns:
		var label = Label.new()
		label.text = g.name
		array.add_child(label)

func _on_audio_players_updated():
	var sfx_array = $VBox/General/Arrays/Sfx
	var music_array = $VBox/General/Arrays/Music
	_clear_array(sfx_array)
	_clear_array(music_array)
	for p in am.sfx_queue:
		var label = Label.new()
		label.text = p[1] #sfx name
		sfx_array.add_child(label)
	for p in am.music_queue:
		var label = Label.new()
		label.text = p[1] #music name
		music_array.add_child(label)



func _clear_array(array):
	for c in array.get_children():
		if c.name != "Label":
			c.queue_free()



### SIGNALS ###

func _resolution_scale_changed(_resolution_scale):
	size = get_tree().get_root().size / Vector2i(world.dl.scale)
