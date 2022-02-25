tool
extends Control

const CURSOR = preload("res://src/UI/ShopMenu/Cursor.tscn")

export var item: Resource setget on_item_changed

export(NodePath) var sprite
export(NodePath) var shadow

func on_item_changed(new):
	if Engine.editor_hint:
		item = new
		get_node(sprite).texture = new.texture
		get_node(shadow).texture = new.texture



func _on_ShopMenuItem_resized():
	var sp = get_node(sprite)
	
	sp.position = rect_size / 2
	
	if rect_size.x >= 96 and rect_size.y >= 64:
		sp.scale = Vector2(4,4)
	elif rect_size.x >= 72 and rect_size.y >= 48:
		sp.scale = Vector2(3,3)
	elif rect_size.x >= 48 and rect_size.y >= 32:
		sp.scale = Vector2(2,2)
	else:
		sp.scale = Vector2(1,1)


func _on_ShopMenuItem_focus_entered():
	#modulate = Color.aqua
	add_child(CURSOR.instance())


func _on_ShopMenuItem_focus_exited():
	#modulate = Color(1, 1, 1)
	$Cursor.queue_free()
