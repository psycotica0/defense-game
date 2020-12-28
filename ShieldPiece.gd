extends Spatial

class_name ShieldPiece

onready var collisionBody = $StaticBody

enum Spot { POSX, NEGX, POSZ, NEGZ}

var surroundings = {
	Spot.POSX: [],
	Spot.NEGX: [],
	Spot.POSZ: [],
	Spot.NEGZ: [],
}

var shield
var strength = 0
var full = false

func _ready():
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
		Spot.POSX: null,
		Spot.NEGX: null,
	}
	
	var space = get_world().direct_space_state
	var query = PhysicsShapeQueryParameters.new()
	var box_shape = BoxShape.new()
	box_shape.extents = Vector3(0.25, 0.25, 0.25)
	query.set_shape(box_shape)
	
	var points = [
		to_global(Vector3(0,0,5)),
		to_global(Vector3(0,0,-5)),
		to_global(Vector3(5,0,0)),
		to_global(Vector3(-5,0,0)),
	]
	
	var results = querySpots(get_world(), points, collisionBody)
	
	neighbours[Spot.POSZ] = results[0]
	neighbours[Spot.NEGZ] = results[1]
	neighbours[Spot.POSX] = results[2]
	neighbours[Spot.NEGX] = results[3]
	
	return neighbours

static func querySpots(world, global_points, exclude = null):
	var space = world.direct_space_state
	var query = PhysicsShapeQueryParameters.new()
	var box_shape = BoxShape.new()
	box_shape.extents = Vector3(0.25, 0.25, 0.25)
	query.set_shape(box_shape)
	
	var return_array = []
	for p in global_points:
		query.transform.origin = p
		var thing
		# Later I may want to prioritize some kind of thing over another
		# For now, though, just do the dumb thing and let it return the last thing
		for i in space.intersect_shape(query):
			if not exclude or i.collider != exclude:
				if "shield" in i.collider.get_parent():
					thing = i.collider.get_parent().shield
				else:
					thing = i.collider
		
		return_array.push_back(thing)
	
	return return_array

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
