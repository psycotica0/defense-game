extends KinematicBody
class_name BaseRobot

# Borrowed from https://www.youtube.com/watch?v=_urHlep2P84

var path = []
var path_ind = 0
const move_speed = 5
onready var nav = get_parent()
var target_orientation

const TURN_RAD_PER_SEC = deg2rad(90)

enum STATE {DEPLOYED, PACKING, PACKED, MOVING, DEPLOYING}

var state = STATE.PACKED

func _ready():
	changeState(STATE.DEPLOYING)
 
func _physics_process(delta):
	match state:
		STATE.PACKING, STATE.DEPLOYING:
			pass
		STATE.DEPLOYED:
			if path_ind < path.size():
				changeState(STATE.PACKING)
		STATE.PACKED:
			if path_ind < path.size():
				changeState(STATE.MOVING)
		STATE.MOVING:
			process_moving(delta)

func process_moving(delta):
	# As of 3.2 Vector3 doesn't have the ability to get a signed angle between things
	# So instead we make 2D versions and use that
	var relative
	
	# If we have a point we're going, turn towards it
	# If not, turn towards our final orientation
	if path_ind < path.size():
		relative = to_local(path[path_ind])
	else:
		relative = to_local(global_transform.origin + target_orientation)
	
	var relative2d = Vector2(relative.x, relative.z)
	var angle = Vector2(0, 1).angle_to(relative2d)

	if angle < -TURN_RAD_PER_SEC * delta:
		rotate_y(TURN_RAD_PER_SEC * delta)
	elif angle > TURN_RAD_PER_SEC * delta:
		rotate_y(-TURN_RAD_PER_SEC * delta)
	elif path_ind < path.size():
		var move_vec = (path[path_ind] - global_transform.origin)
		if move_vec.length() < 0.1:
			path_ind += 1
		else:
			move_and_slide(move_vec.normalized() * move_speed, Vector3(0, 1, 0))
	else:
		rotate_y(angle)
		changeState(STATE.DEPLOYING)

func move_to(target_pos, orientation):
	path = nav.get_simple_path(global_transform.origin, target_pos)
	target_orientation = orientation
	path_ind = 0

func changeState(new_state):
	if state == new_state:
		return
	
	state = new_state
	match state:
		STATE.DEPLOYING:
			$AnimationPlayer.play("Deploy")
		STATE.PACKING:
			$AnimationPlayer.play_backwards("Deploy")
		STATE.DEPLOYED, STATE.PACKED, STATE.MOVING:
			pass

func done_transforming(_name):
	match state:
		STATE.PACKING:
			changeState(STATE.PACKED)
		STATE.DEPLOYING:
			changeState(STATE.DEPLOYED)
		_:
			prints("Animation finished in unexpected state", self, state)
