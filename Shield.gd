extends Spatial

onready var template = $Template
onready var target = $RealShield

const STRENGTH = 3

var emitters = []

func _ready():
	remove_child(template)
	spreadShield()

func spreadShield():
	# Remove Existing Children
	for child in target.get_children():
		target.remove_child(child)
		child.queue_free()
	
	# Add a new child at each emitter
	for emitter in emitters:
		makePiece(to_local(emitter.shieldSpawn.global_transform.origin), STRENGTH)
	
	# Then for each child extend it if there's room
	for i in range(1, STRENGTH):
		for child in target.get_children():
			var neigh = child.getNeighbours()
			if not neigh[ShieldPiece.Spot.POSZ]:
				makePiece(child.transform.origin + Vector3(0, 0, 10), STRENGTH - i)
			if not neigh[ShieldPiece.Spot.NEGZ]:
				makePiece(child.transform.origin + Vector3(0, 0, -10), STRENGTH - i)
			if not neigh[ShieldPiece.Spot.POSX]:
				makePiece(child.transform.origin + Vector3(10, 0, 0), STRENGTH - i)
			if not neigh[ShieldPiece.Spot.NEGX]:
				makePiece(child.transform.origin + Vector3(-10, 0, 0), STRENGTH - i)

func makePiece(position, strength):
	var newOne = template.duplicate()
	newOne.shield = self
	newOne.transform.origin = position
	newOne.strength = strength
	target.add_child(newOne)

func addEmitter(emitter):
	if not emitters.has(emitter):
		emitters.push_back(emitter)
