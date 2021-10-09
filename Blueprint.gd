extends Spatial
class_name Blueprint

var position
var normal

# This is used to figure out which way to rotate when I'm mirroring
# So if this is a floor pattern, I use the wall I just came off of to figure out
# which way to rotate to the ceiling
var lastAxis

var rotated = 0

# This counteracts the offset made by RotationOffset
# And that's there so blueprints will rotate around the middle of their anchor tile
const OFFSET = Vector3(5, 5, 5)

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
	
	func setDependent(wire, direction = null):
		if dependent:
			wire.setDependent(dependent, direction)

var allWires = []
var ghosts = []
var circuitManager = CircuitManager.new()

func ofWires(wires):
	if wires.empty():
		return
	
	var centerOfMass = Vector3.ZERO
	var toPrototype = {}
	for w in wires:
		centerOfMass += w.position
	
	centerOfMass /= wires.size()
	centerOfMass = centerOfMass
	
	var mostCentral = wires[0].position
	var anchorNormal = wires[0].normal
	for w in wires:
		if w.position.distance_to(centerOfMass) < mostCentral.distance_to(centerOfMass):
			mostCentral = w.position
			anchorNormal = w.normal
	
	normal = anchorNormal
	
	for w in wires:
		var proto = WirePrototype.new()
		proto.fromWire(w)
		proto.position -= mostCentral
		allWires.push_back(proto)
		toPrototype[w] = proto
		
		var ghost = proto.buildGhost(w, circuitManager)
		$RotationOffset.add_child(ghost)
		ghost.setPosition(proto.position, proto.normal)
		ghost.select()
		proto.setDependent(ghost, proto.dependent_direction)
	
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
	if allWires.empty():
		return
	
	var fromPrototype = {}
	for w in allWires:
		var newPosition = (w.ghost.global_transform.origin / 10).floor()
		# We can't use the ghost's transform because the wire object rotates itself
		# to align to the normal
		var newNormal = to_global(w.normal) - to_global(Vector3.ZERO)
		var wire = getWire.call_func(newPosition, newNormal)
		fromPrototype[w] = wire
	
	# Connections
	for w in allWires:
		var wire = fromPrototype[w]
		for c in w.connections:
			wire.connectionProposed(fromPrototype[c], false)
	
	for w in allWires:
		fromPrototype[w].commitProposal()
	
	for w in allWires:
		if w.dependent_direction:
			var newDirection = to_global(w.dependent_direction) - to_global(Vector3.ZERO)
			w.setDependent(fromPrototype[w], newDirection)
		else:
			w.setDependent(fromPrototype[w])

func setPosition(pos, norm):
	position = pos
	var rotation_axis = normal.cross(norm)
	rotation = Vector3.ZERO
	
	if rotation_axis != Vector3.ZERO:
		rotate_object_local(rotation_axis, deg2rad(90))
		lastAxis = rotation_axis
	elif norm != normal: # Mirror Opposite (Floor to Ceiling)
		rotate_object_local(lastAxis, deg2rad(180))
	
	rotate_object_local(normal, rotated)
		
	var tile_position = pos * 10 + OFFSET
	translation = tile_position

func rotate_clockwise():
	rotated -= deg2rad(90)
	
func rotate_counterclockwise():
	rotated += deg2rad(90)
