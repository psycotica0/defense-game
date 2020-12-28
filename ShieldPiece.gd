extends Spatial

class_name ShieldPiece

onready var collisionBody = $StaticBody

enum Spot { # POSX, NEGX, 
	POSZ, NEGZ}

var surroundings = {
#	Spot.POSX: [],
#	Spot.NEGX: [],
	Spot.POSZ: [],
	Spot.NEGZ: [],
}

var shield
var strength = 0
var full = false

func _ready():
	prints("ready", global_transform.origin)
	pass

func recomputeFullness():
	if strength == 0:
		full = true
	else:
		var tempFull = true
		for spot in Spot:
			if surroundings[Spot[spot]].empty():
				tempFull = false
				break
		full = tempFull

func getNeighbours():
	var neighbours = {
		Spot.POSZ: null,
		Spot.NEGZ: null,
	}
	
	var space = get_world().direct_space_state
	var query = PhysicsShapeQueryParameters.new()
	var box_shape = BoxShape.new()
	box_shape.extents = Vector3(0.25, 0.25, 0.25)
	query.set_shape(box_shape)
	
	query.transform.origin = to_global(Vector3(0,0,6))
	for i in space.intersect_shape(query):
		neighbours[Spot.POSZ] = i.collider
	
	query.transform.origin = to_global(Vector3(0,0,-6))
	for i in space.intersect_shape(query):
		neighbours[Spot.NEGZ] = i.collider
	
	return neighbours

func newDirection():
	for spot in Spot:
		if surroundings[Spot[spot]].empty():
			return Spot[spot]

func thingEntered(spot, thing):
	if thing != collisionBody:
		surroundings[spot].push_back(thing)
	recomputeFullness()

func thingExited(spot, thing):
	if thing != collisionBody:
		surroundings[spot].erase(thing)
	recomputeFullness()

func _on_PosZ_area_entered(area):
	thingEntered(Spot.POSZ, area)


func _on_PosZ_area_exited(area):
	thingExited(Spot.POSZ, area)


func _on_PosZ_body_exited(body):
	thingExited(Spot.POSZ, body)


func _on_NegZ_area_entered(area):
	thingEntered(Spot.NEGZ, area)


func _on_NegZ_area_exited(area):
	thingExited(Spot.NEGZ, area)


func _on_NegZ_body_entered(body):
	thingEntered(Spot.NEGZ, body)


func _on_NegZ_body_exited(body):
	thingExited(Spot.NEGZ, body)


func _on_PosZ_body_entered(body):
	thingEntered(Spot.POSZ, body)
