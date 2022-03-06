tool
extends EditorPlugin

const ConfigManager = preload("./editor/config_manager.gd")
var config_manager = ConfigManager.new()
signal selection_changed(node)
var eds = get_editor_interface().get_selection()
const ToolbarView = preload("./editor/toolbar/TilesetAdditions.tscn")
const TilemapLoader = preload("./map_tools/TilemapLoader.gd")
var toolBarView:Control

var tiledmapInspector

func _enter_tree():
	config_manager.init_config()
	
	toolBarView = ToolbarView.instance()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,toolBarView)
	toolBarView.init(self,eds)
	
	add_custom_type("Tiled Map","Node2D",TilemapLoader,preload("./tiled.png"))
	
	tiledmapInspector = preload("res://addons/frontrider.tiledtools/editor/inspector/TiledmapInspectorPlugin.gd").new()
	tiledmapInspector.config_manager = config_manager
	add_inspector_plugin(tiledmapInspector)


func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,toolBarView)
	toolBarView.queue_free()
	remove_inspector_plugin(tiledmapInspector)

