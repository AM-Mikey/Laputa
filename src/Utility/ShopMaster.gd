extends Node


var shop_level: int = 0

var blueprint_wait_duration: float = 600 #10 minutes
var fusion_wait_duration: float = 600
var rebuild_wait_duration: float = 600

var wait_timer: Node

var blueprint_prices = {
	"Roberta": 200,
	"TurnstileJumper": 400,
}

var upgrades_per_shop_level = {
	0: [["Revolver", 3, 100], ["Red7", 2, 150]],
	1: [["Blunderbuss", 2, 200], ["GLauncher", 2, 400]],
}

var rebuild_prices = {
	"MPistol": 50,
}

#sage item shop
var items_per_shop_level = { #ID, rebuyable, in_stock
	0: [["Linen", false, true], ["Salmiakki", true, true]],
}

### GUN SHOP ###

func gun_hint_tab(tab_name):
	var tab_name_snake_case = tab_name.to_snake_case()
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "gun_tab_hint_%s" % tab_name_snake_case)

func gun_hint_blueprint(blueprint):
	var gun_name_snake_case = blueprint.id.to_snake_case()
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "gun_blueprint_hint_%s" % gun_name_snake_case)

func gun_build_blueprint():
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "gun_build_button")

func gun_deny_price():
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "gun_deny_price")

### ITEM SHOP ###

func item_hint_tab(tab_name):
	var tab_name_snake_case = tab_name.to_snake_case()
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "item_tab_hint_%s" % tab_name_snake_case)

func item_hint(item_name):
	var item_name_snake_case = item_name.to_snake_case()
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "item_hint_%s" % item_name_snake_case)

func item_buy_button():
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "item_buy_button")

func item_deny_price():
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "item_deny_price")

func item_deny_duplicate():
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "item_deny_duplicate")
