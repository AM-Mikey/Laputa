extends Area2D


const EFFECT = preload("res://src/Effect/Effect.tscn")

var damage: int = 2
var projectile_range: int = 240

var velocity: = Vector2.ZERO
var direction: = Vector2.ZERO

var origin: = Vector2.ZERO

func _physics_process(delta):
	if visible == true:
		translate(velocity)
		var distance_from_origin = origin.distance_to(global_position);
		if distance_from_origin > projectile_range:
			_fizzle_from_range()

func _on_Bullet_body_entered(body): #detects enemies
	if visible == true:
		if body.get_collision_layer_bit(0): #player
			var knockback_direction = Vector2(sign(body.global_position.x - global_position.x), 0)
			body.knockback_direction = knockback_direction
			body.hit(damage, knockback_direction)
			queue_free()
		elif body.get_collision_layer_bit(3): #world
			_fizzle_from_world()


func _fizzle_from_world():
	print("fizzle from world")
	visible = false
	
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
	print("removed bullet and effect")
	effect.queue_free()
	queue_free()

func _fizzle_from_range():
	print("fizzle from range")
	visible = false
	
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
		queue_free()
