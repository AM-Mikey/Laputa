extends Area2D

const TRANSITION = preload("res://src/Effect/Transition/TransitionIris.tscn")

var open_sound = load("res://assets/SFX/Placeholder/snd_door.ogg")
var locked_sound = load("res://assets/SFX/Placeholder/snd_gun_click.ogg")

var has_player_near = false
var active_player = null

onready var world = get_tree().get_root().get_node("World")

signal level_change(level, door_index, music)

export var level: String
export var door_index: int = 0
export var locked = false

func _ready():
	var _val = connect("level_change", world, "on_level_change")
	add_to_group("LevelTriggers")
	add_to_group("Doors")

func _on_Door_body_entered(body):
	has_player_near = true
	active_player = body

func _on_Door_body_exited(_body):
	has_player_near = false


func _input(event):
	if event.is_action_pressed("inspect") and has_player_near and not active_player.disabled and active_player.is_on_floor(): #floor check recently
		if not locked:
			active_player.set_collision_layer_bit(0, false)
			active_player.disabled = true
			if active_player.get_node("AnimationPlayer").is_playing():
				active_player.get_node("AnimationPlayer").stop()
			prepare_next_level()
		else:
			if active_player.inventory.has("Key"):
				var index = active_player.inventory.find("Key")
				active_player.inventory.remove(index)
		
				active_player.set_collision_layer_bit(0, false)
				active_player.disabled = true
				if active_player.get_node("AnimationPlayer").is_playing():
					active_player.get_node("AnimationPlayer").stop()
				prepare_next_level()
			else:
				$AudioStreamPlayer.stream = locked_sound
				$AudioStreamPlayer.play()



func prepare_next_level():
	var level_name = get_parent().get_parent().level_name
	var music = get_parent().get_parent().music
	
	var sfx_player = world.get_node("SFXPlayer")
	sfx_player.stream = open_sound
	sfx_player.play()
	
	var transition = TRANSITION.instance()
	
	
	if world.get_node("UILayer").has_node("TransitionIris"):
		world.get_node("UILayer/TransitionIris").free()
	
	world.get_node("UILayer").add_child(transition)
	
	yield(transition.get_node("AnimationPlayer"), "animation_finished")
	
	emit_signal("level_change", level, door_index, music)
