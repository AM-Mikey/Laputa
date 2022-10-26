extends Bullet

var start_velocity 
onready var ap = $AnimationPlayer

func _ready():
	is_enemy_bullet = true
	add_to_group("WindBullets")
	ap.play("RotateLeft")
	
	velocity = get_initial_velocity()
	start_velocity = max((abs(velocity.x) + abs(velocity.y) /2), 0.1) #used to calculate animation slowdown



func _physics_process(delta):
	if disabled: return
	
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity)
	
	var current_velocity = abs(velocity.x) + abs(velocity.y) /2 #used to calculate animation slowdown
	ap.playback_speed = current_velocity / start_velocity
	if ap.playback_speed < .1:
		ap.stop()



### HELPERS ###

func get_initial_velocity() -> Vector2:
	var out = Vector2(\
	speed * direction.x,\
	speed * direction.y)
	return out
