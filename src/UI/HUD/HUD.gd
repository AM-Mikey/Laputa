extends Control

const GUNICON = preload("res://src/UI/HUD/GunIcon.tscn")
const UI_BULLET_FLY = preload("res://src/UI/HUD/UIBulletFly.tscn")

#onready var pc = get_tree().get_root().get_node("World/Juniper")
@onready var world = get_tree().get_root().get_node("World")

@export var gun: Node
@export var ao: Node
@export var hp_node: Node
@export var xp_node: Node
@export var cd: Node
@export var ammo: Node
@export var mon: Node

@onready var ao_1 = ao.get_node("Num1")
@onready var ao_2 = ao.get_node("Num2")
@onready var ao_3 = ao.get_node("Num3")
@onready var ao_4 = ao.get_node("Num4")
@onready var ao_5 = ao.get_node("Num5")
@onready var ao_6 = ao.get_node("Num6")

@onready var hp_lost = hp_node.get_node("Lost")
@onready var hp_lost_cap = hp_lost.get_node("Cap")
@onready var hp_progress = hp_node.get_node("Progress")
@onready var hp_progress_cap = hp_progress.get_node("Cap")
@onready var hp_1 = hp_node.get_node("Num1")
@onready var hp_2 = hp_node.get_node("Num2")

@onready var xp_lost = xp_node.get_node("Lost")
@onready var xp_lost_cap = xp_lost.get_node("Cap")
@onready var xp_progress = xp_node.get_node("Progress")
@onready var xp_progress_cap = xp_progress.get_node("Cap")
@onready var xp_flash = xp_node.get_node("Flash")
@onready var xp_max = xp_node.get_node("Max")
@onready var xp_num = xp_node.get_node("Num")

@onready var cd_progress = cd.get_node("Progress")
@onready var cd_progress_cap = cd_progress.get_node("Cap")

@onready var ammo_top_animator = ammo.get_node("TopAnimator")
@onready var ammo_bottom_animator = ammo.get_node("BottomAnimator")
@onready var ammo_fly = ammo.get_node("Fly")

@onready var mon_1 = mon.get_node("Num1")
@onready var mon_2 = mon.get_node("Num2")
@onready var mon_3 = mon.get_node("Num3")

@onready var weapon_wheel = gun.get_node("%WeaponWheel")
@onready var weapon_wheel_animator = gun.get_node("%WeaponWheelAnimator")
@onready var weapon_wheel_tilt_animator = gun.get_node("%WeaponWheelTiltAnimator")

@onready var animation_player = %AnimationPlayer

var WheelVisible = false

func _ready():
	if world.has_node("Juniper"):
		var pc = world.get_node("Juniper")
		pc.hp_updated.connect(update_hp)
		pc.guns_updated.connect(update_guns)
		pc.xp_updated.connect(update_xp)
		pc.money_updated.connect(update_money)
		pc.invincibility_end.connect(update_hpflash)
		pc.setup_hud()
		setup_lost_bars(pc.hp, pc.guns.get_child(0).xp)
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)

func _process(_delta):
	set_cap_pos(hp_lost, 38, hp_lost_cap)
	set_cap_pos(xp_lost, 38, xp_lost_cap)

	if world.has_node("Juniper"):
		var pc = world.get_node("Juniper")
		if pc.guns.get_child(0) != null: #TODO: make this connected via signal
			cd_progress.visible = true
			cd_progress.value = 100 - ((pc.get_node("GunManager/CooldownTimer").time_left / pc.guns.get_child(0).cooldown_time) * 100)
			set_cap_pos(cd_progress, 37, cd_progress_cap)
		else: cd_progress.visible = false

func update_guns(guns, cause = "default", do_xp_flash = false):
	var main_icon = gun.get_node("GunIcon")

	if cause == "shiftleft":
		display_weapon_wheel(guns, "CCW")
		ammo_animate("reload", 5.0)
	if cause == "shiftright":
		display_weapon_wheel(guns, "CW")
		ammo_animate("reload", 5.0)

	for g in guns:
		if guns.find(g) == 0: #main gun
			main_icon.texture = g["icon_texture"]
			update_xp(g.xp, g.max_xp, g.level, g.max_level, do_xp_flash)
			#update_ammo(g.ammo, g.max_ammo)
		#else:
			#var gun_icon = GUNICON.instantiate() #all other
			#gun_icon.texture = g["texture"]
			#hbox.add_child(gun_icon)
	if cause == "fire":
		var pc = world.get_node("Juniper")
		var speed: float = 0.8 / pc.guns.get_child(0).cooldown_time
		var is_infinite: bool = pc.guns.get_child(0).max_ammo == 0
		ammo_animate("reset")

		if is_infinite: ammo_top_animator.play("BulletShootInfinite", -1.0, speed)
		else: ammo_top_animator.play("BulletShoot", -1.0, speed)
		await ammo_top_animator.animation_finished

		ammo_animate("reload") #TODO: timing issues with this
		var ui_bullet_fly = UI_BULLET_FLY.instantiate()
		ui_bullet_fly.is_infinite = is_infinite
		ammo_fly.add_child(ui_bullet_fly)
	if cause == "getammo":
		ammo_animate("reload", 5.0)

