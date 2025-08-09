extends Node2D


var player_targets = []
var enemy_targets = []
var bullet_targets = []

@export var speed = Vector2(5, 5)
@export var dir = Vector2.LEFT

@export var active_time = 5.0
@export var wait_time = 5.0

var active = false

func _ready():
	pass


func _physics_process(delta):
	if $Timer.time_left == 0:
		if active:
			active = false
			$Timer.start(wait_time)
			fade_out()
			$ColorRect.visible = false
		elif not active:
			active = true
			$Timer.start(active_time)
			$WindSound.play()
			$ColorRect.visible = true
	
	remove_invalid_targets()
	if active:
		add_windvelocity()

func remove_invalid_targets():
	for p in player_targets:
		if p == null: 
			player_targets.erase(p)
	
	for e in enemy_targets:
		if e != null: 
			if e.dead: 
				enemy_targets.erase(e)
		else:
			enemy_targets.erase(e)
	
	for b in bullet_targets:
		if b == null:
			bullet_targets.erase(b)

func add_windvelocity():
	for p in player_targets:
		p.velocity.x += speed.x * dir.x
	for e in enemy_targets:
		e.velocity.x += speed.x * dir.x
	for b in bullet_targets:
		b.velocity.x += speed.x * dir.x


func fade_out():
	var tween = get_tree().create_tween()
	tween.tween_property($WindSound, "volume_db", -80, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	$WindSound.stop()
	$WindSound.volume_db = 0

func _on_Wind_body_entered(body):
	if body.get_collision_layer_value(1): #player
		player_targets.append(body.get_parent())
	if body.get_collision_layer_value(2): #enemy
		enemy_targets.append(body)
	if body.get_collision_layer_value(7): #bullet foe
		bullet_targets.append(body)

func _on_Wind_body_exited(body):
	if body.get_collision_layer_value(1): #player
		player_targets.erase(body.get_parent())
	if body.get_collision_layer_value(2): #enemy
		enemy_targets.erase(body)
	if body.get_collision_layer_value(7): #bullet foe
		bullet_targets.erase(body)
