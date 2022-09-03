extends Control

const GUNICON = preload("res://src/UI/HUD/GunIcon.tscn")
const AMMOCOUNT = preload("res://src/UI/HUD/AmmoCount.tscn")


#onready var p = get_tree().get_root().get_node("World/Juniper")
onready var world = get_tree().get_root().get_node("World")

export(NodePath) onready var ammo_path
export(NodePath) onready var hp_path
export(NodePath) onready var xp_path
export(NodePath) onready var cooldown_path
export(NodePath) onready var money_path

onready var ao = get_node(ammo_path)
onready var ao_1 = ao.get_node("Num1")
onready var ao_2 = ao.get_node("Num2")
onready var ao_3 = ao.get_node("Num3")
onready var ao_4 = ao.get_node("Num4")
onready var ao_5 = ao.get_node("Num5")
onready var ao_6 = ao.get_node("Num6")

onready var hp = get_node(hp_path)
onready var hp_lost = hp.get_node("Lost")
onready var hp_lost_cap = hp_lost.get_node("Cap")
onready var hp_progress = hp.get_node("Progress")
onready var hp_progress_cap = hp_progress.get_node("Cap")
onready var hp_1 = hp.get_node("Num1")
onready var hp_2 = hp.get_node("Num2")

onready var xp = get_node(xp_path)
onready var xp_progress = xp.get_node("Progress")
onready var xp_flash = xp.get_node("Flash")
onready var xp_max = xp.get_node("Max")
onready var xp_num = xp.get_node("Num")

onready var cd = get_node(cooldown_path)
onready var cd_progress = cd.get_node("Progress")

onready var money = get_node(money_path)
onready var money_1 = money.get_node("Num1")
onready var money_2 = money.get_node("Num2")
onready var money_3 = money.get_node("Num2")

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
	hp_lost_cap.position.x = 38 * hp_lost.value / hp_lost.max_value
	
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



func update_ammo(have, maximum): #TODO FIX this instancing. ammo and max ammo are vars in the instance
	if ao:
			ao.free()
	if maximum != 0:
		var ao = AMMOCOUNT.instance()
		ao.ammo = have
		ao.max_ammo = maximum
		$Gun/HBox.add_child(ao)
		$Gun/HBox.move_child(ao, 1)


func update_money(money):
	money_1.visible = true
	money_2.visible = true
	money_3.visible = true
	
	if money >= 0 and money < 10:
		money_1.visible = false
		money_2.visible = false
		money_3.frame_coords.x = money
	elif money >= 10 and money < 100:
		money_1.visible = false
		money_2.frame_coords.x = (money % 100) / 10
		money_3.frame_coords.x = money % 10
	elif money >= 100 and money < 1000:
		money_1.frame_coords.x = (money % 1000) / 100
		money_2.frame_coords.x = (money % 100) / 10
		money_3.frame_coords.x = money % 10
	elif money >= 1000:
		money_1.frame_coords.x = 9
		money_2.frame_coords.x = 9
		money_3.frame_coords.x = 9
		print("WARNING: hud cannot display money higher than 999")
	else:
		printerr("ERROR: hud cannot display money value of: " + money)


func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale
