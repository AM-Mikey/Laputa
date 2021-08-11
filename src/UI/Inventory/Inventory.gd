extends Control

onready var player = get_tree().get_root().get_node("World/Recruit")
onready var hud = get_parent().get_node("HUD")
onready var items = $MarginContainer/VBoxContainer/Items/ItemList
onready var weapon_wheel = $MarginContainer/VBoxContainer/Weapons/MarginContainer/WeaponWheel

onready var header = $MarginContainer/VBoxContainer/Description/MarginContainer/VBoxContainer/Header
onready var body = $MarginContainer/VBoxContainer/Description/MarginContainer/VBoxContainer/Body

var player_inventory: Array

onready var world = get_tree().get_root().get_node("World")

func _ready():
		get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
		_on_viewport_size_changed()

func _process(delta):
	yield(get_tree(), "idle_frame")
	if Input.is_action_just_pressed("inventory"):
		get_tree().paused = false
		hud.visible = true
		player.get_node("WeaponManager").update_weapon()
		queue_free()


func _on_inventory_updated(inventory):
	if not inventory.empty():
		player_inventory = inventory
		var item_name = player_inventory[-1]
		var item_path = "res://src/Item/KeyItem/%s" % item_name + ".tres"
		var item = load(item_path)
		items.add_icon_item(item.texture)
		#body.text = item.description


func _on_Items_item_activated(index):
		var item_name = player_inventory[index] 
		var item_path = "res://src/Item/KeyItem/%s" % item_name + ".tres"
		var item = load(item_path)
		body.text = item.description

func _on_viewport_size_changed():
	var viewport_size = get_tree().get_root().size / world.resolution_scale
	
#	if viewport_size.x <= viewport_size.y:
#		rect_size = Vector2(viewport_size.x, viewport_size.x)
#		#rect_position = viewport_size/2
#	else:
#		rect_size = Vector2(viewport_size.y, viewport_size.y)
#		#rect_position = viewport_size/2
	
	rect_size = get_tree().get_root().size / world.resolution_scale
