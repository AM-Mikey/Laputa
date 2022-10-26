extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D

var projectile_speed = Vector2.ZERO
var projectile_range: int
var max_spread_distance = 7
var recoil_velocity = 40

onready var pc = get_tree().get_root().get_node("World/Juniper")



func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var spread_distance = int(rng.randf_range(max_spread_distance * -1, max_spread_distance))
	
	rotation_degrees = get_rot(direction)
	match direction:
		Vector2.LEFT:
			#global_position.y += spread_distance
			pc.mm.velocity.x += recoil_velocity
		Vector2.RIGHT:
			#global_position.y += spread_distance
			pc.mm.velocity.x -= recoil_velocity
		Vector2.UP:
			#global_position.x += spread_distance
			pc.mm.velocity.y += recoil_velocity
		Vector2.DOWN:
			#global_position.x += spread_distance
			pc.mm.velocity.y -= recoil_velocity


func _physics_process(_delta):
	if disabled: return
	
	velocity = speed * direction
	velocity = move_and_slide(velocity)
	if origin.distance_to(global_position) > f_range:
		fizzle("range")
