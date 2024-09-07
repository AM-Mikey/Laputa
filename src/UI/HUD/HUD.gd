extends Control

const GUNICON = preload("res://src/UI/HUD/GunIcon.tscn")

#onready var pc = get_tree().get_root().get_node("World/Juniper")
@onready var world = get_tree().get_root().get_node("World")

@export var gun: Node
@export var ao: Node
@export var hp_node: Node
@export var xp_node: Node
@export var cd: Node
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

@onready var mon_1 = mon.get_node("Num1")
@onready var mon_2 = mon.get_node("Num2")
@onready var mon_3 = mon.get_node("Num3")

func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()
	
	if world.has_node("Juniper"):
		var pc = world.get_node("Juniper")
		pc.connect("hp_updated", Callable(self, "update_hp"))
		pc.connect("guns_updated", Callable(self, "update_guns"))
		pc.connect("xp_updated", Callable(self, "update_xp"))
		pc.connect("money_updated", Callable(self, "update_money"))
		pc.setup_hud()
		setup_lost_bars(pc.hp, pc.guns.get_child(0).xp)

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

func update_guns(guns):
	var hbox = gun.get_node("HBox")
	var main_icon = gun.get_node("GunIcon")
	for i in hbox.get_children():
		i.queue_free()
	for g in guns:
		if guns.find(g) == 0: #main gun
			main_icon.texture = g["icon_texture"]
			update_xp(g.xp, g.max_xp, g.level, g.max_level)
			update_ammo(g.ammo, g.max_ammo)
		else: 
			var gun_icon = GUNICON.instantiate() #all other
			gun_icon.texture = g["texture"]
			hbox.add_child(gun_icon)

func update_hp(hp, max_hp):
	hp_progress.value = hp
	display_hp_number(hp, max_hp)
	hp_progress.max_value = max_hp
	hp_lost.max_value = max_hp
	set_cap_pos(hp_progress, 38, hp_progress_cap)
	
	
	if hp < hp_lost.value:
		$AnimationPlayer.play("Flash")
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

func update_xp(xp, max_xp, level, max_level):
	modulate = Color(1, 1, 1) #to prevent flash animation from stopping on a transparent frame
	xp_num.frame_coords.x = level
#	if flash:
#		$AnimationPlayer.play("XpFlash")
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


func update_ammo(have, maximum):
		ao.ammo = have
		ao.max_ammo = maximum
		ao.display_ammo()


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

### HELPER ###

func set_cap_pos(bar, length, cap):
	cap.position.x = length * bar.value / bar.max_value
	cap.visible = false if bar.value == 0 else true

func setup_lost_bars(hp, xp): #needs to be done so that update can tell that it's decreased
	hp_lost.value = hp
	#set_cap_pos(hp_lost, 38, hp_lost_cap) #already on _process()
	xp_lost.value = xp
	#set_cap_pos(xp_lost, 38, xp_lost_cap)

func on_viewport_size_changed():
	size = get_tree().get_root().size / world.resolution_scale
