extends MarginContainer

const ENEMY_BUTTON = preload("res://src/Editor/Button/EnemyButton.tscn")

signal enemy_changed(enemy_path)

var enemies = {}
var active_enemy_path


onready var editor = get_parent().get_parent().get_parent()

func _ready():
	setup_enemies()


func setup_enemies():
	var index = 0
	for e in find_enemy_scenes("res://src/Actor/Enemy/"):
		
		var enemy = load(e).instance()
		if not enemy.editor_hidden:
			enemies[enemy.name] = enemy
			
			var enemy_button = ENEMY_BUTTON.instance()
			enemy_button.enemy_path = e
			enemy_button.enemy_name = enemy.name
			enemy_button.connect("enemy_changed", self, "change_enemy")
			if index == 0:
				enemy_button.active = true
				active_enemy_path = e
			$VBox/Margin/Scroll/Buttons.add_child(enemy_button)
			index += 1


func find_enemy_scenes(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)

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
	for e in $VBox/Margin/Scroll/Buttons.get_children():
		if e.enemy_path == active_enemy_path: #this is weird, we should have already done this. for extra security in case it was activated another way?
			e.activate()
	
	emit_signal("enemy_changed", active_enemy_path)


func unpick_enemy():
	active_enemy_path = null
	for e in $VBox/Margin/Scroll/Buttons.get_children():
			e.deactivate()
