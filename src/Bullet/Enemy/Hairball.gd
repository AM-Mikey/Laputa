extends Bullet

var start_velocity
onready var ap = $AnimationPlayer



func _ready():
	is_enemy_bullet = true
	add_to_group("WindBullets")
	ap.play("Rotate")
	gravity *= .5
	
	velocity = get_velocity(speed, direction)
	start_velocity = abs(velocity.x) + abs(velocity.y)/2 #used to calculate animation slowdown


func _physics_process(delta):
	if disabled: return
	
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity)
	
	var current_velocity = abs(velocity.x) + abs(velocity.y) /2 #used to calculate animation slowdown
	ap.playback_speed = current_velocity / start_velocity
	if ap.playback_speed < .1:
		ap.stop()


func get_velocity(projectile_speed, direction) -> Vector2:
	var out = velocity
	out.x = projectile_speed * direction.x
	out.y += gravity * get_physics_process_delta_time()
	
	if direction.y < 0:
		out.y = projectile_speed * direction.y
	return out

func on_break(method):
	if disabled == false:
		fizzle("bullet")
