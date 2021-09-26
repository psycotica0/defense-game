extends Object
class_name Blueprint

class WirePrototype:
	var position
	var normal
	var connections = []
	var dependent
	var dependent_direction
	
	func fromWire(wire):
		position = wire.position
		normal = wire.normal
		
		if wire.dependent_class:
			dependent = wire.dependent_class
			dependent_direction = wire.dependent_direction
	
	func setDependent(wire):
		if dependent:
			wire.setDependent(dependent, dependent_direction)

var allWires = []

func _init(wires):
	var bottomCorner = Vector3(INF, INF, INF)
	var toPrototype = {}
	for w in wires:
		bottomCorner.x = min(bottomCorner.x, w.position.x)
		bottomCorner.y = min(bottomCorner.y, w.position.y)
		bottomCorner.z = min(bottomCorner.z, w.position.z)
		
	for w in wires:
		var proto = WirePrototype.new()
		proto.fromWire(w)
		proto.position -= bottomCorner
		allWires.push_back(proto)
		toPrototype[w] = proto
	
	# Now turn connections into prototype connections
	for w in wires:
		var proto = toPrototype[w]
		for c in w.connections:
			var other = toPrototype[c]
			if other:
				proto.connections.push_back(other)

func paste(location, getWire):
	var fromPrototype = {}
	for w in allWires:
		var newPosition = w.position + location
		var wire = getWire.call_func(newPosition, w.normal)
		fromPrototype[w] = wire
	
	# Connections
	for w in allWires:
		var wire = fromPrototype[w]
		for c in w.connections:
			wire.connectionProposed(fromPrototype[c])
	
	for w in allWires:
		fromPrototype[w].commitProposal()
	
	for w in allWires:
		w.setDependent(fromPrototype[w])
