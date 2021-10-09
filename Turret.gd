extends StaticBody

const SCAN_RPM = 60.0 / 5.0

onready var gunHolder = $"Gun Holder"
onready var happyLaser = $"Gun Holder/Barrel/Laser"
onready var sadLaser = $"Gun Holder/Barrel/SadLaser"
onready var vision = $"Vision"
onready var heat = $Heat
onready var laser = sadLaser

var source
var circuit

const BASE_DEMAND = 15
const FIRING_DEMAND = 5 # This is on top of base
const LASER_DAMAGE = 20

var demand = 15

var currentTarget
var currentTargetHealth
var currentState = State.OFF

var heatRate = 30

enum State {OFF, SCANNING, FIRING, VENTING}

func _ready():
	changeState(State.OFF)

func changeCircuit(newCircuit):
	var oldCircuit = circuit
	circuit = newCircuit
	if circuit:
		circuit.connect("power_updated", self, "circuitPowerChanged")
		circuit.addSink(self)
		heat.changeCircuit(circuit)
	else:
		changeState(State.OFF)
		if oldCircuit:
			oldCircuit.disconnect("power_updated", self, "circuitPowerChanged")
			oldCircuit.removeSink(self)
		heat.changeCircuit(circuit)

func changeState(newState):
	currentState = newState
	match newState:
		State.OFF, State.VENTING:
			sadLaser.visible = false
			happyLaser.visible = false
			currentTarget = null
			gunHolder.rotation.x = deg2rad(-20)
			updateDemand(BASE_DEMAND)
		State.SCANNING:
			currentTarget = null
			for b in vision.visibleBodies():
				if b.has_method("getAimTarget"):
					var health = b.get_node("Health")
					if health:
						currentTargetHealth = health
					else:
						currentTargetHealth = b
					currentTarget = b
					break
			
			if currentTarget:
				changeState(State.FIRING)
			else:
				laser.visible = false
				gunHolder.rotation.x = 0
				updateDemand(BASE_DEMAND)
		State.FIRING:
			laser.visible = false
			updateDemand(BASE_DEMAND + FIRING_DEMAND)

func circuitPowerChanged(s_circuit, power):
	if s_circuit == circuit:
		if circuit.capacity == 0:
			changeState(State.OFF)
		else:
			if power > 0:
				becomeHappy()
			else:
				becomeSad()
			
			if currentState == State.OFF:
				changeState(State.SCANNING)

func _physics_process(delta):
	match currentState:
		State.OFF:
			pass
		State.SCANNING:
			processScanning(delta)
		State.FIRING:
			processFiring(delta)
		State.VENTING:
			processVenting(delta)

func becomeSad():
	happyLaser.visible = false
	laser = sadLaser
	changeState(currentState)

func becomeHappy():
	sadLaser.visible = false
	laser = happyLaser
	changeState(currentState)

func processFiring(delta):
	if not currentTarget:
		changeState(State.SCANNING)
	else:
		# Keep us pointed at the center of our target
		gunHolder.look_at(currentTarget.getAimTarget(), source.normal)
		var distance = gunHolder.global_transform.origin.distance_to(currentTarget.getAimTarget())
		laser.visible = true
		laser.mesh.height = distance
		laser.translation.y = (distance / 2) - 2.5
		heat.heat(heatRate * delta)
		currentTargetHealth.receiveDamage(LASER_DAMAGE * delta)

func processVenting(_delta):
	# We cool down in all states, so there's nothing to do here but wait
	pass

func updateDemand(newDemand):
	if newDemand == demand:
		return
	
	demand = newDemand
	if circuit:
		circuit.call_deferred("updateDemand")

func processScanning(delta):
	# Continue to scan
	gunHolder.rotate_y((SCAN_RPM / 60.0) * TAU * delta)
	var curRot = vision.rotation
	curRot.y = PI + gunHolder.rotation.y
	vision.rotation = curRot

func _on_Heat_state_change(state):
	if state == Heat.State.VENTING:
		changeState(State.VENTING)
	elif currentState == State.VENTING:
		changeState(State.SCANNING)

func _on_Vision_vision_entered(body):
	# Only target targettable things
	if not body.has_method("getAimTarget"):
		return
	
	if currentState == State.SCANNING:
		var health = body.get_node("Health")
		if health:
			currentTargetHealth = health
		else:
			currentTargetHealth = body
		currentTarget = body
		changeState(State.FIRING)

func _on_Vision_vision_exited(body):
	if body == currentTarget:
		changeState(State.SCANNING)


func _on_Health_dead():
	if source:
		# Tell our wire to get rid of us
		source.removeDependent()
