extends "res://src/Prop/Minecart.gd"

## Minecart with spikes on one side.
## Everything comes from Minecart.gd; override only the functions/values that differ for the spiked cart
## here (call super() inside an override to keep the base behaviour as well).

## Which side the spikes are on. Flips the sprite and moves the SpikesDetector.
#0-based so the values match the option indexes the level editor's inspector stores (PropertyButton);
#use side() for the x sign
enum Flip {LEFT, RIGHT}
@export var flip: Flip = Flip.RIGHT: set = set_flip
var spike_damage := 4
var spike_enemy_interval := 0.5 #s between hits on an enemy that stays on the spikes

var _enemy_hit_cooldowns := {} #enemy -> seconds until the spikes can hit it again
var _spikes_base_pos: Vector2 #SpikesDetector shape position as placed in the scene (spikes on the right)


func _init():
	ICON = preload("res://assets/Prop/MinecartSpikesIcon.png")


func setup():
	_spikes_base_pos = $SpikesDetector/CollisionShape2D.position
	super()


func set_flip(val):
	flip = Flip.LEFT if int(val) <= 0 else Flip.RIGHT #-1 is the old LEFT
	if is_node_ready():
		applied_look = Vector2i(-1, 0) #force a refresh even if the grade didn't change
		_apply_look()


#x sign of the side the spikes are on: -1 left, 1 right
func side() -> int:
	return -1 if flip == Flip.LEFT else 1


#unlike the base cart, the sprite isn't flipped for slopes going the other way: the flip and the spikes
#hitbox always follow `flip`, so the spikes never change sides.
#The hitbox still turns with the cart on slopes: the slope frames are the cart
#rotated around its middle by the slope's angle, so the hitbox is rotated the same way around it.
func _apply_look():
	super()
	var dir_x := side()
	#flipped for LEFT; the Reverse slope frames are drawn mirrored, so they flip the other way
	$Sprite2D.flip_h = (dir_x < 0) != _uses_reverse_anim()
	_sync_cargo_sprite()
	var mid := CART_SIZE / 2.0
	var offset := Vector2(0, CART_SIZE.y - grade_support[grade]) #slope frames sit higher, same as the sprite
	var angle: float = atan(grade_dir * GRADE_RISE[grade])
	var rel := _spikes_base_pos - mid
	rel.x *= dir_x #mirror to the left side
	var shape: CollisionShape2D = $SpikesDetector/CollisionShape2D
	shape.position = mid + offset + rel.rotated(angle)
	shape.rotation = angle


#the slope frames lean down to the right; for a slope the other way (relative to the way the spikes face,
#since the sprite is flipped for LEFT) use the "<Grade>Reverse" frames instead of flipping.
func _get_grade_anim() -> String:
	var anim := super()
	return anim + "Reverse" if _uses_reverse_anim() else anim


func _uses_reverse_anim() -> bool:
	return grade != Grade.FLAT && grade_dir * side() < 0 && ap.has_animation(GRADE_ANIM[grade] + "Reverse")


func _physics_process(delta):
	super(delta)
	_update_spikes(delta)


#SpikesDetector masks breakable (9), playerhurt (17) and enemyhurt (18). Boxes (BreakBlocks group) touching the
#spikes break.
#Players are hit every frame they touch the spikes; their own iframes space the hits out. Enemies have no
#iframes, so they get a cooldown instead.
func _update_spikes(delta):
	for enemy in _enemy_hit_cooldowns.keys():
		_enemy_hit_cooldowns[enemy] -= delta
		if !is_instance_valid(enemy) || _enemy_hit_cooldowns[enemy] <= 0.0:
			_enemy_hit_cooldowns.erase(enemy)

	var spikes: Vector2 = $SpikesDetector/CollisionShape2D.global_position
	for area in $SpikesDetector.get_overlapping_areas():
		var target: Node = area.get_parent()
		if !is_instance_valid(target): continue
		if area.get_collision_layer_value(9): #breakable: only boxes, not health upgrades etc.
			if target.is_in_group("BreakBlocks") && !target.get("broken"):
				target.on_break("cut")
			continue
		if !target.has_method("hit"): continue
		var away := Vector2(sign(target.global_position.x - spikes.x), 0.0)
		if area.get_collision_layer_value(17): #playerhurt
			if target.get("dead") || target.get("invincible") || spares(target): continue #riders are safe
			target.hit(spike_damage, away, $SpikesDetector)
		elif area.get_collision_layer_value(18): #enemyhurt
			if _enemy_hit_cooldowns.has(target): continue
			_enemy_hit_cooldowns[target] = spike_enemy_interval
			target.hit(spike_damage, away, $SpikesDetector, away)
