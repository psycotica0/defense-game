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
	var ghost
	
	func fromWire(wire):
		position = wire.position
		normal = wire.normal
		
		if wire.dependent_class:
			dependent = wire.dependent_class
			dependent_direction = wire.dependent_direction
	
	func buildGhost(wire, manager):
		ghost = Wire.instance()
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
	var centerOfMass = Vector3.ZERO
	var toPrototype = {}
	for w in wires:
		centerOfMass += w.position
	
	centerOfMass /= wires.size()
	centerOfMass = centerOfMass.snapped(Vector3(1,1,1))
	for w in wires:
		var proto = WirePrototype.new()
		proto.fromWire(w)
		proto.position -= centerOfMass
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
			# There may be connections from this wire to things outside the selection
			if toPrototype.has(c):
				var other = toPrototype[c]
				if other:
					proto.connections.push_back(other)

func paste(getWire):
	var fromPrototype = {}
	for w in allWires:
		var newPosition = (w.ghost.global_transform.origin / 10).floor()
		var wire = getWire.call_func(newPosition, w.normal)
		fromPrototype[w] = wire
	
	# Connections
	for w in allWires:
		var wire = fromPrototype[w]
		for c in w.connections:
			wire.connectionProposed(fromPrototype[c], false)
	
	for w in allWires:
		fromPrototype[w].commitProposal()
	
	for w in allWires:
		w.setDependent(fromPrototype[w])

func setPosition(pos, _normal):
	position = pos
	# normal = norm
	var tile_position = pos * 10 + OFFSET
	translation = tile_position

func rotate_clockwise():
	rotate_y(-deg2rad(90))
	
func rotate_counterclockwise():
	rotate_y(deg2rad(90))
