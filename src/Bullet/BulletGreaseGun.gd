extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D

var projectile_speed = Vector2.ZERO

var projectile_range: int
var max_spread_distance = 7
var recoil_velocity = 40

var rng = RandomNumberGenerator.new()

onready var pc = get_tree().get_root().get_node("World/Juniper")

func _ready():
	rng.randomize()
	var spread_distance = int(rng.randf_range(max_spread_distance * -1, max_spread_distance))
	
	match direction:
		Vector2.LEFT:
			rotation_degrees = 0
			global_position.y #+= spread_distance
			pc.mm.velocity.x += recoil_velocity
		Vector2.RIGHT:
			rotation_degrees = 180
			global_position.y #+= spread_distance
			pc.mm.velocity.x -= recoil_velocity
		Vector2.UP:
			rotation_degrees = 90
			global_position.x #+= spread_distance
			pc.mm.velocity.y += recoil_velocity
		Vector2.DOWN:
			rotation_degrees = -90
			global_position.x #+= spread_distance
			pc.mm.velocity.y -= recoil_velocity


func _physics_process(_delta):
	velocity = projectile_speed * direction
	
	if not disabled:
		move_and_slide(velocity)
		var distance_from_origin = origin.distance_to(global_position);
		if distance_from_origin > projectile_range:
			fizzle("range")
