extends Spatial

class_name ShieldPiece

onready var collisionBody = $StaticBody

enum Spot { POSX, NEGX, POSZ, NEGZ}

var shield
var strength = 0

func _ready():
	pass

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
