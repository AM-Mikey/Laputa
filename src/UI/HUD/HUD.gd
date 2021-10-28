extends Control

const WEAPONICON = preload("res://src/UI/HUD/WeaponIcon.tscn")
const AMMOCOUNT = preload("res://src/UI/HUD/AmmoCount.tscn")


onready var p = get_tree().get_root().get_node("World/Recruit")
onready var world = get_tree().get_root().get_node("World")

func _ready():
	get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()
	
	update_hp()
	update_weapon()

	

func _process(_delta):
	$HpBar/HpLost/HpLostCap.position.x = 38 * $HpBar/HpLost.value / $HpBar/HpLost.max_value
	
	if p.get_node("WeaponManager").weapon != null:
		if $CooldownBar/TextureProgress.visible == false:
			$CooldownBar/TextureProgress.visible = true
		$CooldownBar/TextureProgress.value = 100 - ((p.get_node("WeaponManager/CooldownTimer").time_left / p.get_node("WeaponManager").weapon.cooldown_time) * 100)

func update_weapon():
	for i in $Weapon/HBoxContainer.get_children(): #clear old
		i.queue_free()

	for a in p.weapon_array:
		if p.weapon_array.find(a) == 0:
				var weapon_icon = WEAPONICON.instance() #add the first icon
				weapon_icon.texture = p.weapon_array.front()["icon_texture"]
				$Weapon/HBoxContainer.add_child(weapon_icon)
				$Weapon/HBoxContainer.move_child(weapon_icon, 0)
		else: 
			var weapon_icon = WEAPONICON.instance() #add all other icons
			weapon_icon.texture = a["texture"]
			$Weapon/HBoxContainer.add_child(weapon_icon)

	update_xp(false)
	update_ammo()

func update_hp():
	$HpBar/HpProgress.value = p.hp
	display_hp_number(p.hp, p.max_hp)
	
	$HpBar/HpProgress.max_value = p.max_hp
	$HpBar/HpLost.max_value = p.max_hp
	
	$HpBar/HpProgress/HpCap.position.x = 38 * $HpBar/HpProgress.value / $HpBar/HpProgress.max_value
	
	if p.hp < $HpBar/HpLost.value:
		$AnimationPlayer.play("Flash")
	$HpBar/LostTween.interpolate_property($HpBar/HpLost, "value", $HpBar/HpLost.value, p.hp, 0.4, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.4)
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

func update_xp(flash):
	modulate = Color(1, 1, 1) #to prevent flash animation from stopping on a transparent frame
	display_money_number()
	$XpBar/Num.frame_coords.x = p.weapon_array.front().level
	
	if flash:
		$AnimationPlayer.play("XpFlash")
	$XpBar/XpProgress.value = p.weapon_array.front().xp
		
	$XpBar/XpProgress.max_value = p.weapon_array.front().max_xp
	
	
	
	if p.weapon_array.front().xp == p.weapon_array.front().max_xp and p.weapon_array.front().level == p.weapon_array.front().max_level:
		$XpBar/XpProgress.visible = false
		$XpBar/XpMax.visible = true
	else:
		$XpBar/XpProgress.visible = true
		$XpBar/XpMax.visible = false



func update_ammo():
	if $Weapon/HBoxContainer.has_node("AmmoCount"):
			$Weapon/HBoxContainer/AmmoCount.free()
	if p.weapon_array.front().needs_ammo:
		var ammo_count = AMMOCOUNT.instance()
		ammo_count.ammo = p.weapon_array.front().ammo
		ammo_count.max_ammo = p.weapon_array.front().max_ammo
		$Weapon/HBoxContainer.add_child(ammo_count)
		$Weapon/HBoxContainer.move_child(ammo_count, 1)


func display_money_number():
	if p.total_xp >= 0 and p.total_xp < 10:
		$MoneyCount/Num1.visible = false
		$MoneyCount/Num2.visible = false
		$MoneyCount/Num3.visible = true
		$MoneyCount/Num3.frame_coords.x = p.total_xp
	elif p.total_xp >= 10 and p.total_xp < 100:
		$MoneyCount/Num1.visible = false
		$MoneyCount/Num2.visible = true
		$MoneyCount/Num3.visible = true
		$MoneyCount/Num2.frame_coords.x = (p.total_xp % 100) / 10
		$MoneyCount/Num3.frame_coords.x = p.total_xp % 10
	elif p.total_xp >= 100 and p.total_xp < 1000:
		$MoneyCount/Num1.visible = true
		$MoneyCount/Num2.visible = true
		$MoneyCount/Num3.visible = true
		$MoneyCount/Num1.frame_coords.x = (p.total_xp % 1000) / 100
		$MoneyCount/Num2.frame_coords.x = (p.total_xp % 100) / 10
		$MoneyCount/Num3.frame_coords.x = p.total_xp % 10
	elif p.total_xp >= 1000:
		$MoneyCount/Num1.visible = true
		$MoneyCount/Num2.visible = true
		$MoneyCount/Num3.visible = true
		$MoneyCount/Num1.frame_coords.x = 9
		$MoneyCount/Num2.frame_coords.x = 9
		$MoneyCount/Num3.frame_coords.x = 9
	else:
		printerr("ERROR: hud cannot display money number")


func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale
