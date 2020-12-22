extends Spatial

var circuit
var source

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
	circuit = newCircuit
	if circuit:
		activate()
	else:
		deactivate()

func activate():
	pass

func deactivate():
	pass
