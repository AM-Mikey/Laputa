extends Control

var _hurt = load("res://assets/SFX/snd_quote_hurt.ogg")

onready var player = get_tree().get_root().get_node("World/Recruit")
onready var world = get_tree().get_root().get_node("World")

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()

func _process(delta):
	if player.get_node("WeaponManager").weapon != null:
		if $CooldownBar/TextureProgress.visible == false:
			$CooldownBar/TextureProgress.visible = true
		$CooldownBar/TextureProgress.value = 100 - ((player.get_node("WeaponManager/CooldownTimer").time_left / player.get_node("WeaponManager").weapon.cooldown_time) * 100)


func _on_Recruit_setup_ui(hp, max_hp, total_xp, level, xp, max_xp, needs_ammo, ammo, max_ammo, icon_texture):
	print("setting up ui")
	$HpBar/HpProgress.value = hp
	$HpBar/HpProgress.max_value = max_hp
	display_hp_number(hp, max_hp)
	$HpBar/HpLost.value = hp
	$HpBar/HpLost.max_value = max_hp
	
	display_money_number(total_xp)
	
	$XpBar/Num.frame_coords.x = level
	$XpBar/XpProgress.value = xp
	$XpBar/XpProgress.max_value = max_xp
	
	if icon_texture != null:
		$Weapon/HBoxContainer/Sprite.texture = icon_texture
		$Weapon/HBoxContainer/Sprite/Shadow.texture = icon_texture
	
	if needs_ammo:
		display_ammo_number(ammo, max_ammo)
	else:
		display_infinite_ammo()

func _on_Recruit_player_health_updated(hp, max_hp):
	$HpBar/HpProgress.value = hp
	display_hp_number(hp, max_hp)
	if hp < $HpBar/HpLost.value:
		$AnimationPlayer.play("Flash")
		$AudioStreamPlayer.stream = _hurt
		$AudioStreamPlayer.play()
	#elif hp > $HpBar/HpLost.value:
		#$AudioStreamPlayer.stream = _heal
		#$AudioStreamPlayer.play()
	$HpBar/LostTween.interpolate_property($HpBar/HpLost, "value", $HpBar/HpLost.value, hp, 0.4, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.4)
	$HpBar/LostTween.start()
	
func _on_Recruit_player_max_health_updated(max_hp):
	$HpBar/HpProgress.max_value = max_hp
	$HpBar/HpLost.max_value = max_hp


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

func _on_Recruit_player_experience_updated(total_xp, level, max_level, xp, max_xp):
	modulate = Color(1, 1, 1) #Flash animation from stopping on a transparent frame
	display_money_number(total_xp)
	$XpBar/Num.frame_coords.x = level
	$XpBar/XpProgress.value = xp
	$XpBar/XpProgress.max_value = max_xp
	
	$AnimationPlayer.play("XpFlash")
	
	if xp == max_xp and level == max_level:
		$XpBar/XpProgress.visible = false
		$XpBar/XpMax.visible = true
	else:
		$XpBar/XpProgress.visible = true
		$XpBar/XpMax.visible = false


func _on_weapon_updated(icon_texture, level, xp, max_xp):
	$Weapon/HBoxContainer/Sprite.texture = icon_texture
	$Weapon/HBoxContainer/Sprite/Shadow.texture = icon_texture
	$XpBar/Num.frame_coords.x = level
	$XpBar/XpProgress.value = xp
	$XpBar/XpProgress.max_value = max_xp

func _on_ammo_updated(needs_ammo, ammo, max_ammo):
	if needs_ammo:
		display_ammo_number(ammo, max_ammo)
	else:
		display_infinite_ammo()

func display_ammo_number(ammo, max_ammo):
	var ammo_count = $Weapon/HboxContainer/AmmoCount
	var num1 = ammo_count.get_node("Num1")
	var num2 = ammo_count.get_node("Num2")
	var num3 = ammo_count.get_node("Num3")
	var num4 = ammo_count.get_node("Num4")
	var num5 = ammo_count.get_node("Num5")
	var num6 = ammo_count.get_node("Num6")
	
	ammo_count.visible = true
	if ammo >= 0 and ammo < 10:
		num1.visible = false
		num2.visible = false
		num3.visible = true
		num3.frame_coords.x = ammo
	elif ammo >= 10 and ammo < 100:
		num1.visible = false
		num2.visible = true
		num3.visible = true
		num2.frame_coords.x = (ammo % 100) / 10
		num3.frame_coords.x = ammo % 10
	elif ammo >= 100 and ammo < 1000:
		num1.visible = true
		num2.visible = true
		num3.visible = true
		num1.frame_coords.x = (ammo % 1000) / 100
		num2.frame_coords.x = (ammo % 100) / 10
		num3.frame_coords.x = ammo % 10
	elif ammo >= 1000:
		num1.visible = true
		num2.visible = true
		num3.visible = true
		num1.frame_coords.x = 9
		num2.frame_coords.x = 9
		num3.frame_coords.x = 9
	else:
		printerr("ERROR: hud cannot display current ammo number with value: ", ammo)

	if max_ammo >= 0 and max_ammo < 10:
		num4.visible = true
		num5.visible = false
		num6.visible = false
		num4.frame_coords.x = max_ammo
	elif max_ammo >= 10 and max_ammo < 100:
		num4.visible = true
		num5.visible = true
		num6.visible = false
		num4.frame_coords.x = (max_ammo % 100) / 10
		num5.frame_coords.x = max_ammo % 10
	elif max_ammo >= 100 and max_ammo < 1000:
		num4.visible = true
		num5.visible = true
		num6.visible = true
		num4.frame_coords.x = (max_ammo % 1000) / 100
		num5.frame_coords.x = (max_ammo % 100) / 10
		num6.frame_coords.x = max_ammo % 10
	elif max_ammo >= 1000:
		num4.visible = true
		num5.visible = true
		num6.visible = true
		num4.frame_coords.x = 9
		num5.frame_coords.x = 9
		num6.frame_coords.x = 9
	else:
		printerr("ERROR: hud cannot display max ammo number with value: ", max_ammo)

func display_infinite_ammo():
	$Weapon/HBoxContainer/AmmoCount.visible = false


func _on_Recruit_cooldown_updated(time):
	pass # Replace with function body.


func display_money_number(total_xp):
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
	else:
		printerr("ERROR: hud cannot display money number")


func _on_boss_setup_ui(display_name, hp, max_hp):
	$Boss/HpProgress.value = hp
	$Boss/HpProgress.max_value = max_hp
	$Boss/HpLost.value = hp
	$Boss/HpLost.max_value = max_hp
	$Boss/BossName.text = display_name

func _on_boss_health_updated(hp):
	$Boss/HpProgress.value = hp
	#if hp < $Boss/HpLost.value:
		#$AnimationPlayer.play("Flash")
		#$AudioStreamPlayer.stream = _hurt
		#$AudioStreamPlayer.play()
	#elif hp > $HpBar/HpLost.value:
		#$AudioStreamPlayer.stream = _heal
		#$AudioStreamPlayer.play()
	$Boss/LostTween.stop_all()
	$Boss/LostTween.interpolate_property($Boss/HpLost, "value", $Boss/HpLost.value, hp, 0.4, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.4)
	$Boss/LostTween.start()
	
	
	
func _on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale
