extends Node

class_name State

@onready var sm = get_parent()
@onready var main = sm.main

@export var debug: bool = false

func state_start(prev_state: StringName):
	pass

func state_end(next_state: StringName):
	pass

func state_unhandled_input(event: InputEvent):
	pass

func state_input(event: InputEvent):
	pass

func state_process(delta: float):
	pass

func state_physics_process(delta: float):
	pass
