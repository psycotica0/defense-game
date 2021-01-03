extends Spatial

const SCAN_RPM = 60.0 / 5.0

onready var barrelCast = $"Gun Holder/BarrelCast"
onready var aboveCast = $"Gun Holder/AboveCast"
onready var topCast = $"Gun Holder/TopCast"
onready var belowCast = $"Gun Holder/BelowCast"

var scanOrder = []

onready var gunHolder = $"Gun Holder"
onready var happyLaser = $"Gun Holder/Barrel/Laser"
onready var sadLaser = $"Gun Holder/Barrel/SadLaser"
onready var heat = $Heat
onready var laser = sadLaser

var source
var circuit

const BASE_DEMAND = 15
const FIRING_DEMAND = 5 # This is on top of base

var demand = 15

var currentTarget
var currentState = State.OFF

var heatRate = 30

enum State {OFF, SCANNING, TARGETTING, FIRING, VENTING}

func _ready():
	scanOrder = [barrelCast, aboveCast, belowCast, topCast]
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
	match newState:
		State.OFF, State.VENTING:
			laser.visible = false
			currentTarget = null
			gunHolder.rotation.x = deg2rad(-20)
			updateDemand(BASE_DEMAND)
			for ray in scanOrder:
				ray.enabled = false
		State.SCANNING:
			laser.visible = false
			currentTarget = null
			gunHolder.rotation.x = 0
			updateDemand(BASE_DEMAND)
			for ray in scanOrder:
				ray.enabled = true
		State.TARGETTING, State.FIRING:
			laser.visible = false
			updateDemand(BASE_DEMAND + FIRING_DEMAND)
			for ray in scanOrder:
				ray.enabled = true
	currentState = newState

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
		State.TARGETTING:
			processTargetting(delta)
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
	elif barrelCast.get_collider() != currentTarget:
		changeState(State.TARGETTING)
	else:
		# Keep us pointed at the center of our target
		gunHolder.look_at(currentTarget.getAimTarget(), -source.normal)
		var distance = gunHolder.global_transform.origin.distance_to(currentTarget.getAimTarget())
		laser.visible = true
		laser.mesh.height = distance
		laser.translation.y = -(distance / 2) + 2.5
		heat.heat(heatRate * delta)

func processVenting(_delta):
	# We cool down in all states, so there's nothing to do here but wait
	pass

func processTargetting(_delta):
	if not currentTarget:
		changeState(State.SCANNING)
	elif barrelCast.get_collider() == currentTarget:
		changeState(State.FIRING)
	else:
		var targetted = false
		for ray in scanOrder:
			if ray.get_collider() == currentTarget:
				gunHolder.look_at(currentTarget.getAimTarget(), -source.normal)
				targetted = true
				break
		if not targetted:
			changeState(State.SCANNING)

func updateDemand(newDemand):
	if newDemand == demand:
		return
	
	demand = newDemand
	if circuit:
		circuit.call_deferred("updateDemand")

func processScanning(delta):
	for ray in scanOrder:
		var obj = ray.get_collider()
		if obj and obj.has_method("getAimTarget"):
			currentTarget = obj
			changeState(State.TARGETTING)
			return
	
	# Continue to scan
	gunHolder.rotate_y((SCAN_RPM / 60.0) * TAU * delta)

func _on_Heat_state_change(state):
	if state == Heat.State.VENTING:
		changeState(State.VENTING)
	elif currentState == State.VENTING:
		changeState(State.FIRING)
