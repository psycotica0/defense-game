extends Spatial

onready var activeLight = $Spatial/ActiveLight
onready var inactiveLight = $Spatial/InactiveLight

var circuit
var source

const demand = 10

func _ready():
	deactivate()

func changeCircuit(newCircuit):
	var oldCircuit = circuit
	circuit = newCircuit
	if circuit:
		circuit.connect("power_updated", self, "circuitPowerChanged")
		circuit.addSink(self)
	else:
		deactivate()
		if oldCircuit:
			oldCircuit.disconnect("power_updated", self, "circuitPowerChanged")
			oldCircuit.removeSink(self)

func activate():
	activeLight.visible = true
	inactiveLight.visible = false

func deactivate():
	activeLight.visible = false
	inactiveLight.visible = true

func circuitPowerChanged(s_circuit, power):
	# I don't know how async signals are, so I'll make sure nothing changed here
	if circuit == s_circuit:
		if power > 0:
			activate()
		else:
			deactivate()
