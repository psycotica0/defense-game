extends StaticBody

onready var activeLight = $Spatial/ActiveLight
onready var inactiveLight = $Spatial/InactiveLight
onready var strainedLight = $Spatial/StrainedLight

var circuit
var source

const demand = 10

func _ready():
	turnOff()

func changeCircuit(newCircuit):
	var oldCircuit = circuit
	circuit = newCircuit
	if circuit:
		circuit.connect("power_updated", self, "circuitPowerChanged")
		circuit.addSink(self)
	else:
		turnOff()
		if oldCircuit:
			oldCircuit.disconnect("power_updated", self, "circuitPowerChanged")
			oldCircuit.removeSink(self)
	
	$Health.changeCircuit(circuit)

func fullPower():
	activeLight.visible = true
	inactiveLight.visible = false
	strainedLight.visible = false

func lowPower():
	activeLight.visible = false
	inactiveLight.visible = false
	strainedLight.visible = true

func turnOff():
	activeLight.visible = false
	inactiveLight.visible = true
	strainedLight.visible = false

func circuitPowerChanged(s_circuit, power):
	# I don't know how async signals are, so I'll make sure nothing changed here
	if circuit == s_circuit:
		if power > 0:
			fullPower()
		elif circuit.capacity == 0:
			turnOff()
		else:
			lowPower()


func _on_Health_dead():
	if source:
		# Tell our wire to get rid of us
		source.removeDependent()
