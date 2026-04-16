extends Enemy

const ICON = preload("res://assets/Actor/Enemy/TadpoleIcon.png")

var move_dir := Vector2.ZERO
var idle_time_min := 1.0
var idle_time_max := 5.0
var active_time_min := 1.0
var active_time_max := 10.0

var swim_speed := Vector2(40, 40)
var just_hit_wall = false
var wall_normal

var target_dir := Vector2.ZERO
var turn_rate := 2.0 #1.8
var water_friction := 0.04

var water_trigger = null
var water_rect := Rect2()

var flock_radius := 80.0
var sep_radius := 20.0
var flock_check_time := 0.4

var weight_alignment  := 1.0
var weight_cohesion   := 0.6
var weight_separation := 1.8

var scatter_radius := 48.0
var avoid_radius := 64.0
var scatter_speed_mult := 2.2
var scatter_duration_min := 0.6
var scatter_duration_max := 1.2
var scatter_cooldown_duration := 5.0
var scatter_to_flock_cooldown_duration := 5.0
var threats := []

func setup():
	hp = 1
	damage_on_contact = 0
	reward = 0
	rng.randomize()
	do_bubbles = false
	await get_tree().create_timer(0.01).timeout #TODO: for some reason the water trigger spawns really late. look into this or pass a signal
	_find_water_trigger()
	change_state("swim")


func _on_physics_process(delta):
	if disabled or dead: return
	update_drift(delta)
	$MoveCast.rotation = velocity.angle()
	$TargetCast.rotation = target_dir.angle()
	move_and_slide()
	_enforce_water_boundary()
	animate()


func update_drift(delta: float): #instead of normal velocity calculation
	if target_dir == Vector2.ZERO:
		velocity = velocity.lerp(Vector2.ZERO, water_friction)
		return

	#turn move_dir towards target_dir
	var angle_diff := move_dir.angle_to(target_dir)
	var max_turn := turn_rate * delta
	if abs(angle_diff) <= max_turn:
		move_dir = target_dir
	else:
		move_dir = move_dir.rotated(sign(angle_diff) * max_turn)
	#accelerate/decellerate
	var desired := move_dir * swim_speed.x
	velocity = velocity.lerp(desired, water_friction)



### STATES ###

func enter_swim(_prev_state):
	if target_dir == Vector2.ZERO:
		if move_dir == Vector2.ZERO:
			target_dir = Vector2.RIGHT.rotated(randf_range(0, TAU)) #random
		else:
			target_dir = move_dir
	move_dir = target_dir
	var swim_time = rng.randf_range(active_time_min, active_time_max)
	$StateTimer.start(swim_time)

func do_swim(_delta):
	if !$ScatterToFlockCooldownTimer.is_stopped(): return
	_check_threats()
	if _get_flock_neighbors().size() > 0: #join flock
		change_state("flock")


func enter_wait(_prev_state):
	target_dir = Vector2.ZERO
	var wait_time = rng.randf_range(idle_time_min, idle_time_max)
	$StateTimer.start(wait_time)

func do_wait(_delta):
	#print("wait ct")
	_check_threats()


func enter_flock(_prev_state):
	if target_dir == Vector2.ZERO:
		target_dir = move_dir if move_dir != Vector2.ZERO \
			else Vector2.RIGHT.rotated(randf_range(0, TAU))
	_on_FlockTimer_timeout() #calls and starts timer

func do_flock(_prev_state):
	#print("flock ct")
	_check_threats()

func enter_scatter(_prev_state):
	var threat_dir = _get_nearest_threat_dir()
	if threat_dir == Vector2.ZERO:
		threat_dir = Vector2.RIGHT.rotated(randf_range(0, TAU))

	target_dir = (threat_dir * -1).rotated(randf_range(-PI / 5.0, PI / 5.0)) #away from threat
	move_dir = target_dir

	velocity = move_dir * swim_speed.x * scatter_speed_mult #instantly raise velocity

	$FlockTimer.stop()
	$StateTimer.stop()
	var scatter_duration = rng.randf_range(scatter_duration_min, scatter_duration_max)
	$ScatterTimer.start(scatter_duration)
	$ScatterCooldownTimer.start(scatter_duration + scatter_cooldown_duration)

