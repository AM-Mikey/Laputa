extends MarginContainer

const GOT_GUN = preload("res://src/UI/GotGun.tscn")

var is_swapping_guns
var gun_index_to_swap
var blueprint_resource_array = []
var selected_price: int = 0

var alignment: String

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	_align_box()
	_setup_blueprints()
	_setup_upgrade_guns()
	_setup_rebuild_guns()
	_update_money()
	%BlueprintsTabButton.grab_focus()
	f.db().busy = true

func _align_box(): #TODO: left/right alignment
	var db = f.db()
	if db.alignment == "top":
		alignment = "bottom"
		$MarginContainer.size_flags_vertical = SIZE_SHRINK_END
	elif db.alignment == "bottom":
		alignment = "top"
		$MarginContainer.size_flags_vertical = SIZE_SHRINK_BEGIN

func _setup_blueprints():
	%BlueprintBox.clear()
	blueprint_resource_array = []
	for i in f.pc().item_array:
		if i.type == "blueprint":
			blueprint_resource_array.append(i)
			%BlueprintBox.add_icon_item(i.texture, true)

func _setup_upgrade_guns():
	%UpgradeGunBox.clear()
	for g in f.pc().get_node("GunManager/Guns").get_children():
		var icon = load("res://assets/UI/GunIcon/%s.png" % g.name)
		%UpgradeGunBox.add_icon_item(icon, true)
		var can_upgrade = false
		var current_shop_level_upgrades = shop.upgrades_per_shop_level[shop.shop_level]
		for u in current_shop_level_upgrades:
			if g.name.capitalize() in u && g.max_unlocked_level < u[1]: #current_shop_level_upgrades gun upgrade level
				can_upgrade = true
		if !can_upgrade:
			%UpgradeGunBox.set_item_icon_modulate(g.get_index(), Color(0.0, 0.0, 0.0, 0.5))

func _setup_rebuild_guns():
	%RebuildGunBox.clear()
	for g in f.pc().get_node("GunManager/Guns").get_children():
		var icon = load("res://assets/UI/GunIcon/%s.png" % g.name)
		var can_rebuild = true if g.lifetime_xp >= g.xp_to_rebuild else false
		%RebuildGunBox.add_icon_item(icon, true)
		if !can_rebuild:
			%RebuildGunBox.set_item_icon_modulate(g.get_index(), Color(0.0, 0.0, 0.0, 0.5))

func _update_money():
	var player = f.pc()
	%MoneyLabel.text = str("$", player.money)
	player.emit_signal("money_updated", player.money)


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

	if event.is_action_pressed("ui_accept") && %UpgradeGunBox.has_focus() && %UpgradeGunBox.get_selected_items().size() != 0:
		%UpgradeButton.grab_focus()
		get_viewport().set_input_as_handled()



func _on_Blueprints_item_selected(index: int):
	#print("selected index %s" % index)
	var blueprint = blueprint_resource_array[index]
	shop.gun_hint_blueprint(blueprint)
	if !shop.blueprint_prices.has(blueprint.id):
		%BlueprintsPriceLabel.text = ""
		return #no price
	%BlueprintsPriceLabel.text = str("$", shop.blueprint_prices[blueprint.id])
	selected_price = shop.blueprint_prices[blueprint.id]

func _on_UpgradeGunBox_item_selected(index: int):
	var player = f.pc()
	var gun_resource_name: String = player.get_node("GunManager/Guns").get_child(index).name
	var gun_in_player = player.get_node("GunManager/Guns").get_node(gun_resource_name)
	var price: int = -1
	for i in shop.upgrades_per_shop_level[shop.shop_level]:
		if gun_in_player.name.capitalize() in i && gun_in_player.max_unlocked_level < i[1]: #current_shop_level_upgrades gun upgrade level
			price = i[2]
	if price == -1:
		%UpgradePriceLabel.text = ""
		return #no price
	%UpgradePriceLabel.text = str("$", price)
	selected_price = price

func _on_RebuildGunBox_item_selected(index: int):
	var player = f.pc()
	var gun_resource_name: String = player.get_node("GunManager/Guns").get_child(index).name
	var gun_in_player = player.get_node("GunManager/Guns").get_node(gun_resource_name)
	if !shop.rebuild_prices.has(gun_in_player.name.capitalize()):
		%RebuildPriceLabel.text = ""
		return #no price
	var price = shop.rebuild_prices[gun_in_player.name.capitalize()]
	%RebuildPriceLabel.text = str("$", price)
	selected_price = price



