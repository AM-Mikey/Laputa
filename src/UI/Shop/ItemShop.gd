extends MarginContainer

const GOT_ITEM = preload("res://src/UI/GotItem.tscn")

var item_resource_array = []
var in_stock_items_on_current_shop_level = []
var selected_price: int = 0

var alignment: String

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	_align_box()
	_setup_items()
	_update_money()
	%ItemBox.grab_focus()
	f.db().busy = true

func _align_box(): #TODO: left/right alignment
	var db = f.db()
	if db.alignment == "top":
		alignment = "bottom"
		$MarginContainer.size_flags_vertical = SIZE_SHRINK_END
	elif db.alignment == "bottom":
		alignment = "top"
		$MarginContainer.size_flags_vertical = SIZE_SHRINK_BEGIN

func _update_money():
	var player = f.pc()
	%MoneyLabel.text = str("$", player.money)
	player.emit_signal("money_updated", player.money)

func _setup_items():
	var player = f.pc()
	%ItemBox.clear()
	item_resource_array = []
	in_stock_items_on_current_shop_level = []
	for i in shop.items_per_shop_level[shop.shop_level]:
		if i[2]: #in_stock
			in_stock_items_on_current_shop_level.append(i)

	for j in in_stock_items_on_current_shop_level:
		var item_resource = load("res://src/Item/%s.tres" %j[0].capitalize())
		item_resource_array.append(item_resource)
		var can_buy = true
		if player.item_array.has(item_resource) && item_resource.stackable == false:
			can_buy = false

		%ItemBox.add_icon_item(item_resource.texture, true)
		if !can_buy:
			var index = in_stock_items_on_current_shop_level.find(j)
			%ItemBox.set_item_icon_modulate(index, Color(0.0, 0.0, 0.0, 0.5))


func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept") && %ItemBox.has_focus() && %ItemBox.get_selected_items().size() != 0:
		%BuyButton.grab_focus()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_accept") && %ItemBox.has_focus() && %ItemBox.get_selected_items().size() != 0:
		%BuyButton.grab_focus()
		get_viewport().set_input_as_handled()



### SIGNALS ###

func _on_ItemBox_item_selected(index: int):
	shop.item_hint(item_resource_array[index].id)
	var price: int = -1
	if item_resource_array[index].price != null:
		price = item_resource_array[index].price
	else:
		price = 0
	%PriceLabel.text = str("$", price)
	selected_price = price

func _on_BuyButton_pressed():
	var player = f.pc()
	if %ItemBox.get_selected_items().size() == 0:
		am.play("ui_deny")
		return
	var index = %ItemBox.get_selected_items()[0]
	if player.item_array.has(item_resource_array[index]) && item_resource_array[index].stackable == false: #we have it
		am.play("ui_deny")
		shop.item_deny_duplicate()
		return
	if !player.money >= selected_price:
		am.play("ui_deny")
		shop.item_deny_price()
		return
	player.money -= selected_price
	_update_money()
	player.item_array.append(item_resource_array[index])
	#remove from stock if not rebuyable
	var rebuyable = in_stock_items_on_current_shop_level[index][1]
	if !rebuyable:
		var index_in_shop_version = shop.items_per_shop_level[shop.shop_level].find(in_stock_items_on_current_shop_level[index])#[2] = false #in_stock = false
		shop.items_per_shop_level[shop.shop_level][index_in_shop_version][2] = false
	#TODO: save the shop's items_per_shop_level on temp/save file
	_setup_items()
	%PriceLabel.text = ""
	am.play_interrupt("get_item")
	var got_item = GOT_ITEM.instantiate()
	got_item.item_name = item_resource_array[index].display_name
	w.ui.add_child(got_item)
	shop.item_buy_button()


func _on_ExitButton_pressed() -> void:
	f.db().busy = false
	shop.item_hint_tab("exit")
	queue_free()

func _resolution_scale_changed(_resolution_scale):
	set_deferred("size", get_tree().get_root().size / vs.menu_resolution_scale)
