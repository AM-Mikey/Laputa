extends Control

@onready var w = get_tree().get_root().get_node("World")
@onready var items = %Items
@onready var weapon_wheel = %WeaponWheel
@onready var header = %Header
@onready var body = %Body


func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	enter()

func _input(event):
	if event.is_action_pressed("inventory") and f.pc().can_input:
		exit()


func display_items():
	var pc = f.pc()
	for i in pc.item_array:
		print("s")
		var texture = i.texture
		%ItemList.add_icon_item(texture)


func display_topics():
	var pc = f.pc()
	for t in pc.topic_array:
		%TopicList.add_item(t)

func enter():
	get_tree().paused = true
	w.hl.visible = false
	w.ui.visible = false
	display_items()
	display_topics()

func exit():
	get_tree().paused = false
	w.hl.visible = true
	w.ui.visible = true
	var pc = f.pc()
	pc.emit_signal("guns_updated", pc.guns.get_children())
	queue_free()



### SIGNALS

#func _on_inventory_updated(inventory):
	#pass
	#if not inventory.is_empty():
		#player_inventory = inventory
		#var item_name = player_inventory[-1]
		#var item_path = "res://src/Item/%s" % item_name + ".tres"
		#var item = load(item_path)
		#items.add_icon_item(item.texture)
		#body.text = item.description


#func _on_Items_item_activated(index):
	#pass
		#var item_name = player_inventory[index]
		#var item_path = "res://src/Item/%s" % item_name + ".tres"
		#var item = load(item_path)
		#body.text = item.description



### SIGNALS ###


func _on_tab_toggled(toggled_on: bool, tab: String):
	if !toggled_on:
		match tab:
			"inventory":
				%InventoryButton.set_pressed_no_signal(true)
			"mission":
				%MissionButton.set_pressed_no_signal(true)
			"map":
				%MapButton.set_pressed_no_signal(true)
	else:
		match tab:
			"inventory":
				%MissionButton.set_pressed_no_signal(false)
				%MapButton.set_pressed_no_signal(false)
				%Inventory.visible = true
				%Mission.visible = false
				%Map.visible = false
			"mission":
				%InventoryButton.set_pressed_no_signal(false)
				%MapButton.set_pressed_no_signal(false)
				%Inventory.visible = false
				%Mission.visible = true
				%Map.visible = false
			"map":
				%InventoryButton.set_pressed_no_signal(false)
				%MissionButton.set_pressed_no_signal(false)
				%Inventory.visible = false
				%Mission.visible = false
				%Map.visible = true


func _on_ItemList_item_selected(index: int):
	var pc = f.pc()
	%InventoryHeader.text = pc.item_array[index].item_name
	%InventoryBody.text = pc.item_array[index].description


func _resolution_scale_changed(_resolution_scale):
	var inventory_size = get_tree().get_root().size / vs.inventory_resolution_scale
	set_deferred("size", inventory_size)

	var polygon_points = [
		Vector2(0,0),
		Vector2(inventory_size.x, 0),
		inventory_size,
		Vector2(0, inventory_size.y),
		]
	$Blur.polygon = PackedVector2Array(polygon_points)
