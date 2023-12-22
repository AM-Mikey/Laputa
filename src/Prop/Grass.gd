extends Prop

const HEART = preload("res://src/Actor/Pickup/Heart.tscn")
const EXPERIENCE = preload("res://src/Actor/Pickup/Experience.tscn")
const AMMO = preload("res://src/Actor/Pickup/Ammo.tscn")

@export var drop_chance = 0.1
@export var heart_chance = 1
@export var experience_chance = 1
@export var ammo_chance = 1
var rng = RandomNumberGenerator.new()

var one = load("res://assets/Prop/Grass/Grass1.png")
var two = load("res://assets/Prop/Grass/Grass2.png")
var three = load("res://assets/Prop/Grass/Grass3.png")
var four = load("res://assets/Prop/Grass/Grass4.png")

var num = 1
var palette = "village"
var broken = false

var wind_time = 2.4

@onready var player_actor = get_tree().get_root().get_node_or_null("World/Juniper")

func _ready():
	$WindTimer.start(wind_time)
	$AnimationPlayer.play("Wind")
	
	match palette:
		null: 
			one = load("res://assets/Prop/Grass/Grass1.png")
			two = load("res://assets/Prop/Grass/Grass2.png")
			three = load("res://assets/Prop/Grass/Grass3.png")
			four = load("res://assets/Prop/Grass/Grass4.png")
		"village":
			one = load("res://assets/Prop/Grass/Village1.png")
			two = load("res://assets/Prop/Grass/Village2.png")
			three = load("res://assets/Prop/Grass/Village3.png")
			four = load("res://assets/Prop/Grass/Village4.png")
			
	
	match num:
		1: $Sprite2D.texture = one
		2: $Sprite2D.texture = two
		3: $Sprite2D.texture = three
		4: $Sprite2D.texture = four
	


func _on_PlayerDetector_body_entered(_body):
	if not broken:
		$AnimationPlayer.play("Rustle")
	

func _on_PlayerDetector_body_exited(_body):
	if not broken:
		$AnimationPlayer.play("Unrustle")



func _on_WindTimer_timeout():
	if not broken:
		$WindTimer.start(wind_time)
		
		if not $AnimationPlayer.is_playing():
			$AnimationPlayer.play("Wind")




func on_break(method):
	if not broken:
		broken = true
		if method == "fire":
			#$AnimationPlayer.play("Burn")
			$AnimationPlayer.play("Cut")
			$BreakSound.play()
			do_break_drop()
		else:
			$AnimationPlayer.play("Cut")
			$BreakSound.play()
			do_break_drop()


func do_break_drop():
	var heart = HEART.instantiate()
	var experience = EXPERIENCE.instantiate()
	var ammo = AMMO.instantiate()
	
	rng.randomize()
	if drop_chance >= rng.randf():
		print("grass dropped item")
		
		var player_needs_ammo = false
		if player_actor == null:
			player_actor = get_tree().get_root().get_node_or_null("World/Juniper")
		for g in player_actor.get_node("GunManager/Guns").get_children():
			if g.ammo < g.max_ammo:
				player_needs_ammo = true
	
		if not player_needs_ammo:
			ammo_chance = 0
		

		var total_chance = heart_chance + experience_chance + ammo_chance
		rng.randomize()
		var drop = rng.randf_range(0, total_chance)
		
		if drop <= heart_chance:
			heart.position = position
			heart.value = 2
			get_tree().get_root().get_node("World/Middle").add_child(heart)
		
		elif drop > heart_chance and drop <= heart_chance + experience_chance:
			experience.position = position
			experience.value = 1
			get_tree().get_root().get_node("World/Middle").add_child(experience)

		else:
			ammo.position = position
			ammo.value = 0.2
			get_tree().get_root().get_node("World/Middle").add_child(ammo)
