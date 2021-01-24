extends Spatial

var circuit
var source

const demand = 10

enum State {ON, OFF}
var currentState = State.OFF

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

func changeState(newState):
	if newState == currentState:
		return
	
	currentState = newState
	match currentState:
		State.OFF:
			for t in getCoveredTiles():
				var tile = Globals.currentLevel.tileState[t]
				tile.beacons.erase(self)
		State.ON:
			for t in getCoveredTiles():
				var tile = Globals.currentLevel.tileState[t]
				if not tile.beacons.has(self):
					tile.beacons.push_back(self)
	
	Globals.currentLevel.updateSpawnLocations()

func turnOff():
	changeState(State.OFF)

func fullPower():
	changeState(State.ON)

func lowPower():
	turnOff()

func circuitPowerChanged(s_circuit, power):
	# I don't know how async signals are, so I'll make sure nothing changed here
	if circuit == s_circuit:
		if power > 0:
			fullPower()
		elif circuit.capacity == 0:
			turnOff()
		else:
			lowPower()

func getCoveredTiles():
	var soFar = []
	var thisRound = [source.tileState.position]
	
	for f in range(0, 5):
		var nextRound = []
		for t in thisRound:
			# Grab all the tiles around this one
			for x in [-1, 0, 1]:
				for z in [-1, 0, 1]:
					var vect = t + Vector3(x, 0, z)
					if not soFar.has(vect) and not thisRound.has(vect) and not nextRound.has(vect):
						if Globals.currentLevel.tileState.has(vect):
							nextRound.push_back(vect)
		
		soFar += thisRound
		thisRound = nextRound
	
	return soFar

func _on_Health_dead():
	if source:
		# Tell our wire to get rid of us
		source.removeDependent()


func _ready():
	changeState(State.OFF)
