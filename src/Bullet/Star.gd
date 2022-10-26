extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D

var minimum_speed: float = 6
var bounciness = 1 #.6
var fizzle_time = 12.0
var start_velocity
var touched_floor = false



onready var w = get_tree().get_root().get_node("World")
onready var pc = w.get_node("Juniper")



func _ready():
	break_method = "cut"
	default_area_collision = false
	default_body_collision = false
	default_clear = false
	

	velocity = get_initial_velocity()
	start_velocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	


func _physics_process(delta):
	if not disabled:
		velocity.y += gravity * delta
		
		if velocity.x > 0:
			$AnimationPlayer.play("FlipLeft")
		else:
			$AnimationPlayer.play("FlipRight")
		
		var collision = move_and_collide(velocity * delta)
		if collision:
			if abs(velocity.y) > minimum_speed:
				velocity *= bounciness
				velocity = velocity.bounce(collision.normal)
				am.play_pos("gun_star_bounce", self)
			else:
				velocity = Vector2.ZERO
	
	
	var avr_velocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown
	$AnimationPlayer.playback_speed = avr_velocity / start_velocity
	if $AnimationPlayer.playback_speed < .1:
		$AnimationPlayer.stop()




func get_initial_velocity() -> Vector2:
	var out = velocity

	out.x = speed * direction.x
	out.y = speed * direction.y
	
	out.y -= 80 #give us some ups to start with

	return out



### SIGNALS ###

func _on_CollisionDetector_body_entered(body):
	if disabled: return
	#enemy
	if body.get_collision_layer_bit(1): 
		if not touched_floor:
			body.hit(damage, get_blood_dir(body))
		else:
			body.hit(damage/2, get_blood_dir(body))
		queue_free()


func _on_FizzleTimer_timeout():
	fizzle("range")
