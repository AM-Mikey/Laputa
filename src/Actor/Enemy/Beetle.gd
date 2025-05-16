extends Enemy

const TX_0 = preload("res://assets/Actor/Enemy/Beetle.png")
const TX_1 = preload("res://assets/Actor/Enemy/Beetle1.png")
const TX_2 = preload("res://assets/Actor/Enemy/Beetle2.png")
const TX_3 = preload("res://assets/Actor/Enemy/Beetle3.png")

@export var move_dir = Vector2.LEFT
@export var difficulty:= 0
var idle_time: float
var fly_speed = Vector2(100, 100)

func setup():
	gravity = 0
	match difficulty:
		0: 
			hp = 2
			reward = 1
			damage_on_contact = 1
			idle_time = 2.0
			$Sprite2D.texture = TX_0
			change_state("idle")
		1: 
			hp = 2
			reward = 2
			damage_on_contact = 2
			$Sprite2D.texture = TX_1
		2:
			hp = 3
			reward = 4
			damage_on_contact = 2
			$Sprite2D.texture = TX_2
		3:
			hp = 4
			reward = 5
			damage_on_contact = 4
			$Sprite2D.texture = TX_3



func _on_physics_process(_delta):
	if disabled or dead or Engine.is_editor_hint(): return
	#if not is_on_floor():
		#move_dir.y = 0 #don't allow them to jump if they are midair

	velocity = calc_velocity(velocity, move_dir, speed)
	move_and_slide()
	#animate()



### STATES ###

func enter_idle():
	print("enter idle")
	set_transform_variables()
	$Crawl.disabled = false
	$CrawlDiagonal.disabled = true
	$Fly.disabled = true
	speed = Vector2.ZERO
	$AnimationPlayer.play("Idle")
	
	await get_tree().create_timer(idle_time).timeout
	change_state("fly")

func enter_fly():
	set_transform_variables()
	print("ha")
	$Crawl.disabled = true
	$CrawlDiagonal.disabled = true
	$Fly.disabled = false
	speed = fly_speed
	$AnimationPlayer.play("Fly")
	

	#$Sprite2D.rotation_degrees = 0
	#$Sprite2D.flip_h = true if move_dir.x > 0 else false #flip if right


func do_fly():
	var collider = $RayCast2D.get_collider()
	if collider:
		move_dir.x *= -1 #flip
		print("hit wall, move dir: ", move_dir)
		change_state("idle")
		return


### HELPERS ###

func set_transform_variables():
	match state:
		"idle", "crawl":
			scale.x = -1.0 if move_dir.x > 0 else 1.0
			#rotation_degrees = 90 if move_dir.x > 0 else -90
			#scale.y = -1.0 if move_dir.y > 0 else 1.0
			print(scale.x, " scale idle")
		"fly":
			scale.x = -1.0 if move_dir.x > 0 else 1.0
			print(scale.x, " scale fly")
			#rotation_degrees = 90 if move_dir.y != 0 else 0

#func do_crawl_around_platform():
	#pass
	#

#func animate():
	
