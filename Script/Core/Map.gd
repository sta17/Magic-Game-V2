@icon("res://Assets/Icons/Pixel-Boy/color/icon_map_2.png")
extends Node3D

@export var spawn_points:Dictionary[String,Vector3]
@export var Area_Display_Name:Dictionary[String,String]

func get_spawn_point(spawn_point_key:String="")-> Vector3:
	if spawn_points.size() == 1:
		return spawn_points[spawn_points.keys()[0]]
	else:
		return spawn_points[spawn_point_key]
