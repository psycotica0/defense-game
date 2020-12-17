extends Spatial

var position
var normal
var circuitManager
var circuit

var proposedConnections = []
var connections = []

const OFFSET = Vector3(5, 5, 5)

const UP = Vector3.UP
const DOWN = Vector3.DOWN
const RIGHT = Vector3.RIGHT
const LEFT = Vector3.LEFT
const FORWARD = Vector3.FORWARD
const BACK = Vector3.BACK

func _ready():
	$Committed/Hub.visible = false
	$Committed/PosZ.visible = false
	$Committed/NegZ.visible = false
	$Committed/PosX.visible = false
	$Committed/NegX.visible = false
	
	$Proposed/Hub.visible = false
	$Proposed/PosZ.visible = false
	$Proposed/NegZ.visible = false
	$Proposed/PosX.visible = false
	$Proposed/NegX.visible = false

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

func propose(direction, otherNormal):
	if direction == Vector3.ZERO:
		# If we're not going anywhere, then we should instead move towards the other tile's normal
		direction = otherNormal
	
	# Since these are integer values, the only way to get 2 is if it's 1 in two places.
	# 2 in one place will get me 4, because it's squared, and we don't have imaginary values
	# So I think we're ok here.
	# So if I've moved between two places that differ by 1 in two axis, then I think that's an outside corner
	if direction.length_squared() == 2.0:
		direction = -otherNormal
		
	match direction:
		RIGHT:
			match normal:
				UP, DOWN, BACK, FORWARD:
					$Proposed/NegX.visible = true
		LEFT:
			match normal:
				UP, DOWN, BACK, FORWARD:
					$Proposed/PosX.visible = true
		FORWARD:
			match normal:
				UP, LEFT, RIGHT:
					$Proposed/PosZ.visible = true
				DOWN:
					$Proposed/NegZ.visible = true
		BACK:
			match normal:
				UP, LEFT, RIGHT:
					$Proposed/NegZ.visible = true
				DOWN:
					$Proposed/PosZ.visible = true
		UP:
			match normal:
				RIGHT:
					$Proposed/PosX.visible = true
				LEFT:
					$Proposed/NegX.visible = true
				BACK:
					$Proposed/PosZ.visible = true
				FORWARD:
					$Proposed/NegZ.visible = true
		DOWN:
			match normal:
				RIGHT:
					$Proposed/NegX.visible = true
				LEFT:
					$Proposed/PosX.visible = true
				BACK:
					$Proposed/NegZ.visible = true
				FORWARD:
					$Proposed/PosZ.visible = true

func proposeConnection(otherWire):
	self.connectionProposed(otherWire)
	otherWire.connectionProposed(self)

# This is the other half of proposeConnection
# The outside tells one of use to connect to the other
# Whereas this is the two halves talking to each other as part of that
func connectionProposed(otherWire):
	var diff = position - otherWire.position
	propose(diff, otherWire.normal)
	proposedConnections.push_back(otherWire)

func changeCircuit(newCircuit):
	circuit = newCircuit
	circuit.join(self)
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

func commitProposal():
	$Committed/Hub.visible = $Committed/Hub.visible or $Proposed/Hub.visible
	$Committed/PosX.visible = $Committed/PosX.visible or $Proposed/PosX.visible
	$Committed/NegX.visible = $Committed/NegX.visible or $Proposed/NegX.visible
	$Committed/PosZ.visible = $Committed/PosZ.visible or $Proposed/PosZ.visible
	$Committed/NegZ.visible = $Committed/NegZ.visible or $Proposed/NegZ.visible
	
	$Proposed/Hub.visible = false
	$Proposed/PosX.visible = false
	$Proposed/NegX.visible = false
	$Proposed/PosZ.visible = false
	$Proposed/NegZ.visible = false
	
	for p in proposedConnections:
		if not connections.has(p):
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
