extends KinematicBody2D
class_name Actor, "res://assets/Icon/ActorIcon.png"

const DAMAGENUMBER = preload("res://src/Effect/DamageNumber.tscn")
const FLOOR_NORMAL: = Vector2.UP

export var speed: = Vector2(150, 350)
export var gravity: = 300
var velocity: = Vector2.ZERO
var acceleration = 50
export var ground_cof = 0.2
export var air_cof = 0.05

var dead = false
var is_in_water = false
