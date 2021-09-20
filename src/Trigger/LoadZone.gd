extends Area2D

const TRANSITION = preload("res://src/Effect/Transition/TransitionWipe.tscn")

var open_sound = load("res://assets/SFX/placeholder/snd_door.ogg")

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
	active_player.disabled = true
	if active_player.get_node("AnimationPlayer").is_playing():
		active_player.get_node("AnimationPlayer").stop()
	prepare_next_level()

func _on_LoadZone_body_exited(_body):
	pass


func prepare_next_level():
	var level_name = get_parent().get_parent().level_name
	var music = get_parent().get_parent().music
	
	var sfx_player = world.get_node("SFXPlayer")
	sfx_player.stream = open_sound
	sfx_player.play()
	
	var transition = TRANSITION.instance()
	match direction:
		Vector2.LEFT: transition.animation = "WipeInLeft"
		Vector2.RIGHT: transition.animation = "WipeInRight"
		Vector2.UP: transition.animation = "WipeInUp"
		Vector2.DOWN: transition.animation = "WipeInDown"
	
	if world.get_node("UILayer").has_node("TransitionWipe"):
		world.get_node("UILayer/TransitionWipe").free()
	
	world.get_node("UILayer").add_child(transition)
	
	yield(transition.get_node("AnimationPlayer"), "animation_finished")
	
	emit_signal("level_change", level, door_index, level_name, music)
	





