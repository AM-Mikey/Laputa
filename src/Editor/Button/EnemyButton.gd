extends MarginContainer

signal enemy_changed(enemy_path)

var enemy_path: String
var enemy_name: String
var enemy_icon: Texture2D
var enemy_difficulty = 0
var enemy_max_difficulty = 0
var active = false

func _ready():
	%Label.text = enemy_name
	%PanelActive.visible = active
	set_icon()

func activate():
	for e in get_tree().get_nodes_in_group("EnemyButtons"):
		e.deactivate()
	%PanelActive.visible = true
	active = true

func deactivate():
	%PanelActive.visible = false
	active = false

### HELPER ###

func set_icon():
	var frame = enemy_difficulty
	var texture = AtlasTexture.new()
	texture.atlas = enemy_icon
	texture.region = Rect2(0, frame * 16.0, 16.0, 16.0)
	%TextureRect.texture = texture

### SIGNALS ###

func _on_Button_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				activate()
				emit_signal("enemy_changed", enemy_path)
			MOUSE_BUTTON_RIGHT:
				if enemy_difficulty == enemy_max_difficulty:
					enemy_difficulty = 0
				else:
					enemy_difficulty += 1
	set_icon()
