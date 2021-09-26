extends Spatial
class_name Blueprint

var position

const OFFSET = Vector3(0, 0, 0)

class CircuitManager:
	var circuit = Circuit.new()
	
	func newCircuit():
		return circuit
	
	func merge(_c1, _c2):
		pass
	
	func splitCircuits(_cs):
		pass

const Wire = preload("res://Wires.tscn")

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
	
	func buildGhost(wire, manager):
		var ghost = Wire.instance()
		ghost.circuitManager = manager
		for leg in wire.legConnectivity.keys():
			if wire.legs[leg] == wire.LegState.COMMITTED:
				ghost.legs[leg] = wire.LegState.COMMITTED
		
		return ghost
	
	func setDependent(wire):
		if dependent:
			wire.setDependent(dependent, dependent_direction)

var allWires = []
var ghosts = []
var circuitManager = CircuitManager.new()

func ofWires(wires):
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
		
		var ghost = proto.buildGhost(w, circuitManager)
		add_child(ghost)
		ghost.setPosition(proto.position, proto.normal)
		ghost.select()
		proto.setDependent(ghost)
	
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

func setPosition(pos, _normal):
	position = pos
	# normal = norm
	var tile_position = pos * 10 + OFFSET
	translation = tile_position