func display_weapon_wheel(guns, rot_dir: String):
	if not WheelVisible:
		WheelVisible = true
		weapon_wheel_tilt_animator.play("TiltIn", -1, 3.0)
	weapon_wheel_tilt_animator.get_node("Timer").start(1.0)

	match rot_dir:
		"CW":
				weapon_wheel_animator.play("CW", -1, 4.0)
				weapon_wheel.get_node("Bullet1/Gun").texture = guns[0].icon_texture
				weapon_wheel.get_node("Bullet2/Gun").texture = guns[1].icon_small_texture
				weapon_wheel.get_node("Bullet3/Gun").texture = guns[2].icon_small_texture
				weapon_wheel.get_node("Bullet5/Gun").texture = guns[-2].icon_small_texture
				weapon_wheel.get_node("Bullet6/Gun").texture = guns[-1].icon_small_texture
		"CCW":
				weapon_wheel_animator.play("CCW", -1, 4.0)
				#await get_tree().create_timer(0.8) #i still dont know why but i dont ask questions
				weapon_wheel.get_node("Bullet1/Gun").texture = guns[0].icon_texture
				weapon_wheel.get_node("Bullet2/Gun").texture = guns[1].icon_small_texture
				weapon_wheel.get_node("Bullet3/Gun").texture = guns[2].icon_small_texture
				weapon_wheel.get_node("Bullet5/Gun").texture = guns[-2].icon_small_texture
				weapon_wheel.get_node("Bullet6/Gun").texture = guns[-1].icon_small_texture




func _on_Timer_timeout():
	WheelVisible = false
	weapon_wheel_tilt_animator.play("TiltOut", -1, 3.0)


#func display_guns():
	#$HBox/Gun/Sprite2D

func ammo_animate(animation, speed: float = -1):
	var pc = world.get_node("Juniper")
	if speed == -1:
		speed = 0.8 / pc.guns.get_child(0).cooldown_time

	if pc.guns.get_child(0).max_ammo != 0:
		if pc.guns.get_child(0).ammo == 0:
			if animation == "reload":
				ammo_bottom_animator.play("BulletReload0", -1.0, speed)
			elif animation == "reset":
				ammo_bottom_animator.play("Reset1")
		else:
			var ammo_percentage: float = float(pc.guns.get_child(0).ammo) / float(pc.guns.get_child(0).max_ammo)
			if ammo_percentage > 0.833:
				if animation == "reload":
					ammo_bottom_animator.play("BulletReload6", -1.0, speed)
				elif animation == "reset":
					ammo_bottom_animator.play("Reset6")
			elif ammo_percentage > 0.667:
				if animation == "reload":
					ammo_bottom_animator.play("BulletReload5", -1.0, speed)
				elif animation == "reset":
					ammo_bottom_animator.play("Reset5")
			elif ammo_percentage > 0.5:
				if animation == "reload":
					ammo_bottom_animator.play("BulletReload4", -1.0, speed)
				elif animation == "reset":
					ammo_bottom_animator.play("Reset4")
			elif ammo_percentage > 0.333:
				if animation == "reload":
					ammo_bottom_animator.play("BulletReload3", -1.0, speed)
				elif animation == "reset":
					ammo_bottom_animator.play("Reset3")
			elif ammo_percentage > 0.167:
				if animation == "reload":
					ammo_bottom_animator.play("BulletReload2", -1.0, speed)
				elif animation == "reset":
					ammo_bottom_animator.play("Reset2")
			else:
				if animation == "reload":
					ammo_bottom_animator.play("BulletReload1", -1.0, speed)
				elif animation == "reset":
					ammo_bottom_animator.play("Reset1")
	else:
		if animation == "reload":
			ammo_bottom_animator.play("BulletReloadInfinite", -1.0, speed)
		elif animation == "reset":
			ammo_bottom_animator.play("ResetInfinite")

