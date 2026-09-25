extends MarginContainer

var is_swapping_guns
var gun_index_to_swap
var blueprint_resource_array = []

func _ready():
	_setup_blueprints()
	_setup_guns()
	%GunBox.grab_focus()
	f.db().busy = true

func _setup_blueprints():
	for i in f.pc().item_array:
		if i.type == "blueprint":
			blueprint_resource_array.append(i)
			%Blueprints.add_icon_item(i.texture, true)

func _setup_guns():
	%GunBox.clear()
	for g in f.pc().get_node("GunManager/Guns").get_children():
		var icon = load("res://assets/UI/GunIcon/%s.png" % g.name)
		%GunBox.add_icon_item(icon, true)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept") && %GunBox.has_focus() && %GunBox.get_selected_items().size() != 0:
		if !is_swapping_guns:
			is_swapping_guns = true
			gun_index_to_swap = %GunBox.get_selected_items()[0]
			am.play("ui_move")
		elif is_swapping_guns:
			is_swapping_guns = false
			var current_index = %GunBox.get_selected_items()[0]
			var guns = f.pc().get_node("GunManager/Guns")
			var child1 = guns.get_child(gun_index_to_swap)
			var child2 = guns.get_child(current_index)
			guns.move_child(child1, current_index)
			guns.move_child(child2, gun_index_to_swap)
			var gun_manager = f.pc().get_node("GunManager")
			var temp = gun_manager.gun_order[gun_index_to_swap]
			gun_manager.gun_order[gun_index_to_swap] = gun_manager.gun_order[current_index]
			gun_manager.gun_order[current_index] = temp


			f.pc().emit_signal("guns_updated", guns.get_children())
			am.play("ui_accept")
			_setup_guns()
			gun_manager.set_guns_visible()
			%GunBox.select(current_index)
	if event.is_action_pressed("ui_accept") && %Blueprints.has_focus() && %Blueprints.get_selected_items().size() != 0:
		var index = %Blueprints.get_selected_items()[0]
		var blueprint = blueprint_resource_array[index]
		shop.process_blueprint(blueprint)


#func _on_Blueprints_pressed():
	#%TabContainer.current_tab = 0
	#shop.hint_tab("blueprints")
#
#
#func _on_Upgrade_pressed():
	#shop.hint_tab("upgrade")
#
#
#func _on_Fusion_pressed():
	#shop.hint_tab("fusion")
#
#
#func _on_Rebuild_pressed():
	#shop.hint_tab("rebuild")

func _on_Exit_pressed():
	shop.hint_tab("exit")
	f.db().busy = false
	queue_free()


func _on_Blueprints_item_selected(index: int):
	print("selected index %s" % index)
	var blueprint = blueprint_resource_array[index]
	shop.hint_blueprint(blueprint)


func _on_Blueprints_focus_entered():
	%TabContainer.current_tab = 0
	shop.hint_tab("blueprints")


func _on_Upgrade_focus_entered():
	shop.hint_tab("upgrade")


func _on_Fusion_focus_entered():
	shop.hint_tab("fusion")


func _on_Rebuild_focus_entered():
	shop.hint_tab("rebuild")
