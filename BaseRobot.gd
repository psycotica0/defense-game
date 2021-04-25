extends KinematicBody

# Borrowed from https://www.youtube.com/watch?v=_urHlep2P84

var path = []
var path_ind = 0
const move_speed = 5
onready var nav = get_parent()

enum STATE {DEPLOYED, PACKING, PACKED, MOVING, DEPLOYING}

var state = STATE.PACKED

func _ready():
	pass
	#add_to_group("units")
 
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
			else:
				changeState(STATE.DEPLOYING)
		STATE.MOVING:
			process_moving(delta)
	
func process_moving(delta):
	if path_ind < path.size():
		var move_vec = (path[path_ind] - global_transform.origin)
		if move_vec.length() < 0.1:
			path_ind += 1
		else:
			move_and_slide(move_vec.normalized() * move_speed, Vector3(0, 1, 0))
	else:
		changeState(STATE.DEPLOYING)
 
func move_to(target_pos):
	path = nav.get_simple_path(global_transform.origin, target_pos)
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
