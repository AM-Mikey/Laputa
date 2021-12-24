extends Trigger

const TRANSITION = preload("res://src/Effect/Transition/TransitionIris.tscn")

var open_sound = load("res://assets/SFX/Placeholder/snd_door.ogg")
var locked_sound = load("res://assets/SFX/Placeholder/snd_gun_click.ogg")

signal level_change(level, door_index, music)

export var level: String
export var door_index: int = 0
export var locked = false

onready var world = get_tree().get_root().get_node("World")

func _ready():
	var _val = connect("level_change", world, "on_level_change") #TODO a better way of not returning this
	
	trigger_type = "door"
	
	add_to_group("LevelTriggers")
	add_to_group("Doors")

func _on_body_entered(body):
	active_pc = body

func _on_body_exited(_body):
	active_pc = null


func _input(event):
	if event.is_action_pressed("inspect") and active_pc != null:
		if not active_pc.disabled and active_pc.is_on_floor():
			if not locked:
				active_pc.set_collision_layer_bit(0, false) #TODO: why not just respawn the player?
				active_pc.disabled = true
				if active_pc.get_node("AnimationPlayer").is_playing():
					active_pc.get_node("AnimationPlayer").stop()
				prepare_next_level()
			else:
				if active_pc.inventory.has("Key"):
					var index = active_pc.inventory.find("Key") #TODO: have door store a specific key
					active_pc.inventory.remove(index)
			
					active_pc.set_collision_layer_bit(0, false)
					active_pc.disabled = true
					if active_pc.get_node("AnimationPlayer").is_playing():
						active_pc.get_node("AnimationPlayer").stop()
					prepare_next_level()
				else:
					$AudioStreamPlayer.stream = locked_sound
					$AudioStreamPlayer.play()



func prepare_next_level():
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

