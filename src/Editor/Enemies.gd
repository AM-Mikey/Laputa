extends MarginContainer

const ENEMY_BUTTON = preload("res://src/Editor/Button/EnemyButton.tscn")

signal enemy_changed(enemy_path)

var enemies = {}
var active_enemy_path


@onready var editor = get_parent().get_parent().get_parent().get_parent()

func _ready():
	setup_enemies()


func setup_enemies(): #TODO: connect this to editor instead of _ready
	editor.connect("tab_changed", Callable(self, "on_tab_changed"))
	var index = 0
	for e in find_enemy_scenes("res://src/Actor/Enemy/"):

		var enemy = load(e).instantiate()
		if not enemy.editor_hidden:
			enemies[enemy.name] = enemy

			var enemy_button = ENEMY_BUTTON.instantiate()
			enemy_button.enemy_path = e
			enemy_button.enemy_name = enemy.name
			enemy_button.enemy_sprite = enemy.get_node("Sprite2D").texture
			enemy_button.connect("enemy_changed", Callable(self, "change_enemy"))
			if index == 0:
				enemy_button.active = true
				active_enemy_path = e
			$VBox/Margin/Scroll/Buttons.add_child(enemy_button)
			index += 1


func find_enemy_scenes(path):
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".tscn"):
			files.append(path + file)

	return files

func change_enemy(enemy_path):
	editor.set_tool("entity", "enemy")
	active_enemy_path = enemy_path


func unpick_enemy():
	active_enemy_path = null
	for e in $VBox/Margin/Scroll/Buttons.get_children():
			e.deactivate()

### SINGALS ###

func on_tab_changed(tab_name):
	pass
