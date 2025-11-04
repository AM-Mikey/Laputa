extends Node2D

var price: int
var item_name: String
var item_description: String

@onready var name_label = $Panel/MarginContainer/VBoxContainer/ItemName
@onready var description_label = $Panel/MarginContainer/VBoxContainer/ItemDescription

func _ready():
	display_tooltip()

func display_tooltip():
	name_label.text = item_name
	description_label.text = item_description
	$MoneyNumber.value = price
	$MoneyNumber.display_number()
