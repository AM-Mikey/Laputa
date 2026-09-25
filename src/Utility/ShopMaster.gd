extends Node


var current_shop_level: int = 0

var blueprint_wait_duration: float = 600 #10 minutes
var fusion_wait_duration: float = 600
var rebuild_wait_duration: float = 600

var wait_timer: Node


func hint_tab(tab_name):
	var db = f.db()
	#db.busy = false
	db.do_force_end = true
	db.end_via_subprint = true
	db.subprint_json = "res://src/Dialog/ShopMaster.json"
	db.subprint_conversation = "tab_hint_%s" % tab_name
	db.setup_subprint_conversation()


func hint_blueprint(blueprint):
	var gun_name_snake_case = blueprint.id.to_snake_case()
	var db = f.db()
	#db.busy = false
	db.do_force_end = true
	db.end_via_subprint = true
	db.subprint_json = "res://src/Dialog/ShopMaster.json"
	db.subprint_conversation = "blueprint_hint_%s" % gun_name_snake_case
	db.setup_subprint_conversation()


func process_blueprint(blueprint):
	pass
	#var gun_name_snake_case = blueprint.id.to_snake_case()
#
	#var db = f.db()
	#db.busy = false
	#db.do_force_end = true
	#db.end_via_subprint = true
	#db.subprint_json = "res://src/Dialog/ShopMaster.json"
	#db.subprint_conversation = "blueprint_%s" % gun_name_snake_case
