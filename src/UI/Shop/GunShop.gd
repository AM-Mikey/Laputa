extends MarginContainer

const GOT_GUN = preload("res://src/UI/GotGun.tscn")

var is_swapping_guns
var gun_index_to_swap
var blueprint_resource_array = []

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	_setup_blueprints()
	_setup_guns()
	%BlueprintsTabButton.grab_focus()
	f.db().busy = true

func _setup_blueprints():
	%BlueprintBox.clear()
	blueprint_resource_array = []
	for i in f.pc().item_array:
		if i.type == "blueprint":
			blueprint_resource_array.append(i)
			%BlueprintBox.add_icon_item(i.texture, true)

func _setup_guns():
	%UpgradeGunBox.clear()
	%RebuildGunBox.clear()
	for g in f.pc().get_node("GunManager/Guns").get_children():
		var icon = load("res://assets/UI/GunIcon/%s.png" % g.name)
		%UpgradeGunBox.add_icon_item(icon, true)
		%RebuildGunBox.add_icon_item(icon, true)




func _input(event: InputEvent):
	#if event.is_action_pressed("ui_accept") && %GunBox.has_focus() && %GunBox.get_selected_items().size() != 0:
		#if !is_swapping_guns:
			#is_swapping_guns = true
			#gun_index_to_swap = %GunBox.get_selected_items()[0]
			#am.play("ui_move")
		#elif is_swapping_guns:
			#is_swapping_guns = false
			#var current_index = %GunBox.get_selected_items()[0]
			#var guns = f.pc().get_node("GunManager/Guns")
			#var child1 = guns.get_child(gun_index_to_swap)
			#var child2 = guns.get_child(current_index)
			#guns.move_child(child1, current_index)
			#guns.move_child(child2, gun_index_to_swap)
			#var gun_manager = f.pc().get_node("GunManager")
			#var temp = gun_manager.gun_order[gun_index_to_swap]
			#gun_manager.gun_order[gun_index_to_swap] = gun_manager.gun_order[current_index]
			#gun_manager.gun_order[current_index] = temp
#
#
			#f.pc().emit_signal("guns_updated", guns.get_children())
			#am.play("ui_accept")
			#_setup_guns()
			#gun_manager.set_guns_visible()
			#%GunBox.select(current_index)
	if event.is_action_pressed("gun_left"):
		var tab_index: int = posmod(%TabContainer.current_tab - 1, %TabContainer.get_tab_count())
		match tab_index: #sets current tab upon grabbing focus
			0: %BlueprintsTabButton.grab_focus()
			1: %UpgradeTabButton.grab_focus()
			2: %RebuildTabButton.grab_focus()

	if event.is_action_pressed("gun_right"):
		var tab_index: int = posmod(%TabContainer.current_tab + 1, %TabContainer.get_tab_count())
		match tab_index: #sets current tab upon grabbing focus
			0: %BlueprintsTabButton.grab_focus()
			1: %UpgradeTabButton.grab_focus()
			2: %RebuildTabButton.grab_focus()

	if event.is_action_pressed("ui_accept") && %BlueprintBox.has_focus() && %BlueprintBox.get_selected_items().size() != 0:
		%BuildButton.grab_focus()
		get_viewport().set_input_as_handled()
		#var index = %BlueprintBox.get_selected_items()[0]
		#var blueprint = blueprint_resource_array[index]
		#shop.process_blueprint(blueprint)



func _on_Blueprints_item_selected(index: int):
	print("selected index %s" % index)
	var blueprint = blueprint_resource_array[index]
	shop.hint_blueprint(blueprint)



func _on_BuildButton_pressed():
	var index = %BlueprintBox.get_selected_items()[0]
	var blueprint = blueprint_resource_array[index]
	var gun = load("res://src/Gun/%s.tscn" % blueprint.id).instantiate()
	var player = f.pc()

	var already_has_gun = false
	for g in player.guns.get_children():
		if g.name == gun.name:
			already_has_gun = true
	if !already_has_gun:
		player.get_node("GunManager/Guns").add_child(gun)
		player.get_node("GunManager/Guns").move_child(gun, 0)
		player.emit_signal("guns_updated", player.guns.get_children(), "get_gun")
		player.gm.set_guns_visible()
		player.item_array.erase(blueprint)
		_setup_guns()
		_setup_blueprints()

		am.play_interrupt("get_item")
		var got_gun = GOT_GUN.instantiate()
		got_gun.gun_name = gun.display_name
		w.ui.add_child(got_gun)

		shop.build_blueprint()
		%BlueprintBox.grab_focus()
		print("added gun '", gun.name, "' to guns")
	else:
		print("WARNING: Gun: ", gun.name, " already in guns, ignoring")



func _on_BlueprintsTabButton_focus_entered():
	%TabContainer.current_tab = 0
	shop.hint_tab("blueprints")

func _on_UpgradeTabButton_focus_entered():
	%TabContainer.current_tab = 1
	shop.hint_tab("upgrade")

func _on_RebuildTabButton_focus_entered():
	%TabContainer.current_tab = 2
	shop.hint_tab("rebuild")

func _on_ExitButton_pressed():
	f.db().busy = false
	shop.hint_tab("exit")
	queue_free()
