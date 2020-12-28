extends Spatial

var source

const shieldScene = preload("res://Shield.tscn")

onready var shieldSpawn = $ShieldSpawn

var shield
var direction

var extentsFound = false

func _ready():
	# Rotate ourselves so our positive Z is pointing in the way the player is facing
	look_at(global_transform.origin - direction, source.normal)
	# Figure out what area we're filling
	var point = ShieldPiece.querySpots(
		get_world(),
		[shieldSpawn.global_transform.origin])[0]
	
	if point:
		shield = point
		shield.addEmitter(self)
		shield.spreadShield()
	else:
		shield = shieldScene.instance()
		shield.transform = shieldSpawn.global_transform
		shield.addEmitter(self)
		get_tree().root.add_child(shield)
	

func setDirection(dir):
	direction = dir

func changeCircuit(newCircuit):
	pass
