extends Area2D

var open_sound = load("res://assets/SFX/snd_door.ogg")

var active_player = null

onready var world = get_tree().get_root().get_node("World")

signal level_change(level, door_index, level_name, music)

export var level: String
export var door_index: int = 0
export var direction = Vector2.RIGHT

func _ready():
	connect("level_change", world, "_on_level_change")
	add_to_group("LevelTriggers")
	add_to_group("LoadZones")


func _on_LoadZone_body_entered(body):
	active_player = body

	active_player.set_collision_layer_bit(0, false)
	prepare_next_level()

func _on_LoadZone_body_exited(body):
	pass


func prepare_next_level():
	var level_name = get_parent().get_parent().level_name
	var music = get_parent().get_parent().music
	
	var sfx_player = world.get_node("SFXPlayer")
	sfx_player.stream = open_sound
	sfx_player.play()
	emit_signal("level_change", level, door_index, level_name, music)
	





