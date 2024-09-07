extends Bullet

#var texture: CompressedTexture2D #why are these here?
#var texture_index: int
#var collision_shape: RectangleShape2D

func _ready():
	if direction == Vector2.LEFT or direction == Vector2.RIGHT:
		scale.x = direction.x *-1
		$Sprite2D.scale = Vector2.ONE
	if direction == Vector2.UP or direction == Vector2.DOWN:
		rotation_degrees = get_rot(direction)
		#$Sprite2D.scale.x = -1
	#scale.y = direction.y *-1

	$AnimationPlayer.play("Slash")
	await $AnimationPlayer.animation_finished
	queue_free()

#func _physics_process(_delta):
	#if disabled: return
	#velocity = speed * direction
	#move_and_slide()
	#if origin.distance_to(global_position) > f_range:
		#do_fizzle("range")