func update_hp(hp, max_hp):
	var pc = world.get_node("Juniper")
	hp_progress.value = hp
	display_hp_number(hp, max_hp)
	hp_progress.max_value = max_hp
	hp_lost.max_value = max_hp
	set_cap_pos(hp_progress, 38, hp_progress_cap)


	if hp < hp_lost.value:
		if hp > 0:
			$AnimationPlayerHp.stop()
			$AnimationPlayerHp.play("HpFlash")
			var tween = get_tree().create_tween()
			tween.tween_property(hp_lost, "value", hp, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.4)
	else: #increasing, just set it
		hp_lost.value = hp


func display_hp_number(hp, max_hp):
	hp_1.visible = true
	hp_2.visible = true
	if hp > 0 and hp < 10:
		hp_1.visible = false
		hp_2.visible = true
		hp_2.frame_coords.x = hp
	elif hp >= 10 and hp < 100:
		hp_1.visible = true
		hp_2.visible = true
		hp_1.frame_coords.x = (hp % 100) / 10
		hp_2.frame_coords.x = hp % 10
	elif hp >= 100:
		hp_1.frame_coords.x = 9
		hp_2.frame_coords.x = 9
		print("Warning: over 99 life cannot be displayed!")
	else:
		printerr("ERROR: hud cannot display hp number")

	if float(hp) / float(max_hp) <= .20: #less than 10% make red
		hp_1.frame_coords.y = 2
		hp_2.frame_coords.y = 2
	elif float(hp) / float(max_hp) <= .40: #less than 20% left, make gold
		hp_1.frame_coords.y = 3
		hp_2.frame_coords.y = 3
	else:
		hp_1.frame_coords.y = 5
		hp_2.frame_coords.y = 5

func update_xp(xp, max_xp, level, max_level, do_xp_flash = false):
	modulate = Color(1, 1, 1) #to prevent flash animation from stopping on a transparent frame
	xp_num.frame_coords.x = level
	if do_xp_flash:
		animation_player.play("XpFlash")
	xp_progress.value = xp
	xp_progress.max_value = max_xp
	xp_lost.max_value = max_xp
	set_cap_pos(xp_progress, 38, xp_progress_cap)

	if xp < xp_lost.value:
		var tween = get_tree().create_tween()
		tween.tween_property(xp_lost, "value", xp, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.4)
	else: #increasing, just set it
		xp_lost.value = xp

	if xp == max_xp and level == max_level:
		xp_progress.visible = false
		xp_max.visible = true
	else:
		xp_progress.visible = true
		xp_max.visible = false


func update_ammo(have, maximum): #TODO: do we use this?
	pass
		#ao.ammo = have
		#ao.max_ammo = maximum
		#ao.display_ammo()


func update_money(money):
	mon_1.visible = true
	mon_2.visible = true
	mon_3.visible = true

	if money >= 0 and money < 10:
		mon_1.visible = false
		mon_2.visible = false
		mon_3.frame_coords.x = money
	elif money >= 10 and money < 100:
		mon_1.visible = false
		mon_2.frame_coords.x = (money % 100) / 10
		mon_3.frame_coords.x = money % 10
	elif money >= 100 and money < 1000:
		mon_1.frame_coords.x = (money % 1000) / 100
		mon_2.frame_coords.x = (money % 100) / 10
		mon_3.frame_coords.x = money % 10
	elif money >= 1000:
		mon_1.frame_coords.x = 9
		mon_2.frame_coords.x = 9
		mon_3.frame_coords.x = 9
		print("WARNING: hud cannot display money higher than 999")
	else:
		printerr("ERROR: hud cannot display money value of: " + money)

func update_hpflash():
	$AnimationPlayerHp.stop()

### HELPER ###

func set_cap_pos(bar, length, cap):
	cap.position.x = length * bar.value / bar.max_value
	cap.visible = false if bar.value == 0 else true

func setup_lost_bars(hp, xp): #needs to be done so that update can tell that it's decreased
	hp_lost.value = hp
	#set_cap_pos(hp_lost, 38, hp_lost_cap) #already on _process()
	xp_lost.value = xp
	#set_cap_pos(xp_lost, 38, xp_lost_cap)



### SIGNALS ###

func _resolution_scale_changed(resolution_scale):
	size = get_tree().get_root().size / resolution_scale
	position = Vector2(0, 0)
