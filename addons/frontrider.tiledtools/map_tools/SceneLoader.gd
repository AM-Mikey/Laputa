tool
extends Node

# Extend this to create a scene loader
# to load scenes from object layers.
# add the created node as a child to the tiled map node.

#use the "type" tag of the object to check if this node needs to build it.
func is_type(type:String):
	return false
	pass

#you recieve the properties of the object as a 
func load_scene(data:Dictionary)->Node:
	return Node.new()
	pass
