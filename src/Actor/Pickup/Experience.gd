extends Actor

var direction
@export var bounciness: float = .75
@export var friction: float = .9
@export var minimum_speed: float = 8.0
var start_velocity

@export var rng_min_speed = Vector2(30, 60)
@export var rng_max_speed = Vector2(60, 120)

var value: int

var normal_time = 5.0
var end_time = 3.0
var state = "normal"
var did_first_frame = false
var did_second_frame = false
var just_spawned = true

func _ready():
	home = global_position
	$StateTimer.start(normal_time)
	direction = randomize_direction()
	speed = randomize_speed()
	velocity = calc_starting_velocity(speed, direction)
	match value:
		1:
			if velocity.x < 0: $AnimationPlayer.play("SmallLeft")
			else: $AnimationPlayer.play("SmallRight")
		5:
			if velocity.x < 0: $AnimationPlayer.play("MediumLeft")
			else: $AnimationPlayer.play("MediumRight")
		10:
			if velocity.x < 0: $AnimationPlayer.play("LargeLeft")
			else: $AnimationPlayer.play("LargeRight")
	await get_tree().physics_frame
	await get_tree().physics_frame
	just_spawned = false

func randomize_direction():
	rng.randomize()
	return Vector2(sign(rng.randf_range(-1.0, 1.0)), -1)

func randomize_speed():
	rng.randomize()
	return Vector2(rng.randf_range(rng_min_speed.x, rng_max_speed.x),rng.randf_range(rng_min_speed.y, rng_max_speed.y))

func _physics_process(delta):
	if !did_first_frame:
		did_first_frame = true
		return
	velocity.y += gravity * delta
	var prev_velocity = velocity
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()
		velocity = prev_velocity.bounce(normal)
		velocity *= bounciness
		velocity.x *= friction
		if abs(velocity.y) < minimum_speed: #this could cause a midair freeze
			velocity.y = 0
		if abs(velocity.x) < minimum_speed: #this could cause a midair freeze
			velocity.x = 0
		if abs(velocity.y) > minimum_speed or abs(velocity.x) > minimum_speed:
			if i == 0: #only one collision per frame
				am.play("xp", self)

	if did_first_frame and !did_second_frame:
		did_second_frame = true
		start_velocity = (abs(velocity.x) + abs(velocity.y)) #used to calculate animation slowdown

	var ave_velocity = (abs(velocity.x) + abs(velocity.y)) #used to calculate animation slowdown
	if $AnimationPlayer.current_animation == "SmallPop" or $AnimationPlayer.current_animation == "MediumPop" or $AnimationPlayer.current_animation == "LargePop":
		$AnimationPlayer.speed_scale = 1
	else:
		$AnimationPlayer.speed_scale = ave_velocity / start_velocity
		if $AnimationPlayer.speed_scale > 1:
			$AnimationPlayer.speed_scale = 1



func calc_starting_velocity(speed, dir) -> Vector2:
	var out = velocity
	out.x = speed.x * dir.x
	out.y = speed.y * dir.y
	return out


func _on_FlashTimer_timeout():
	var start_time = fposmod(snappedf($AnimationPlayer.current_animation_position, 0.001), 0.4)
	match state:
		"normal":
			match $AnimationPlayer.current_animation:
				"SmallLeft":
					animate("SmallLeftFlash", start_time)
				"SmallRight":
					animate("SmallRightFlash", start_time)
				"SmallLeftFlash":
					animate("SmallLeft", start_time)
				"SmallRightFlash":
					animate("SmallRight", start_time)
				"MediumLeft":
					animate("MediumLeftFlash", start_time)
				"MediumRight":
					animate("MediumRightFlash", start_time)
				"MediumLeftFlash":
					animate("MediumLeft", start_time)
				"MediumRightFlash":
					animate("MediumRight", start_time)
				"LargeLeft":
					animate("LargeLeftFlash", start_time)
				"LargeRight":
					animate("LargeRightFlash", start_time)
				"LargeLeftFlash":
					animate("LargeLeft", start_time)
				"LargeRightFlash":
					animate("LargeRight", start_time)
		"end":
			match $AnimationPlayer.current_animation:
				"SmallLeft":
					animate("SmallLeftFlash", start_time)
				"SmallRight":
					animate("SmallRightFlash", start_time)
				"SmallLeftFlash":
					animate("SmallLeftEnd", start_time)
				"SmallRightFlash":
					animate("SmallRightEnd", start_time)
				"SmallLeftEnd":
					animate("SmallLeftFlash", start_time)
				"SmallRightEnd":
					animate("SmallRightFlash", start_time)
				"MediumLeft":
					animate("MediumLeftFlash", start_time)
				"MediumRight":
					animate("MediumRightFlash", start_time)
				"MediumLeftFlash":
					animate("MediumLeftEnd", start_time)
				"MediumRightFlash":
					animate("MediumRightEnd", start_time)
				"MediumLeftEnd":
					animate("MediumLeftFlash", start_time)
				"MediumRightEnd":
					animate("MediumRightFlash", start_time)
				"LargeLeft":
					animate("LargeLeftFlash", start_time)
				"LargeRight":
					animate("LargeRightFlash", start_time)
				"LargeLeftFlash":
					animate("LargeLeftEnd", start_time)
				"LargeRightFlash":
					animate("LargeRightEnd", start_time)
				"LargeLeftEnd":
					animate("LargeLeftFlash", start_time)
				"LargeRightEnd":
					animate("LargeRightFlash", start_time)
		"pop":
			$AnimationPlayer.speed_scale = 1
			if $AnimationPlayer.current_animation.begins_with("Small"):
				$AnimationPlayer.play("SmallPop")
			if $AnimationPlayer.current_animation.begins_with("Medium"):
				$AnimationPlayer.play("MediumPop")
			if $AnimationPlayer.current_animation.begins_with("Large"):
				$AnimationPlayer.play("LargePop")


func animate(animation_name, start_time):
	$AnimationPlayer.play_section(animation_name, start_time)


func _on_StateTimer_timeout():
	if state == "normal":
		$StateTimer.start(end_time)
		state = "end"
	if state == "end":
		state = "pop"


func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()
