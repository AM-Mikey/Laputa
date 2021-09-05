extends Control

onready var pc = get_tree().get_root().get_node("World/Recruit")


func _process(delta):
	$GridContainer/Bars/HBox/A/HP.text = pc.hp + " / " + pc.max_hp