func do_scatter(_delta):
	#pass
	var threat_dir = _get_nearest_threat_dir()
	if threat_dir != Vector2.ZERO:
		target_dir = (threat_dir * -1).rotated(randf_range(-PI / 5.0, PI / 5.0)) #away from threat

### THREATS ###

func _check_threats():
	if !$ScatterCooldownTimer.is_stopped(): return #prevent re-entering if we're on cooldown
	if threats.is_empty(): return
	var nearest_dir := _get_nearest_threat_dir()
	if nearest_dir == Vector2.ZERO: return

	var nearest_dist := _get_nearest_threat_dist()
	if nearest_dist <= scatter_radius:
		#print("scatter")
		change_state("scatter")
	elif nearest_dist <= avoid_radius: #avoid threat instead
		target_dir = target_dir.lerp((nearest_dir * -1), 0.3).normalized()


func _get_nearest_threat_dir() -> Vector2:
	var best_dist := INF
	var out := Vector2.ZERO
	for t in threats:
		if not is_instance_valid(t): continue
		var d := global_position.distance_to(t.global_position)
		if d < best_dist:
			best_dist = d
			out = (t.global_position - global_position).normalized()
	return out


func _get_nearest_threat_dist() -> float:
	var out := INF
	for t in threats:
		if not is_instance_valid(t): continue
		var d := global_position.distance_to(t.global_position)
		if d < out:
			out = d
	return out

### WATER BOUNDARY ###

func _enforce_water_boundary():
	if water_trigger == null or water_rect == Rect2(): return

	var pos := global_position
	var clamped := Vector2(
		clamp(pos.x, water_rect.position.x, water_rect.end.x),
		clamp(pos.y, water_rect.position.y, water_rect.end.y))

	if clamped.is_equal_approx(pos): return

	global_position = clamped

	var normal := Vector2.ZERO
	if pos.x < water_rect.position.x or pos.x > water_rect.end.x:
		normal.x = sign(clamped.x - pos.x)
		velocity.x *= -1.0
	if pos.y < water_rect.position.y or pos.y > water_rect.end.y:
		normal.y = sign(clamped.y - pos.y)
		velocity.y *= -1.0

	if normal != Vector2.ZERO:
		var n := normal.normalized()
		wall_normal = n
		just_hit_wall = true
		if state == "scatter":
			# Pick a direction along the wall, biased away from the nearest threat.
			# The wall tangent is the normal rotated 90°; choose whichever tangent
			# points more away from the threat.
			var tangent := Vector2(-n.y, n.x)
			var threat_dir := _get_nearest_threat_dir()
			var away := -threat_dir if threat_dir != Vector2.ZERO else move_dir
			if tangent.dot(away) < 0:
				tangent = -tangent
			# Add a small random nudge so repeated corner bounces don't loop
			target_dir = tangent.rotated(randf_range(-PI / 6.0, PI / 6.0))
			move_dir = target_dir
			return
		target_dir = target_dir.reflect(n)
		move_dir = target_dir
		if state == "swim" or state == "flock":
			change_state("wait")



func _find_water_trigger():
	for t in get_tree().get_nodes_in_group("Triggers"):
		if t.trigger_type == "water":
			water_trigger = t
			for child in t.get_children():
				if child is CollisionShape2D and child.shape is RectangleShape2D:
					var half = child.shape.size / 2.0
					var center = t.global_position + child.position
					water_rect = Rect2(center - half, child.shape.size)
					return


### FLOCK HELPERS ###

func _get_flock_neighbors() -> Array:
	var neighbors := []
	for t in get_tree().get_nodes_in_group("Tadpoles"):
		if t == self: continue
		if t.dead or t.disabled: continue
		if t.water_trigger != water_trigger: continue
		if global_position.distance_to(t.global_position) <= flock_radius:
			neighbors.append(t)
	return neighbors


