extends Spatial

const SCAN_RPM = 60.0 / 5.0

onready var barrelCast = $"Gun Holder/BarrelCast"
onready var aboveCast = $"Gun Holder/AboveCast"
onready var topCast = $"Gun Holder/TopCast"
onready var belowCast = $"Gun Holder/BelowCast"

var scanOrder = []

onready var gunHolder = $"Gun Holder"
onready var laser = $"Gun Holder/Barrel/Laser"

var source
var circuit
var demand = 15

var currentTarget
var currentState = State.OFF

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
	else:
		changeState(State.OFF)
		if oldCircuit:
			oldCircuit.disconnect("power_updated", self, "circuitPowerChanged")
			oldCircuit.removeSink(self)

func changeState(newState):
	match newState:
		State.OFF, State.VENTING:
			laser.visible = false
			currentTarget = null
			gunHolder.rotation.x = deg2rad(-20)
			for ray in scanOrder:
				ray.enabled = false
		State.SCANNING:
			laser.visible = false
			currentTarget = null
			gunHolder.rotation.x = 0
			for ray in scanOrder:
				ray.enabled = true
		State.TARGETTING, State.FIRING:
			laser.visible = false
			for ray in scanOrder:
				ray.enabled = true
	currentState = newState

func circuitPowerChanged(s_circuit, power):
	if s_circuit == circuit:
		if circuit.capacity == 0:
			changeState(State.OFF)
		elif currentState == State.OFF:
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
			pass

func processFiring(delta):
	if not currentTarget:
		changeState(State.SCANNING)
	elif barrelCast.get_collider() != currentTarget:
		changeState(State.TARGETTING)
	else:
		# Keep us pointed at the center of our target
		gunHolder.look_at(currentTarget.getAimTarget(), -source.normal)
		laser.visible = true

func processTargetting(delta):
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

func processScanning(delta):
	for ray in scanOrder:
		var obj = ray.get_collider()
		if obj and obj.has_method("getAimTarget"):
			currentTarget = obj
			changeState(State.TARGETTING)
			return
	
	# Continue to scan
	gunHolder.rotate_y((SCAN_RPM / 60.0) * TAU * delta)