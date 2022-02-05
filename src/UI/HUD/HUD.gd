extends Control

const GUNICON = preload("res://src/UI/HUD/GunIcon.tscn")
const AMMOCOUNT = preload("res://src/UI/HUD/AmmoCount.tscn")


#onready var p = get_tree().get_root().get_node("World/Juniper")
onready var world = get_tree().get_root().get_node("World")

func _ready():
	var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()
	
	
	if world.has_node("Juniper"):
		var pc = world.get_node("Juniper")
		pc.connect("hp_updated", self, "update_hp")
		pc.connect("guns_updated", self, "update_guns")
		pc.connect("total_xp_updated", self, "update_total_xp")
		pc.setup_hud()
		

func _process(_delta):
	$HpBar/HpLost/HpLostCap.position.x = 38 * $HpBar/HpLost.value / $HpBar/HpLost.max_value
	if world.has_node("Juniper"):
		var pc = world.get_node("Juniper")
		if pc.guns.get_child(0) != null: #TODO: make this independant
			$CooldownBar/TextureProgress.visible = true
			$CooldownBar/TextureProgress.value = 100 - ((pc.get_node("GunManager/CooldownTimer").time_left / pc.guns.get_child(0).cooldown_time) * 100)
		else: $CooldownBar/TextureProgress.visible = false

func update_guns(guns):
	for i in $Gun/HBox.get_children(): #clear old
			i.queue_free()
	for g in guns:
		if guns.find(g) == 0: #check if front
			var gun_icon = GUNICON.instance() #add the first icon
			gun_icon.texture = g["icon_texture"]
			$Gun/HBox.add_child(gun_icon)
			$Gun/HBox.move_child(gun_icon, 0)
			
			update_xp(g.xp, g.max_xp, g.level, g.max_level)
			update_ammo(g.ammo, g.max_ammo)
		else: 
			var gun_icon = GUNICON.instance() #add all other icons
			gun_icon.texture = g["texture"]
			$Gun/HBox.add_child(gun_icon)

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



func update_ammo(ammo, max_ammo):
	if $Gun/HBox.has_node("AmmoCount"):
			$Gun/HBox/AmmoCount.free()
	if max_ammo != 0:
		var ammo_count = AMMOCOUNT.instance()
		ammo_count.ammo = ammo
		ammo_count.max_ammo = max_ammo
		$Gun/HBox.add_child(ammo_count)
		$Gun/HBox.move_child(ammo_count, 1)


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
