extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D

var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var projectile_speed = Vector2.ZERO

var projectile_range: int

var origin = Vector2.ZERO



var duration = 0.1


func _ready():
	default_body_collision = false
	
	$Timer.start(duration)
	
	if direction == Vector2.LEFT:
		rotation_degrees = 0
	if direction == Vector2.RIGHT:
		rotation_degrees = 180
	if direction == Vector2.UP:
		rotation_degrees = 90
	if direction == Vector2.DOWN:
		rotation_degrees = -90

#shotgun bullets do not stop on world so it doesn't delete the bullet if it clipped world
#shotgun bullets can also go through multiple creatures, they only dissapear after their timer ends
func _on_CollisionDetector_body_entered(body):
	
	if not disabled:
		if body.get_collision_layer_bit(8): #breakable
					body.on_break(break_method)

		elif body.get_collision_layer_bit(1): #enemy
			yield(get_tree(), "idle_frame")
			var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage, blood_direction)


func _on_Timer_timeout():
	queue_free()
