extends Control

const TAB_BUTTON = preload("res://src/Editor/Button/TabButton.tscn")

var icons = load("res://assets/Editor/TabIcons.png")

@onready var editor = get_parent().get_parent().get_parent()
@onready var tabs = get_parent().get_node("Tab").get_children()

func _ready():
	var index = 0
	for t in tabs:
		var button = TAB_BUTTON.instantiate()

		var icon = AtlasTexture.new()
		icon.atlas = icons
		icon.region = Rect2(16 * index, 0, 16, 16)
		button.icon = icon

		button.tab_index = index
		$VBox.add_child(button)
		button.connect("tab_selected", Callable(editor, "on_tab_selected"))
		index += 1
