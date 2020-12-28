extends Spatial

var source

const shieldScene = preload("res://Shield.tscn")

onready var shieldStart = $ShieldStart

var shield

var extentsFound = false

func _ready():
	# Figure out what area we're filling
	shield = shieldScene.instance()
	shield.transform.origin = global_transform.origin
	get_tree().root.add_child(shield)

func changeCircuit(newCircuit):
	pass
