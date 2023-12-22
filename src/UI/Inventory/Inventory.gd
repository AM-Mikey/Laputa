extends Control

var player_inventory: Array
var disabled = true

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_tree().get_root().get_node("World/Juniper")
@onready var hud = get_parent().get_node("HUD")
@onready var items = $MarginContainer/VBoxContainer/Items/ItemList
@onready var weapon_wheel = $MarginContainer/VBoxContainer/Weapons/MarginContainer/WeaponWheel
@onready var header = $MarginContainer/VBoxContainer/Description/MarginContainer/VBoxContainer/Header
@onready var body = $MarginContainer/VBoxContainer/Description/MarginContainer/VBoxContainer/Body


func _ready():
		var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
		on_viewport_size_changed()
		enter()

func _input(event):
	if event.is_action_pressed("inventory") and not disabled:
		exit()

func enter():
	get_tree().paused = true
	hud.visible = false
	await get_tree().process_frame
	disabled = false

func exit():
	get_tree().paused = false
	hud.visible = true
	pc.emit_signal("guns_updated", pc.guns.get_children())
	queue_free()


### SIGNALS

func _on_inventory_updated(inventory):
	if not inventory.is_empty():
		player_inventory = inventory
		var item_name = player_inventory[-1]
		var item_path = "res://src/Item/%s" % item_name + ".tres"
		var item = load(item_path)
		items.add_icon_item(item.texture)
		#body.text = item.description


func _on_Items_item_activated(index):
		var item_name = player_inventory[index] 
		var item_path = "res://src/Item/%s" % item_name + ".tres"
		var item = load(item_path)
		body.text = item.description

func on_viewport_size_changed():
	var viewport_size = get_tree().get_root().size / world.resolution_scale
	var target_width = 400
	
	if target_width > viewport_size.x:
		size.x = viewport_size.x
	else:
		size.x = target_width
		position.x = (viewport_size.x - target_width) /2
	size.y = viewport_size.y
