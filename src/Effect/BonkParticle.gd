extends Node2D

var type = "bonk"
var normal = Vector2(1,0) #down


func _ready():
	match type:
		"bonk": $AudioStreamPlayer.stream = load("res://assets/SFX/Placeholder/snd_quote_bonkhead.ogg")
		"land": $AudioStreamPlayer.stream = load("res://assets/SFX/Placeholder/snd_thud.ogg")
	$AudioStreamPlayer.play()
	$Left.direction = normal.rotated(deg2rad(90))
	$Right.direction = normal.rotated(deg2rad(-90))
	$Left.emitting = true
	$Right.emitting = true

	yield(get_tree().create_timer(.4), "timeout")
	queue_free()
