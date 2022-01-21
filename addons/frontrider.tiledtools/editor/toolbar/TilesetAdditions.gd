tool
extends Control

const TilemapLoader = preload("res://addons/frontrider.tiledtools/map_tools/TilemapLoader.gd")
const TileSetLoader = preload("res://addons/frontrider.tiledtools/loader/TilesetLoader.gd")

var editor_plugin
var eds 
var selected_node:TilemapLoader


onready var menu = $MenuButton


var tile_set_loader:TileSetLoader
# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	var popup = menu.get_popup()
	popup.connect("index_pressed",self,"_item_activated")
	tile_set_loader = TileSetLoader.new()
	pass

func init(plugin,eds):
	editor_plugin = plugin
	self.eds = eds
	eds.connect("selection_changed",self,"_selection_changed")
	pass

func _selection_changed():
	# Returns an array of selected nodes
	var selected = eds.get_selected_nodes()
	#we only select 1 node, any other case is invalid.
	if selected.size() ==1:
		visible = selected[0] is TilemapLoader
		if visible:
			selected_node = selected[0]
	pass

func _item_activated(index):
	match index:
		0:
			print("exporting tileset")
			$ExportFileDialog.show()
			pass
		1:
			print("importing tileset")
			$ImportFileDialog.show()
			pass
		3:
			print("rendering map")
			selected_node.clear_level()
			selected_node.open_level()
			pass
		4:
			print("cleaning map")
			selected_node.clear_level()
			pass
	pass


func _on_ImportFileDialog_file_selected(path):
	var tileset_folder = editor_plugin.config_manager.get_tileset_folder()
	
	if not path.begins_with("res://"):
		$tilesetImportError.popup()
		return
	
	tile_set_loader.import_tileset(path,tileset_folder)
	
	pass # Replace with function body.


func _on_ExportFileDialog_file_selected(path:String):
	
	var path_parts = path.split("/")
	path_parts.invert()
	#remove the suffix from the last segment of the path
	var file_name = path_parts[0].split(".")[0]
	
	var tileset:TileSet = selected_node.tileset
	var size = selected_node.tile_size
	
	
	var columns = 16
	if(tileset.get_tiles_ids().size()<16):
		columns = tileset.get_tiles_ids().size()
		pass
	
	var image = tile_set_loader.get_tileset_image(tileset,size,columns)
	var tiledTileset = tile_set_loader.get_tileset_dict(tileset,file_name,size,columns,image,selected_node.tileset_properties)
	
	image.save_png(path.trim_suffix(".json")+".png")
	var json_tileset = to_json(tiledTileset)
	
	var tileset_file = File.new()
	tileset_file.open(path, File.WRITE)
	tileset_file.store_line(json_tileset)
	tileset_file.close()
	
	pass # Replace with function body.
