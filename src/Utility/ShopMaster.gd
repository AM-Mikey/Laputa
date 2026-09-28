extends Node


var current_shop_level: int = 0

var blueprint_wait_duration: float = 600 #10 minutes
var fusion_wait_duration: float = 600
var rebuild_wait_duration: float = 600

var wait_timer: Node


func hint_tab(tab_name):
	var tab_name_snake_case = tab_name.to_snake_case()
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "tab_hint_%s" % tab_name_snake_case)


func hint_blueprint(blueprint):
	print("asdddddddddddddddd")
	var gun_name_snake_case = blueprint.id.to_snake_case()
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "blueprint_hint_%s" % gun_name_snake_case)


func build_blueprint():
	var db = f.db()
	db.request_subprint("res://src/Dialog/ShopMaster.json", "build_button")
