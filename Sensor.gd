extends Spatial

var source
var circuit
var demand = 0

var direction

enum State {
	IDLE,
	DETECTING
}
var state

var directionMapping = {
	"posX": "",
	"posZ": "",
	"negX": "",
	"negY": ""
}

func changeCircuit(_newCircuit):
	pass

func _ready():
	# Rotate ourselves so our positive Z is pointing in the way the player is facing
	look_at(global_transform.origin - direction, source.normal)
	
	match direction:
		Vector3(0,0,1):
			directionMapping["posX"] = "posX"
			directionMapping["posZ"] = "posZ"
			directionMapping["negX"] = "negX"
			directionMapping["negZ"] = "negZ"
		Vector3(0,0,-1):
			directionMapping["posX"] = "negX"
			directionMapping["posZ"] = "negZ"
			directionMapping["negX"] = "posX"
			directionMapping["negZ"] = "posZ"
		Vector3(1,0,0):
			directionMapping["posX"] = "negZ"
			directionMapping["posZ"] = "posX"
			directionMapping["negX"] = "posZ"
			directionMapping["negZ"] = "negX"
		Vector3(-1,0,0):
			directionMapping["posX"] = "posZ"
			directionMapping["posZ"] = "negX"
			directionMapping["negX"] = "negZ"
			directionMapping["negZ"] = "posX"
	
	changeState(State.IDLE)

func setDirection(dir):
	direction = dir

func changeState(newState):
	if state == newState:
		return
	
	state = newState
	
	match state:
		State.IDLE:
			$AnimationPlayer.play("Idle")
			source.setConnectivity(directionMapping["posX"], true)
			source.setConnectivity(directionMapping["negX"], false)
			source.processCircuitConnection()
		State.DETECTING:
			$AnimationPlayer.play("Detected")
			source.setConnectivity(directionMapping["posX"], false)
			source.setConnectivity(directionMapping["negX"], true)
			source.processCircuitConnection()

func _on_Vision_vision_entered(_body):
	changeState(State.DETECTING)

func _on_Vision_vision_exited(_body):
	if $Vision.visibleBodies().empty():
		changeState(State.IDLE)
	else:
		changeState(State.DETECTING)
