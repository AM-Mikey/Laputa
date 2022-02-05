# Godot-Tiled-Tools
Godot addon for importing tiled maps into godot.

This addon is NOT set up to import the map as a scene! It includes a node that can parse an existing json tilemap, and a set of editor tools to manage tilesets between Godot and Tiled.
This is a stylistic choice, it lets me import tiledmaps at runtime. There is no tool included to import tilesets at runtime!
Another "benefit" is that the level we edit inside tiled is the single source of truth for our levels, there can be no difference between what we see in Godot and Tiled.
