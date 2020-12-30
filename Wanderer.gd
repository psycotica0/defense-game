extends KinematicBody

onready var scanner = $Scanner

enum State {SCANNING, WALKING}

var currentState

var pointsToScan = []
var walkOptions = []
const SCAN_DIMENSION = 5
const WALK_SPEED = 2

var rand = RandomNumberGenerator.new()
var currentDestination

func _ready():
	changeState(State.SCANNING)
	rand.randomize()

func changeState(newState):
	if newState == currentState:
		return
	
	match newState:
		State.SCANNING:
			for x in range(-SCAN_DIMENSION, SCAN_DIMENSION):
				for z in range(-SCAN_DIMENSION, SCAN_DIMENSION):
					pointsToScan.push_back(Vector3(x, 0, z) * 10)
			walkOptions.clear()
		State.WALKING:
			var idx = rand.randi_range(0, walkOptions.size() - 1)
			currentDestination = walkOptions[idx] * 10 + Vector3(5, global_transform.origin.y, 5)
#			for w in walkOptions:
#				print(w)
#				var test = $Body.duplicate()
#				test.transform.origin = to_local(w * 10 + Vector3(5,0,5))
#				add_child(test)
	
	currentState = newState

func _physics_process(delta):
	match currentState:
		State.SCANNING:
			process_scanning(delta)
		State.WALKING:
			process_walking(delta)
	pass

func process_scanning(_delta):
	var nextScan = pointsToScan.pop_front()
	# Vector3(0,0,0) is falsey
	if nextScan != null:
		var state = get_world().direct_space_state
		# The extra 1.2x is just to make it slightly longer
		# That way it'll shoot through the floor rather than just kissing the surface
		var buffer = ((nextScan - scanner.transform.origin) * 1.2) + scanner.transform.origin
		var ray_result = state.intersect_ray(scanner.global_transform.origin, to_global(buffer), [], Globals.WALLS_LAYER)
		if ray_result:
			var pos = ray_result["position"]
			var normal = ray_result["normal"].snapped(Vector3(1, 1, 1))
			if normal == Vector3.UP:
				# This is a normalized ID for the cubes that occupy this space
				var cube_coord = (pos / 10).floor()
				walkOptions.push_back(cube_coord)
	else:
		changeState(State.WALKING)

func process_walking(_delta):
	var vect = currentDestination - global_transform.origin
	
	# Eventually I'll probably want some kind of "stuck" detection 
	if vect.length_squared() < 1:
		changeState(State.SCANNING)
		return
	
	move_and_slide(vect.normalized() * WALK_SPEED)
