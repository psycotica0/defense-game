extends Spatial

var position
var normal
var circuitManager
var circuit

var proposedConnections = []
var proposedDeletions = []
var connections = []
var dependent

enum SwitchState {NONE, OPEN, CLOSED}
var switchState = SwitchState.NONE

const OFFSET = Vector3(5, 5, 5)

const UP = Vector3.UP
const DOWN = Vector3.DOWN
const RIGHT = Vector3.RIGHT
const LEFT = Vector3.LEFT
const FORWARD = Vector3.FORWARD
const BACK = Vector3.BACK

enum LegState {NOTHING, PROPOSED, COMMITTED}
var legs = {
	"posZ": LegState.NOTHING,
	"negZ": LegState.NOTHING,
	"posX": LegState.NOTHING,
	"negX": LegState.NOTHING,
}

func _ready():
	$Committed/Hub.visible = false
	$Proposed/Hub.visible = false
	renderSwitchState()
	setLegVisibility()

func setPosition(pos, norm):
	position = pos
	normal = norm
	var tile_position = pos * 10 + OFFSET
	translation = tile_position
	match normal:
		UP: # This is floor. For hacky reasons, for now that means I need to move up
			translate(Vector3(0, 1, 0))
		DOWN: # Ceiling
			rotate_x(PI)
		LEFT: # This is wall
			rotate_z(PI/2)
		RIGHT:
			rotate_z(-PI/2)
		FORWARD:
			rotate_x(-PI/2)
		BACK:
			rotate_x(PI/2)

func startPropose():
	$Proposed/Hub.visible = true

func getDirection(otherWire):
	var direction = position - otherWire.position
	if direction == Vector3.ZERO:
		# If we're not going anywhere, then we should instead move towards the other tile's normal
		direction = otherWire.normal
	
	# Since these are integer values, the only way to get 2 is if it's 1 in two places.
	# 2 in one place will get me 4, because it's squared, and we don't have imaginary values
	# So I think we're ok here.
	# So if I've moved between two places that differ by 1 in two axis, then I think that's an outside corner
	if direction.length_squared() == 2.0:
		direction = -otherWire.normal
		
	match direction:
		RIGHT:
			match normal:
				UP, DOWN, BACK, FORWARD:
					return "negX"
		LEFT:
			match normal:
				UP, DOWN, BACK, FORWARD:
					return "posX"
		FORWARD:
			match normal:
				UP, LEFT, RIGHT:
					return "posZ"
				DOWN:
					return "negZ"
		BACK:
			match normal:
				UP, LEFT, RIGHT:
					return "negZ"
				DOWN:
					return "posZ"
		UP:
			match normal:
				RIGHT:
					return "posX"
				LEFT:
					return "negX"
				BACK:
					return "posZ"
				FORWARD:
					return "negZ"
		DOWN:
			match normal:
				RIGHT:
					return "negX"
				LEFT:
					return "posX"
				BACK:
					return "negZ"
				FORWARD:
					return "posZ"

func proposeConnection(otherWire):
	self.connectionProposed(otherWire)
	otherWire.connectionProposed(self)

# This is the other half of proposeConnection
# The outside tells one of use to connect to the other
# Whereas this is the two halves talking to each other as part of that
func connectionProposed(otherWire):
	var leg = getDirection(otherWire)
	
	var cnxIndex = connections.find(otherWire)
	var prpIndex = proposedConnections.find(otherWire)
	var delIndex = proposedDeletions.find(otherWire)
	
	if delIndex != -1: # Undo Delete
		proposedDeletions.remove(delIndex)
		legs[leg] = LegState.COMMITTED
	elif cnxIndex != -1: # Delete
		proposedDeletions.push_back(otherWire)
		legs[leg] = LegState.PROPOSED
	elif prpIndex != -1: # Undo Add
		proposedConnections.remove(prpIndex)
		legs[leg] = LegState.NOTHING
	else: # Add
		proposedConnections.push_back(otherWire)
		legs[leg] = LegState.PROPOSED
	
	setLegVisibility()

func changeCircuit(newCircuit):
	circuit = newCircuit
	circuit.join(self)
	if dependent:
		dependent.changeCircuit(circuit)
	
	$Cube.visible = false
	$Prism.visible = false
	$Sphere.visible = false
	$Cylinder.visible = false
	
	match posmod(circuit.identifier, 4):
		0:
			$Cube.visible = true
		1:
			$Prism.visible = true
		2:
			$Sphere.visible = true
		3:
			$Cylinder.visible = true

# This one recurses through neighbours to spread our new circuit
# It's used when there's a split to find the currently connected set
func floodCircuit(newCircuit, fromTop = false):
	match switchState:
		SwitchState.NONE, SwitchState.CLOSED:
			if circuit != newCircuit:
				changeCircuit(newCircuit)
				for c in connections:
					c.floodCircuit(newCircuit)
		SwitchState.OPEN:
			if fromTop and circuit != newCircuit:
				changeCircuit(newCircuit)

func setLegVisibility():
	$Committed/PosX.visible = legs.posX == LegState.COMMITTED
	$Committed/NegX.visible = legs.negX == LegState.COMMITTED
	$Committed/PosZ.visible = legs.posZ == LegState.COMMITTED
	$Committed/NegZ.visible = legs.negZ == LegState.COMMITTED
	
	$Proposed/PosX.visible = legs.posX == LegState.PROPOSED
	$Proposed/NegX.visible = legs.negX == LegState.PROPOSED
	$Proposed/PosZ.visible = legs.posZ == LegState.PROPOSED
	$Proposed/NegZ.visible = legs.negZ == LegState.PROPOSED

func setDependent(dep):
	dependent = dep
	if circuit:
		dependent.changeCircuit(circuit)

func renderSwitchState():
	$OpenSwitch.visible = switchState == SwitchState.OPEN
	$ClosedSwitch.visible = switchState == SwitchState.CLOSED

func commitProposal():
	$Committed/Hub.visible = true
	$Proposed/Hub.visible = false
	
	for p in proposedConnections:
		if not connections.has(p):
			legs[getDirection(p)] = LegState.COMMITTED
			connections.push_back(p)
			if p.circuit and p.circuit != circuit:
				# Our neightbour is a member of a circuit we are not
				if circuit:
					# We're already in a circuit, so this is a merge
					circuitManager.merge(circuit, p.circuit)
				else:
					# We aren't in a circuit, so just join theirs
					changeCircuit(p.circuit)
	
	proposedConnections.clear()
	
	if not circuit:
		# If at the end of the above loop, I didn't end up in any circuits, just add a new one for myself
		# It may end up getting merged right after my neighbour runs, but that's fine
		changeCircuit(circuitManager.newCircuit())
	
	# Now deletions, perhaps undoing all the work we just did
	for p in proposedDeletions:
		connections.erase(p)
		legs[getDirection(p)] = LegState.NOTHING
	
	var hadDeletions = not proposedDeletions.empty()
	proposedDeletions.clear()
	
	setLegVisibility()
	
	if hadDeletions:
		return circuit
	else:
		return null

func toggleSwitch():
	match switchState:
		SwitchState.NONE, SwitchState.CLOSED:
			switchState = SwitchState.OPEN
		SwitchState.OPEN:
			switchState = SwitchState.CLOSED
	
	renderSwitchState()
	
	if switchState == SwitchState.CLOSED:
		# We've just closed the switch, so check if we've connected stuff
		for c in connections:
			if c.circuit != circuit:
				circuitManager.merge(circuit, c.circuit)
	else:
		# We've just opened a closed switch, so split our circuit
		circuitManager.splitCircuits([circuit])
