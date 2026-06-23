extends Node2D

const WIND_FAN = preload("res://src/Effect/WindFan.tscn")

var affected_entities := []

var wind_dir : Vector2
var speed : float #4 is about equal with gravity
var column_rect : Rect2 #in global
var effect : Node
#var disable_gravity_on_horizontal := true

func _ready():
	$BodyDetector/CollisionShape2D.shape.size = column_rect.size
	$BodyDetector/CollisionShape2D.global_position = column_rect.position + (column_rect.size / 2.0)
	effect = WIND_FAN.instantiate()
	effect.direction = wind_dir
	effect.global_position = global_position
	effect.tile_distance = (max(column_rect.size.x, column_rect.size.y) / 16.0)
	get_tree().get_root().get_node("World").middle.add_child(effect)


func _physics_process(_delta: float):
	for a in affected_entities:
		if a.is_on_floor() && (wind_dir == Vector2.DOWN || (wind_dir == Vector2.UP && speed <= 4.0)):
			return
		a.velocity += wind_dir * speed


func _on_BodyDetector_body_entered(body: Node2D):
	var target: Node
	if body.get_collision_layer_value(1): #player
		target = body.get_parent()
	elif body.get_collision_layer_value(2) || body.get_collision_layer_value(8): #enemy, npc
		if body.is_wind_affected:
			print("got one")
			target = body
	elif body.get_collision_layer_value(5):
		if body.is_in_group("PhysicsProps"):
			target = body
	if target:
		affected_entities.append(target)
		target.wind_areas_inside.append(self)


func _on_BodyDetector_body_exited(body: Node2D):
	var target: Node
	if body.get_collision_layer_value(1): #player
		target = body.get_parent()
	elif body.get_collision_layer_value(2) || body.get_collision_layer_value(8): #enemy, npc
		if body.is_wind_affected:
			target = body
	elif body.get_collision_layer_value(5):
		if body.is_in_group("PhysicsProps"):
			target = body
	if target:
		affected_entities.erase(target)
		target.wind_areas_inside.erase(self)




func _on_BodyDetector_area_entered(area: Area2D):
	var target: Node
	if area.get_collision_layer_value(11) || area.get_collision_layer_value(7) || area.get_collision_layer_value(14): #pickup, bullet or enemybull
		if area.get_parent().is_wind_affected:
			target = area.get_parent()
	if target:
		affected_entities.append(target)
		target.wind_areas_inside.append(self)

func _on_BodyDetector_area_exited(area: Area2D):
	var target: Node
	if area.get_collision_layer_value(11) || area.get_collision_layer_value(7) || area.get_collision_layer_value(14): #pickup, bullet or enemybull
		if area.get_parent().is_wind_affected:
			target = area.get_parent()
	if target:
		affected_entities.erase(target)
		target.wind_areas_inside.erase(self)
