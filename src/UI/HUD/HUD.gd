extends Control

const WEAPONICON = preload("res://src/UI/HUD/WeaponIcon.tscn")
const AMMOCOUNT = preload("res://src/UI/HUD/AmmoCount.tscn")


#onready var p = get_tree().get_root().get_node("World/Recruit")
onready var world = get_tree().get_root().get_node("World")

func _ready():
	var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()
	
	
	if world.has_node("Recruit"):
		var pc = world.get_node("Recruit")
		pc.connect("hp_updated", self, "update_hp")
		pc.connect("weapons_updated", self, "update_weapons")
		pc.connect("total_xp_updated", self, "update_total_xp")
		pc.setup_hud()
		

func _process(_delta):
	$HpBar/HpLost/HpLostCap.position.x = 38 * $HpBar/HpLost.value / $HpBar/HpLost.max_value
	if world.has_node("Recruit"):
		var pc = world.get_node("Recruit")
		if pc.weapon_array.front() != null: #TODO: make this independant
			$CooldownBar/TextureProgress.visible = true
			$CooldownBar/TextureProgress.value = 100 - ((pc.get_node("WeaponManager/CooldownTimer").time_left / pc.weapon_array.front().cooldown_time) * 100)
		else: $CooldownBar/TextureProgress.visible = false

func update_weapons(weapon_array):
	for i in $Weapon/HBoxContainer.get_children(): #clear old
			i.queue_free()
	for w in weapon_array:
		if weapon_array.find(w) == 0: #check if front
			var weapon_icon = WEAPONICON.instance() #add the first icon
			weapon_icon.texture = w["icon_texture"]
			$Weapon/HBoxContainer.add_child(weapon_icon)
			$Weapon/HBoxContainer.move_child(weapon_icon, 0)
			
			update_xp(w.xp, w.max_xp, w.level, w.max_level)
			update_ammo(w.ammo, w.max_ammo, w.needs_ammo)
		else: 
			var weapon_icon = WEAPONICON.instance() #add all other icons
			weapon_icon.texture = w["texture"]
			$Weapon/HBoxContainer.add_child(weapon_icon)

func update_hp(hp, max_hp):
	$HpBar/HpProgress.value = hp
	display_hp_number(hp, max_hp)
	
	$HpBar/HpProgress.max_value = max_hp
	$HpBar/HpLost.max_value = max_hp
	
	$HpBar/HpProgress/HpCap.position.x = 38 * $HpBar/HpProgress.value / $HpBar/HpProgress.max_value
	
	if hp < $HpBar/HpLost.value:
		$AnimationPlayer.play("Flash")
	$HpBar/LostTween.interpolate_property($HpBar/HpLost, "value", $HpBar/HpLost.value, hp, 0.4, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.4)
	$HpBar/LostTween.start()


func display_hp_number(hp, max_hp):
	if hp > 0 and hp < 10:
		$HpBar/Num1.visible = false
		$HpBar/Num2.visible = true
		$HpBar/Num2.frame_coords.x = hp
	elif hp >= 10 and hp < 100:
		$HpBar/Num1.visible = true
		$HpBar/Num2.visible = true
		$HpBar/Num1.frame_coords.x = (hp % 100) / 10
		$HpBar/Num2.frame_coords.x = hp % 10
	elif hp >= 100:
		$HpBar/Num1.visible = true
		$HpBar/Num2.visible = true
		$HpBar/Num1.frame_coords.x = 9
		$HpBar/Num2.frame_coords.x = 9
	else:
		printerr("ERROR: hud cannot display hp number")
		
	if float(hp) / float(max_hp) <= .20: #less than 10% make red
		$HpBar/Num1.frame_coords.y = 2
		$HpBar/Num2.frame_coords.y = 2
	elif float(hp) / float(max_hp) <= .40: #less than 20% left, make gold
		$HpBar/Num1.frame_coords.y = 3
		$HpBar/Num2.frame_coords.y = 3
	else:
		$HpBar/Num1.frame_coords.y = 5
		$HpBar/Num2.frame_coords.y = 5

func update_xp(xp, max_xp, level, max_level):
	modulate = Color(1, 1, 1) #to prevent flash animation from stopping on a transparent frame

	$XpBar/Num.frame_coords.x = level

#	if flash:
#		$AnimationPlayer.play("XpFlash")
	$XpBar/XpProgress.value = xp

	$XpBar/XpProgress.max_value = max_xp



	if xp == max_xp and level == max_level:
		$XpBar/XpProgress.visible = false
		$XpBar/XpMax.visible = true
	else:
		$XpBar/XpProgress.visible = true
		$XpBar/XpMax.visible = false



func update_ammo(ammo, max_ammo, needs_ammo):
	if $Weapon/HBoxContainer.has_node("AmmoCount"):
			$Weapon/HBoxContainer/AmmoCount.free()
	if needs_ammo:
		var ammo_count = AMMOCOUNT.instance()
		ammo_count.ammo = ammo
		ammo_count.max_ammo = max_ammo
		$Weapon/HBoxContainer.add_child(ammo_count)
		$Weapon/HBoxContainer.move_child(ammo_count, 1)


func update_total_xp(total_xp):
	if total_xp >= 0 and total_xp < 10:
		$MoneyCount/Num1.visible = false
		$MoneyCount/Num2.visible = false
		$MoneyCount/Num3.visible = true
		$MoneyCount/Num3.frame_coords.x = total_xp
	elif total_xp >= 10 and total_xp < 100:
		$MoneyCount/Num1.visible = false
		$MoneyCount/Num2.visible = true
		$MoneyCount/Num3.visible = true
		$MoneyCount/Num2.frame_coords.x = (total_xp % 100) / 10
		$MoneyCount/Num3.frame_coords.x = total_xp % 10
	elif total_xp >= 100 and total_xp < 1000:
		$MoneyCount/Num1.visible = true
		$MoneyCount/Num2.visible = true
		$MoneyCount/Num3.visible = true
		$MoneyCount/Num1.frame_coords.x = (total_xp % 1000) / 100
		$MoneyCount/Num2.frame_coords.x = (total_xp % 100) / 10
		$MoneyCount/Num3.frame_coords.x = total_xp % 10
	elif total_xp >= 1000:
		$MoneyCount/Num1.visible = true
		$MoneyCount/Num2.visible = true
		$MoneyCount/Num3.visible = true
		$MoneyCount/Num1.frame_coords.x = 9
		$MoneyCount/Num2.frame_coords.x = 9
		$MoneyCount/Num3.frame_coords.x = 9
		print("WARNING: hud cannot display total_xp higher than 999")
	else:
		printerr("ERROR: hud cannot display total_xp value of: " + total_xp)


func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale
