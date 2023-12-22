@tool
extends MarginContainer

@export var color: Color = Color.WHITE: set = _on_color_changed

func _on_color_changed(new):
	if Engine.is_editor_hint():
		color = new
		$TL.self_modulate = new
		$TR.self_modulate = new
		$BR.self_modulate = new
		$BL.self_modulate = new


func _on_Cursor_resized():
	var l = 0
	var r = size.x
	var t = 0
	var b = size.y
	
	$TL.position = Vector2(l, t)
	$TR.position = Vector2(r, t)
	$BL.position = Vector2(l, b)
	$BR.position = Vector2(r, b)
 
