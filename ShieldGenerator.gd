extends Spatial

var source

const shieldScene = preload("res://Shield.tscn")

onready var shieldStart = $ShieldStart

var shield
var direction

var extentsFound = false

func _ready():
	# Rotate ourselves so our positive Z is pointing in the way the player is facing
	look_at(global_transform.origin - direction, source.normal)
	# Figure out what area we're filling
	shield = shieldScene.instance()
	shield.transform.origin = global_transform.origin
	get_tree().root.add_child(shield)

func setDirection(dir):
	direction = dir

func changeCircuit(newCircuit):
	pass
