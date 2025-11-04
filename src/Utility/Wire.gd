extends Node2D
extends Path2D

func _ready():
		var points = curve.tessellate()
		$Line2D.points = points