func _on_BuildButton_pressed():
	var player = f.pc()
	if %BlueprintBox.get_selected_items().size() == 0:
		am.play("ui_deny")
		return
	var index = %BlueprintBox.get_selected_items()[0]
	var blueprint = blueprint_resource_array[index]
	var gun = load("res://src/Gun/%s.tscn" % blueprint.id).instantiate()

	if !player.money >= selected_price:
		am.play("ui_deny")
		shop.gun_deny_price()
		return
	player.money -= selected_price

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
		_setup_upgrade_guns()
		_setup_rebuild_guns()
		_setup_blueprints()
		_update_money()
		%BlueprintsPriceLabel.text = ""

		am.play_interrupt("get_item")
		var got_gun = GOT_GUN.instantiate()
		got_gun.gun_name = gun.display_name
		w.ui.add_child(got_gun)

		shop.gun_build_blueprint()
		%BlueprintBox.grab_focus()
		print("added gun '", gun.name, "' to guns")
	else:
		print("WARNING: Gun: ", gun.name, " already in guns, ignoring")


func _on_UpgradeButton_pressed():
	var player = f.pc()
	if %UpgradeGunBox.get_selected_items().size() == 0:
		am.play("ui_deny")
		return
	var index = %UpgradeGunBox.get_selected_items()[0]
	var gun_resource_name: String = player.get_node("GunManager/Guns").get_child(index).name
	var gun_in_player = player.get_node("GunManager/Guns").get_node(gun_resource_name)
	var can_upgrade = false
	var current_shop_level_upgrades = shop.upgrades_per_shop_level[shop.shop_level]
	for u in current_shop_level_upgrades:
		if gun_in_player.name.capitalize() in u && gun_in_player.max_unlocked_level < u[1]: #current_shop_level_upgrades gun upgrade level
			can_upgrade = true
	if !can_upgrade:
		am.play("ui_deny")
		return
	if !player.money >= selected_price:
		am.play("ui_deny")
		shop.gun_deny_price()
		return
	player.money -= selected_price
	gun_in_player.max_unlocked_level += 1 #TODO: upgrade more than one level at a time later?
	am.play_interrupt("get_item") #TODO: play a smaller jingle
	player.emit_signal("guns_updated", player.guns.get_children())
	_setup_upgrade_guns()
	_setup_rebuild_guns()
	_setup_blueprints()
	_update_money()
	%UpgradePriceLabel.text = ""


func _on_RebuildButton_pressed():
	var player = f.pc()
	if %RebuildGunBox.get_selected_items().size() == 0:
		am.play("ui_deny")
		return
	var index = %RebuildGunBox.get_selected_items()[0]
	var gun_resource_name: String = player.get_node("GunManager/Guns").get_child(index).name
	var old_gun_in_player = player.get_node("GunManager/Guns").get_node(gun_resource_name)
	var can_rebuild = true if old_gun_in_player.lifetime_xp >= old_gun_in_player.xp_to_rebuild else false
	if !can_rebuild:
		am.play("ui_deny")
		return
	if !player.money >= selected_price:
		am.play("ui_deny")
		shop.gun_deny_price()
		return
	player.money -= selected_price
	var mark_designation = str("M", old_gun_in_player.rebuild_count + 2)
	var gun = load("res://src/Gun/%s%s.tscn" % [gun_resource_name, mark_designation]).instantiate()
	if gun == null:
		printerr("ERROR: Can't find gun at: res://src/Gun/%s%s.tscn" % [gun_resource_name, mark_designation])

	var already_has_gun = false
	for g in player.guns.get_children():
		if g.name == gun.name:
			already_has_gun = true
	if !already_has_gun:
		player.get_node("GunManager/Guns").add_child(gun)
		player.get_node("GunManager/Guns").move_child(gun, 0)
		old_gun_in_player.free()
		var index_in_gun_order = player.get_node("GunManager").gun_order.find(old_gun_in_player)
		player.get_node("GunManager").gun_order[index_in_gun_order] = gun #replace old with new
		player.emit_signal("guns_updated", player.guns.get_children(), "get_gun")
		player.gm.set_guns_visible()
		_setup_upgrade_guns()
		_setup_rebuild_guns()
		_setup_blueprints()
		_update_money()
		%RebuildPriceLabel.text = ""

		am.play_interrupt("get_item")
		var got_gun = GOT_GUN.instantiate()
		got_gun.gun_name = gun.display_name
		w.ui.add_child(got_gun)

		shop.gun_build_blueprint()
		%BlueprintBox.grab_focus()
		print("added gun '", gun.name, "' to guns")
	else:
		print("WARNING: Gun: ", gun.name, " already in guns, ignoring")



func _on_BlueprintsTabButton_focus_entered():
	%TabContainer.current_tab = 0
	shop.gun_hint_tab("blueprints")

func _on_UpgradeTabButton_focus_entered():
	%TabContainer.current_tab = 1
	shop.gun_hint_tab("upgrade")

func _on_RebuildTabButton_focus_entered():
	%TabContainer.current_tab = 2
	shop.gun_hint_tab("rebuild")

func _on_ExitButton_pressed():
	f.db().busy = false
	shop.gun_hint_tab("exit")
	queue_free()

func _resolution_scale_changed(_resolution_scale):
	set_deferred("size", get_tree().get_root().size / vs.menu_resolution_scale)
