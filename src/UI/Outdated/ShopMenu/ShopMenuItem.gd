@tool
extends Control

const CURSOR = preload("res://src/UI/ShopMenu/Cursor.tscn")

@export var item: Resource: set = on_item_changed

@export var sprite: NodePath
@export var shadow: NodePath

func on_item_changed(new):
	if Engine.is_editor_hint():
		item = new
		get_node(sprite).texture = new.texture
		get_node(shadow).texture = new.texture



func _on_ShopMenuItem_resized():
	var sp = get_node(sprite)

	sp.position = size / 2

	if size.x >= 96 and size.y >= 64:
		sp.scale = Vector2(4,4)
	elif size.x >= 72 and size.y >= 48:
		sp.scale = Vector2(3,3)
	elif size.x >= 48 and size.y >= 32:
		sp.scale = Vector2(2,2)
	else:
		sp.scale = Vector2(1,1)


func _on_ShopMenuItem_focus_entered():
	#modulate = Color.aqua
	add_child(CURSOR.instantiate())


func _on_ShopMenuItem_focus_exited():
	#modulate = Color(1, 1, 1)
	$Cursor.queue_free()
