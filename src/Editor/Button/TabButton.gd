extends MarginContainer

signal tab_selected(tab_index)

var icon
var tab_index: int

func _ready():
	$VBox/TextureRect.texture = icon
	$VBox/TextureRect/Shadow.texture = icon
	$VBox/TextureRect/Highlight.texture = icon


func on_pressed():
	emit_signal("tab_selected", tab_index)
