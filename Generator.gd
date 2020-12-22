extends Spatial

var circuit
var source
const capacity = 100

func _ready():
	pass

func _on_Area_area_entered(area):
	prints("Entered Generator!", area, area.get_parent())
	source = area.get_parent()
	source.setDependent(self)

func _on_Area_area_exited(area):
	prints("Exit Generator!", area, area.get_parent())
	source = null
	changeCircuit(null)

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
