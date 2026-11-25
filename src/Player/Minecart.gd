extends Node

## Riding a rideable minecart (Minecart.gd with rideable = true).
## - Entered from Run by pressing interact (down) while standing on top of the cart.
## - The player sits centered in the cart, feet RIDE_DEPTH px above the cart's bottom, and moves with it.
## - Left/right drives the cart with its own push physics (cart.rider_push_dir()), so slopes, top speed etc.
##   are the cart's. The player can shoot in every direction; shooting down still needs open space below.
## - Jump leaves it as a normal jump. Hitting a ceiling/wall with the head (the part above the cart) knocks
##   the player out. No knockback while riding; death leaves through the death state as usual.
## The cart stays solid while ridden (it only drops its armor layer); the rider and the rider's own shots
## ignore it, and things landing on top get shoved off. See Minecart.gd "RIDING".

const RIDE_DEPTH := 8.0 #px from the cart's bottom up to the rider's feet
const EXIT_IFRAME_TIME := 1.0 #s of invincibility after leaving the cart (jumping out or knocked out)

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var run = get_parent().get_node("Run")
@onready var sprite = pc.get_node("Sprite2D")

var cart: Node = null
var _exited_msec := -100000 #when the player last left a cart, for is_cart_immune()


func ride(new_cart: Node):
	cart = new_cart
	mm.change_state("minecart")


func state_process(_delta):
	if !is_instance_valid(cart) || !cart.is_inside_tree():
		knock_out()
		return

	run.set_player_directions() #same aiming as on foot, shoot-down checks the ground under the cart
	if !inp.can_act:
		pc.move_dir = Vector2.ZERO

	#follow the cart. The cart moves in the physics step after this, so aim for where it'll be or the rider
	#trails it a frame. The head sticks out above it: if it would end up in the level (a low ceiling, a wall)
	#the player is knocked out and stays behind
	var target: Vector2 = get_seat_position() + cart.linear_velocity * _delta
	var motion: Vector2 = target - pc.global_position
	if _head_hits_level(target):
		knock_out(-signf(motion.x))
		return
	pc.global_position = target
	pc.velocity = cart.linear_velocity

	if inp.pressed("jump") && inp.can_act:
		mm.change_state("jump") #not mm.jump(): that refuses while is_crouching, which a low ceiling can set
		return

	run.play_animation("stand")


#minecarts don't squish/crush a player who is riding one or left one less than EXIT_IFRAME_TIME ago
#(Minecart.gd spares()). Normal iframes don't protect from carts, so this is tracked separately
func is_cart_immune() -> bool:
	return mm.current_state == self || Time.get_ticks_msec() - _exited_msec < EXIT_IFRAME_TIME * 1000.0


func get_seat_position() -> Vector2:
	return cart.global_position + Vector2(cart.CART_SIZE.x / 2.0, cart.CART_SIZE.y - RIDE_DEPTH)


#out of the cart without a jump: dropped on the ground just behind the cart (back_dir, or the way the player
#faces away from), so they aren't left standing inside it. If neither side has room they drop from the seat.
func knock_out(back_dir := 0.0):
	if back_dir == 0.0: back_dir = -pc.look_dir.x
	if is_instance_valid(cart):
		for side in [back_dir, -back_dir]:
			var spot: Vector2 = cart.global_position + Vector2(cart.CART_SIZE.x / 2.0 + side * (cart.CART_SIZE.x / 2.0 + 7.0), cart.CART_SIZE.y)
			if _has_room(spot):
				pc.global_position = spot
				break
	pc.velocity = Vector2.ZERO
	mm.change_state("jump")


#only static level geometry counts: boxes/enemies/carts landing on the cart are shoved off by the cart
#instead (Minecart.gd _update_top_shove), and the rider's head passes up through one-way ssp
func _head_hits_level(feet: Vector2) -> bool:
	var head: CollisionShape2D = pc.get_node("MinecartCollision")
	var shape := RectangleShape2D.new()
	shape.size = head.shape.size - Vector2(0.2, 0.2)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, feet + head.position)
	query.collision_mask = 8 #world
	query.exclude = [cart.get_rid()]
	for hit in pc.get_world_2d().direct_space_state.intersect_shape(query, 8):
		if !(hit.collider is RigidBody2D) && !(hit.collider is CharacterBody2D):
			return true
	return false


func _has_room(feet: Vector2) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(11.8, 14.8)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, feet + Vector2(0.0, -7.6))
	query.collision_mask = pc.collision_mask
	query.exclude = [cart.get_rid()]
	return pc.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


### STATE ###

func enter(_prev_state: String) -> void:
	#only the part sticking out above the cart collides while riding, so the ground beside the cart on a
	#slope doesn't count as hitting something
	mm.disable_collision_shapes([pc.get_node("CollisionShape2D"), pc.get_node("CrouchingCollision"), pc.get_node("JumpCollision")])
	mm.enable_collision_shapes([pc.get_node("MinecartCollision")])
	pc.is_crouching = false
	pc.is_in_coyote = false
	mm.coyote_timer.stop()
	sprite.position = Vector2(0.0, -16.0)
	sprite.gun_pos_offset = Vector2.ZERO
	if is_instance_valid(cart):
		cart.set_rider(pc)
		pc.get_node("GunManager/ShootDown").add_exception(cart) #shooting down checks the ground under the cart
		pc.global_position = get_seat_position()
		pc.velocity = cart.linear_velocity
	run.play_animation("stand")


func exit(_next_state: String) -> void:
	mm.disable_collision_shapes([pc.get_node("MinecartCollision")])
	mm.enable_collision_shapes([pc.get_node("CollisionShape2D")])
	if is_instance_valid(cart):
		pc.get_node("GunManager/ShootDown").remove_exception(cart)
		if cart.rider == pc:
			cart.set_rider(null)
	cart = null
	_exited_msec = Time.get_ticks_msec()
	pc.do_iframes(EXIT_IFRAME_TIME) #does nothing when leaving through death
