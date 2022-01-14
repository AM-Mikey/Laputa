tool
extends EditorPlugin

var icon = preload("./icon.png")

var edi
var interface
var control_added = false

func _enter_tree():
	edi = get_editor_interface()
	interface = preload("./Interface.tscn").instance()
	interface.connect("file_created",self,"_on_file_created")
	add_custom_type("AutotileGenerator","Node2D",preload("./AutotileGenerator.gd"),icon)
	

func _exit_tree():
	remove_custom_type("AutotileGenerator")
	if control_added:
		remove_control_from_docks(interface)
	interface.free()

func _on_file_created():
	get_editor_interface().get_resource_filesystem().scan()
	
func _process(delta):
	if !edi:
		return
	var nodes = edi.get_selection().get_selected_nodes()

	if nodes:
		var node = nodes[0]
		if node is AutotileGenerator:
			if !control_added:
				control_added = true
				add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, interface)
				interface.setup(node)
		else:
			if control_added:
				remove_control_from_docks(interface)
				control_added = false
