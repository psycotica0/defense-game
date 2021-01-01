extends KinematicBody

onready var scanner = $Scanner

enum State {
	SCANNING,   # This is when it's wandering and looking for a nice place to walk next
	WALKING,    # This is when it's wandering and it has a place it's trying to get
	CHASING,    # This is when it sees a target and it's trying to get to it
	HUNTING,    # This is when it had a target but lost it, and is going to the last place it saw it
	LOOKING,    # This is when it's done hunting, and is seeing if the target is around
}

var currentState

var pointsToScan = []
var walkOptions = []
const SCAN_DIMENSION = 5
const WALK_SPEED = 2
const TURN_RAD_PER_SEC = deg2rad(90)
const RAD_EPSILON = deg2rad(5)
const LOOK_ANGLE = deg2rad(70)

var rand = RandomNumberGenerator.new()
var currentDestination
var currentTarget
var look1
var look2
var lookState

func _ready():
	changeState(State.SCANNING)
	rand.randomize()

func changeState(newState):
	if newState == currentState:
		return
	
	prints("State is", State.keys()[newState])
	
	match newState:
		State.SCANNING:
			currentTarget = null
			for x in range(-SCAN_DIMENSION, SCAN_DIMENSION):
				for z in range(-SCAN_DIMENSION, SCAN_DIMENSION):
					pointsToScan.push_back(Vector3(x, 0, z) * 10)
			walkOptions.clear()
		State.WALKING:
			currentTarget = null
			var idx = rand.randi_range(0, walkOptions.size() - 1)
			currentDestination = walkOptions[idx] * 10 + Vector3(5, global_transform.origin.y, 5)
		State.CHASING:
			# If I add more state here about the current target
			# I may want to look at the logic for changing targets mid-chase
			currentDestination = null
			walkOptions.clear()
			pointsToScan.clear()
		State.HUNTING:
			# Technically the target is currently out of sight by the time we move to hunting
			# But structurally I like this better than keeping track all along
			# It feels nicer to have this value set here in the state transformation
			# Besides, it will have been a fraction of a second since I left
			# How far could I have gotten
			currentDestination = currentTarget.global_transform.origin
			currentTarget = null
		State.LOOKING:
			currentTarget = null
			currentDestination = null
			if rand.randi_range(0, 1) == 0:
				look1 = LOOK_ANGLE
				look2 = -LOOK_ANGLE
			else:
				look1 = -LOOK_ANGLE
				look2 = LOOK_ANGLE
			lookState = 1
	
	currentState = newState

func _physics_process(delta):
	match currentState:
		State.SCANNING:
			process_scanning(delta)
		State.WALKING:
			process_walking(delta)
		State.CHASING:
			process_chasing(delta)
		State.HUNTING:
			process_hunting(delta)
		State.LOOKING:
			process_looking(delta)
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

func process_walking(delta):
	# This returns true if we're "there"
	# If we've reached our destination, then scan for another one
	if walkTowards(delta, currentDestination, 1.0):
		changeState(State.SCANNING)

func walkTowards(delta, point, speedFactor):
	var vect = point - global_transform.origin
	
	# Eventually I'll probably want some kind of "stuck" detection
	if vect.length_squared() < 1:
		return true
	
	# As of 3.2 Vector3 doesn't have the ability to get a signed angle between things
	# So instead we make 2D versions and use that
	var relative = to_local(point)
	var relative2d = Vector2(relative.x, relative.z)
	var angle = Vector2(0, 1).angle_to(relative2d)
	
	if -RAD_EPSILON < angle and angle < RAD_EPSILON:
		move_and_slide(vect.normalized() * WALK_SPEED * speedFactor)
	elif angle < 0:
		rotate_y(TURN_RAD_PER_SEC * speedFactor * delta)
	else:
		rotate_y(-TURN_RAD_PER_SEC * speedFactor * delta)
	
	return false

func process_chasing(delta):
	walkTowards(delta, currentTarget.global_transform.origin, 2.0)

func process_hunting(delta):
	if walkTowards(delta, currentDestination, 2.0):
		changeState(State.LOOKING)

func process_looking(delta):
	var angle = 1.0 * TURN_RAD_PER_SEC * delta
	match(lookState):
		1:
			if look1 < -RAD_EPSILON:
				look1 += angle
				look2 += angle
				rotate_y(-angle)
			elif look1 < 0:
				# look1 is negative, but we're within epsilon
				lookState = 2
			elif look1 > RAD_EPSILON:
				look1 -= angle
				look2 -= angle
				rotate_y(angle)
			else:
				# look1 is positive, but we're within epsilon
				lookState = 2
		2:
			if look2 < -RAD_EPSILON:
				look1 += angle
				look2 += angle
				rotate_y(-angle)
			elif look2 < 0:
				# look2 is negative, but we're within epsilon
				# If we saw something, it would already have pulled us into chasing
				# So we must have seen nothing
				changeState(State.SCANNING)
			elif look2 > RAD_EPSILON:
				look1 -= angle
				look2 -= angle
				rotate_y(angle)
			else:
				# look2 is positive, but we're within epsilon
				# If we saw something, it would already have pulled us into chasing
				# So we must have seen nothing
				changeState(State.SCANNING)

func _on_Vision_vision_entered(body):
	if not currentTarget:
		currentTarget = body
		changeState(State.CHASING)

func _on_Vision_vision_exited(body):
	if body == currentTarget:
		if $Vision.visibleBodies().empty():
			changeState(State.HUNTING)
		else:
			currentTarget = $Vision.visibleBodies().front()