func _calc_flock_direction(neighbors: Array) -> Vector2:
	var separation := Vector2.ZERO
	var alignment := Vector2.ZERO
	var cohesion := Vector2.ZERO

	for n in neighbors:
		var offset: Vector2 = n.global_position - global_position
		var dist := offset.length()

		#separation
		if dist > 0.0 and dist < sep_radius:
			separation -= offset.normalized() * (1.0 - dist / sep_radius)
		#alignment
		if n.move_dir != Vector2.ZERO:
			alignment += n.move_dir
		# cohesion
		cohesion += offset

	var count := float(neighbors.size())
	alignment /= count
	cohesion /= count

	var steering := Vector2.ZERO
	if separation != Vector2.ZERO:
		steering += separation.normalized() * weight_separation
	if alignment != Vector2.ZERO:
		steering += alignment.normalized() * weight_alignment
	if cohesion != Vector2.ZERO:
		steering += cohesion.normalized() * weight_cohesion

	if steering == Vector2.ZERO: #if flocking has no effect
		return target_dir
	return steering.normalized()



func animate():
	if move_dir == Vector2.ZERO:
		return
	var deg := rad_to_deg(move_dir.angle())
	if deg < 0:
		deg += 360.0
	#nearest 45 degrees
	var sector := int((deg + 22.5) / 45.0) % 8
	$Sprite2D.flip_h = false
	$Sprite2D.flip_v = false
	$Sprite2D.rotation_degrees = 0.0

	match sector:
		6:  # Up
			$AnimationPlayer.play("Straight")
		2:  # Down
			$AnimationPlayer.play("Straight")
			$Sprite2D.flip_v = true
		4:  # Left
			$AnimationPlayer.play("Straight")
			$Sprite2D.rotation_degrees = -90.0
		0:  # Right
			$AnimationPlayer.play("Straight")
			$Sprite2D.rotation_degrees = 90.0
		5:  # Up-left
			$AnimationPlayer.play("Diagonal")
		7:  # Up-right
			$AnimationPlayer.play("Diagonal")
			$Sprite2D.flip_h = true
		3:  # Down-left
			$AnimationPlayer.play("Diagonal")
			$Sprite2D.flip_v = true
		1:  # Down-right
			$AnimationPlayer.play("Diagonal")
			$Sprite2D.flip_h = true
			$Sprite2D.flip_v = true
	$AnimationPlayer.speed_scale = velocity.length() / Vector2(swim_speed.x, 0.0).length()

### SIGNALS ###

func _on_StateTimer_timeout():
	match state:
		"swim":
			change_state("wait")
		"wait":
			if just_hit_wall:
				target_dir = wall_normal.rotated(randf_range(-PI / 6.0, PI / 6.0))
				just_hit_wall = false
			else:
				target_dir = Vector2.RIGHT.rotated(randf_range(0, TAU)) #random direction
			change_state("swim")

func _on_ScatterTimer_timeout():
	target_dir = move_dir if move_dir != Vector2.ZERO \
		else Vector2.RIGHT.rotated(randf_range(0, TAU))
	$ScatterToFlockCooldownTimer.start(scatter_to_flock_cooldown_duration)
	change_state("swim")

func _on_WorldDetector_body_entered(_body: Node2D):
	if state == "swim" || state == "flock":
		just_hit_wall = true
		wall_normal = $MoveCast.get_collision_normal()
		change_state("wait")


func _on_FlockTimer_timeout():
	var neighbors = _get_flock_neighbors()
	if neighbors.size() == 0: # leave flock
		change_state("swim")
		return

	target_dir = _calc_flock_direction(neighbors)
	$FlockTimer.start(flock_check_time)


func _on_ThreatDetector_body_entered(body: Node2D):
	#ignore self and tadpoles
	if body == self: return
	if body.is_in_group("Tadpoles"): return
	if not threats.has(body):
		threats.append(body)


func _on_ThreatDetector_body_exited(body: Node2D):
	threats.erase(body)
