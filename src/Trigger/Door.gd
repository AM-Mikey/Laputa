extends Area2D

var open_sound = load("res://assets/SFX/Placeholder/snd_door.ogg")
var locked_sound = load("res://assets/SFX/Placeholder/snd_gun_click.ogg")

var has_player_near = false
var active_player = null

onready var world = get_tree().get_root().get_node("World")

signal level_change(level, door_index, level_name, music)

export var level: String
export var door_index: int = 0
export var locked = false

func _ready():
	connect("level_change", world, "on_level_change")
	add_to_group("LevelTriggers")

func _on_LevelTrigger_body_entered(body):
	has_player_near = true
	active_player = body

func _on_LevelTrigger_body_exited(_body):
	has_player_near = false
	active_player = null


func _input(event):
	var level_name = get_parent().get_parent().level_name
	var music = get_parent().get_parent().music
	
	var sfx_player = world.get_node("SFXPlayer")
	
	if event.is_action_pressed("inspect") and has_player_near == true and active_player.disabled == false:
		if not locked:
			sfx_player.stream = open_sound
			sfx_player.play()
			emit_signal("level_change", level, door_index, level_name, music)
		else:
			if active_player.inventory.has("Key"):
				var index = active_player.inventory.find("Key")
				active_player.inventory.remove(index)
				sfx_player.stream = open_sound
				sfx_player.play()
				emit_signal("level_change", level, door_index, level_name, music)
			else:
				$AudioStreamPlayer.stream = locked_sound
				$AudioStreamPlayer.play()
