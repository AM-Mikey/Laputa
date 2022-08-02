extends Bullet

var start_velocity 
onready var ap = $AnimationPlayer

func _ready():
	add_to_group("WindBullets")
	ap.play("RotateLeft")
	
	velocity = get_initial_velocity()
	start_velocity = max((abs(velocity.x) + abs(velocity.y)/2), 0.1) #used to calculate animation slowdown


func _physics_process(delta):
	if disabled: return
	
	velocity.y += gravity * delta
	
	var avr_velocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	ap.playback_speed = avr_velocity / start_velocity
	if ap.playback_speed < .1:
		ap.stop()
	
	move_and_slide(velocity)



### HELPERS

func get_initial_velocity() -> Vector2:
	var out = velocity
	
	out.x = speed * direction.x
	out.y = speed * direction.y

	return out




### SIGNALS

func _on_CollisionDetector_body_entered(body):
	if disabled: return
	if body.get_collision_layer_bit(0): #player
		var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
		body.hit(damage, blood_direction)
		queue_free()
	elif body.get_collision_layer_bit(3): #world
		fizzle("world")
	elif body.get_collision_layer_bit(5): #armor
		fizzle("armor")


func _on_VisibilityNotifier2D_viewport_exited(_viewport):
	queue_free()
