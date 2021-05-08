extends KinematicBody2D

class_name Bullet, "res://assets/Icon/BulletIcon.png"

const EFFECT = preload("res://src/Effect/Effect.tscn")



var disabled = false
var gravity = 300
var damage


func _on_Bullet_body_entered(body): #detects enemies
	if not disabled:
		if body.get_collision_layer_bit(1): #enemy
			var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage, blood_direction)
			queue_free()
		elif body.get_collision_layer_bit(3): #world
			visible = false
			disabled = true
			_fizzle_from_world()


func _fizzle_from_world():
	#print("fizzle from world")
	var effect = EFFECT.instance()
	get_parent().add_child(effect)
	effect.position = $End.global_position
	
	var player = effect.get_node("AnimationPlayer")
	player.play("DiamondPop")
	
	var audio = effect.get_node("AudioStreamPlayer")
	audio.stream = load("res://assets/SFX/snd_shot_hit.ogg")
	audio.play()
	
	yield(player, "animation_finished")
	#yield(audio, "finished")
	#print("removed bullet and effect")
	effect.queue_free()
	queue_free()

func _fizzle_from_range():
	#print("fizzle from range")
	var effect = EFFECT.instance()
	get_parent().add_child(effect)
	effect.position = global_position
	
	var player = effect.get_node("AnimationPlayer")
	player.play("StarPop")
	yield(player, "animation_finished")
	#print("removed bullet and effect")
	effect.queue_free()
	queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	if visible != false:
		#print("WARNING: bullet has exited screen")
		queue_free()

