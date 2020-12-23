extends Spatial

var circuit
var source
const capacity = 100

func _ready():
	# I want to be able to place these in the editor
	# But in reality it needs to be a dependent of a wire
	# That nees to live in a global array
	# So instead we've got this bootstrap which kills us and makes a real one
	if get_parent().has_method("initializeGenerator"):
		get_parent().call_deferred("initializeGenerator", self)

func changeCircuit(newCircuit):
	var oldCircuit = circuit
	circuit = newCircuit
	if circuit:
		activate()
	else:
		deactivate(oldCircuit)

func activate():
	circuit.addSource(self)

func deactivate(oldCircuit):
	oldCircuit.removeSource(self)
