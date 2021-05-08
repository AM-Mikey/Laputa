extends Control

onready var player = get_tree().get_root().get_node("World/Recruit")
onready var hud = get_parent().get_node("HUD")
onready var items = $CenterContainer/Background/MarginContainer/VBoxContainer/Items
onready var description = $CenterContainer/Background/MarginContainer/VBoxContainer/Description/Label
onready var weapon_wheel = $CenterContainer/Background/MarginContainer/VBoxContainer/Panel/WeaponWheel

var player_inventory: Array

func _process(delta):
	if Input.is_action_just_pressed("inventory") and get_tree().paused == false:
		get_tree().paused = true
		print("game paused")
		hud.visible = false
		visible = true
		
		weapon_wheel.disabled = false
		weapon_wheel.setup() #set up whenever inventory is called
	
	elif Input.is_action_just_pressed("inventory") and get_tree().paused == true:
		get_tree().paused = false
		print("game unpaused")
		hud.visible = true
		visible = false
		
		
		player.get_node("WeaponManager").update_weapon()
		weapon_wheel.disabled = true
		


func _on_inventory_updated(inventory):
	if not inventory.empty():
		player_inventory = inventory
		var item_name = player_inventory[-1]
		var item_path = "res://src/Item/KeyItem/%s" % item_name + ".tres"
		var item = load(item_path)
		items.add_icon_item(item.texture)
		#description.text = item.description


func _on_Items_item_activated(index):
		var item_name = player_inventory[index] 
		var item_path = "res://src/Item/KeyItem/%s" % item_name + ".tres"
		var item = load(item_path)
		description.text = item.description
