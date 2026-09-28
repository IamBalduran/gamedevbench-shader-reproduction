extends MarginContainer
class_name Minimap

@export var player: Player
@export var zoom = 1.5:
	set = set_zoom

@onready var grid = $Content/Grid
@onready var player_marker = $Content/Grid/PlayerMarker
@onready var mob_marker = $Content/Grid/MobMarker
@onready var alert_marker = $Content/Grid/AlertMarker

@onready var icons = {
	"mob": mob_marker,
	"alert": alert_marker
}

var grid_scale
var markers = {}

func _ready():
	pass

func _process(delta):
	pass
		
func _on_object_removed(object):
	pass

func set_zoom(value):
	pass

func _on_gui_input(event):
	pass