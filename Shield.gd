extends Spatial

onready var template = $Template
onready var target = $RealShield

const STRENGTH = 3

func _ready():
	var newOne = template.duplicate()
	remove_child(template)
	newOne.transform.origin = Vector3(0,5,0)
	target.add_child(newOne)
#	spreadShield()

func spreadShield():
	for i in range(1, STRENGTH):
		print(i)
		for child in target.get_children():
			var neigh = child.getNeighbours()
			if not neigh[ShieldPiece.Spot.POSZ]:
				var newOne = template.duplicate()
				newOne.transform.origin = child.transform.origin
				newOne.translate(Vector3(0, 0, 10))
				newOne.strength = STRENGTH - i
				target.add_child(newOne)
			if not neigh[ShieldPiece.Spot.NEGZ]:
				var newOne = template.duplicate()
				newOne.transform.origin = child.transform.origin
				newOne.translate(Vector3(0, 0, -10))
				newOne.strength = STRENGTH - i
				target.add_child(newOne)
			if not neigh[ShieldPiece.Spot.POSX]:
				var newOne = template.duplicate()
				newOne.transform.origin = child.transform.origin
				newOne.translate(Vector3(10, 0, 0))
				newOne.strength = STRENGTH - i
				target.add_child(newOne)
			if not neigh[ShieldPiece.Spot.NEGX]:
				var newOne = template.duplicate()
				newOne.transform.origin = child.transform.origin
				newOne.translate(Vector3(-10, 0, 0))
				newOne.strength = STRENGTH - i
				target.add_child(newOne)
