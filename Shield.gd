extends Spatial

onready var template = $Template
onready var target = $RealShield

const STRENGTH = 3

func _ready():
	var newOne = template.duplicate()
	remove_child(template)
	newOne.transform.origin = Vector3(0,5,0)
	target.add_child(newOne)
	spreadShield()

func spreadShield():
	for i in range(0, STRENGTH - 1):
		print(i)
		for child in target.get_children():
			var neigh = child.getNeighbours()
			if not neigh[ShieldPiece.Spot.POSZ]:
				var newOne = template.duplicate()
				newOne.transform.origin = child.transform.origin
				newOne.translate(Vector3(0, 0, 10))
				newOne.strength = STRENGTH - i
				target.add_child(newOne)
