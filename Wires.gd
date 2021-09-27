extends Spatial

var position
var normal
var circuitManager
var circuit

var proposedConnections = []
var proposedDeletions = []
var connections = []
var dependent
var dependent_class
var dependent_direction
var tileState

enum SwitchState {NONE, OPEN, CLOSED}
var switchState = SwitchState.NONE

var selected = false

const OFFSET = Vector3(5, 5, 5)

const UP = Vector3.UP
const DOWN = Vector3.DOWN
const RIGHT = Vector3.RIGHT
const LEFT = Vector3.LEFT
const FORWARD = Vector3.FORWARD
const BACK = Vector3.BACK

const circuitDebugSymbol = false

enum LegState {NOTHING, PROPOSED, COMMITTED}
var legs = {
	"posZ": LegState.NOTHING,
	"negZ": LegState.NOTHING,
	"posX": LegState.NOTHING,
	"negX": LegState.NOTHING,
}

var legConnectivity = {
	"posZ": true,
	"negZ": true,
	"posX": true,
	"negX": true,
}

func _ready():
	$Committed/Hub.visible = false
	$Proposed/Hub.visible = false
	renderSwitchState()
	setLegVisibility()
	renderSelectionState()
	tileState = Globals.currentLevel.getTileState(global_transform.origin)

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
			translate(Vector3(0, 1, 0))
		LEFT: # This is wall
			rotate_z(PI/2)
			translate(Vector3(0, 2, 0))
		RIGHT:
			rotate_z(-PI/2)
			translate(Vector3(0, 2, 0))
		FORWARD:
			rotate_x(-PI/2)
			translate(Vector3(0, 2, 0))
		BACK:
			rotate_x(PI/2)
			translate(Vector3(0, 2, 0))

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
# If xor is true, connection over existing connection means delete
# If false, connection over existing connection means noop
func connectionProposed(otherWire, xor = true):
	var leg = getDirection(otherWire)
	
	# At some point I should fix this for real
	# For now I just don't want it to crash
	if leg == null or otherWire.getDirection(self) == null:
		return
	
	var cnxIndex = connections.find(otherWire)
	var prpIndex = proposedConnections.find(otherWire)
	var delIndex = proposedDeletions.find(otherWire)
	
	if delIndex != -1: # Undo Delete
		proposedDeletions.remove(delIndex)
		legs[leg] = LegState.COMMITTED
	elif cnxIndex != -1: # Delete
		if xor:
			proposedDeletions.push_back(otherWire)
			legs[leg] = LegState.PROPOSED
		else:
			pass
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
	
	if circuitDebugSymbol:
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
func floodCircuit(newCircuit, fromWire):
	if circuit == newCircuit or (fromWire and not legConnectivity[getDirection(fromWire)]):
		# If we're already on this circuit, then we're done.
		# Continuing would make a contant feedback loop.
		# Also, if there is no other wire, then we're being given a circuit from
		# the main loop, which means it didn't flood into us. We have to take those.
		# Also, if we got flooded from a wire we are unswitched from, ignore it.
		return
	
	changeCircuit(newCircuit)
	for c in connections:
		if legConnectivity[getDirection(c)]:
			c.floodCircuit(newCircuit, self)

func setLegVisibility():
	$Committed/PosX.visible = legs.posX == LegState.COMMITTED
	$Committed/NegX.visible = legs.negX == LegState.COMMITTED
	$Committed/PosZ.visible = legs.posZ == LegState.COMMITTED
	$Committed/NegZ.visible = legs.negZ == LegState.COMMITTED
	
	$Proposed/PosX.visible = legs.posX == LegState.PROPOSED
	$Proposed/NegX.visible = legs.negX == LegState.PROPOSED
	$Proposed/PosZ.visible = legs.posZ == LegState.PROPOSED
	$Proposed/NegZ.visible = legs.negZ == LegState.PROPOSED

func setDependent(klass, direction = Vector3.RIGHT):
	if dependent and dependent is Generator:
		# Don't allow people to change generators into other stuff
		return
	
	# Make sure if we have a dependent already we clean it up
	removeDependent()
	
	dependent = klass.instance()
	dependent_class = klass
	dependent_direction = direction
	
	dependent.transform = $MountPoint.transform
	if dependent.has_method("setDirection"):
		dependent.setDirection(direction)
	
	dependent.source = self
	
	add_child(dependent)
	if circuit:
		dependent.changeCircuit(circuit)

func removeDependent():
	# Don't allow people to remove generators
	if dependent and not dependent is Generator:
		dependent.changeCircuit(null)
		dependent.queue_free()
		dependent = null
		dependent_class = null
		dependent_direction = null
	
	# All circuits without a dependent are closed
	legConnectivity["posX"] = true
	legConnectivity["posZ"] = true
	legConnectivity["negX"] = true
	legConnectivity["negZ"] = true
	processCircuitConnection()

func renderSwitchState():
	$OpenSwitch.visible = switchState == SwitchState.OPEN
	$ClosedSwitch.visible = switchState == SwitchState.CLOSED

func renderSelectionState():
	if selected:
		$Selection/AnimationPlayer.play("Selected")
	else:
		$Selection/AnimationPlayer.play("Unselected")

func select():
	if not selected:
		selected = true
		renderSelectionState()

func unselect():
	if selected:
		selected = false
		renderSelectionState()

func toggle_selection():
	if selected:
		unselect()
	else:
		select()

func commitProposal():
	$Committed/Hub.visible = true
	$Proposed/Hub.visible = false
	
	for p in proposedConnections:
		if not connections.has(p):
			legs[getDirection(p)] = LegState.COMMITTED
			connections.push_back(p)
	
	proposedConnections.clear()
	
	# Run through my connections now to make sure circuits are all joined
	processCircuitConnection()
	
	# Now deletions, perhaps undoing all the work we just did
	for p in proposedDeletions:
		connections.erase(p)
		legs[getDirection(p)] = LegState.NOTHING
	
	var hadDeletions = not proposedDeletions.empty()
	proposedDeletions.clear()
	
	setLegVisibility()
	
	if is_trivial():
		tileState.wires.erase(self)
	else:
		if not tileState.wires.has(self):
			tileState.wires.push_back(self)
	
	if hadDeletions:
		return circuit
	else:
		return null

func setConnectivity(key, value):
	legConnectivity[key] = value

func processCircuitConnection():
	for c in connections:
		var dir = getDirection(c)
		var otherDir = c.getDirection(self)
		
		if legConnectivity[dir] and c.legConnectivity[otherDir]:
			if circuit and c.circuit:
				# We're already in a circuit, so this is a merge
				if circuit != c.circuit:
					# Our neighbour is a member of a circuit we are not
					circuitManager.merge(circuit, c.circuit)
			elif c.circuit:
				# We aren't in a circuit, so just join theirs
				changeCircuit(c.circuit)
		else:
			if circuit == c.circuit:
				# We're sharing a circuit with a thing that's disconnected from us
				circuitManager.splitCircuits([circuit])
				# This split will erase this circuit and fully recompute them
				# So we're done now. It's all been traced, etc
				return
	
	if not circuit:
		# If at the end of the above loop, I didn't end up in any circuits, just add a new one for myself
		changeCircuit(circuitManager.newCircuit())

func toggleSwitch():
	match switchState:
		SwitchState.NONE, SwitchState.CLOSED:
			switchState = SwitchState.OPEN
			setConnectivity("posZ", false)
			setConnectivity("negZ", false)
			setConnectivity("posX", false)
			setConnectivity("negX", false)
		SwitchState.OPEN:
			switchState = SwitchState.CLOSED
			setConnectivity("posZ", true)
			setConnectivity("negZ", true)
			setConnectivity("posX", true)
			setConnectivity("negX", true)
	
	renderSwitchState()
	
	processCircuitConnection()

func is_trivial():
	# I have nothing on me, and I'm not connected to anyone else
	return dependent == null and connections.size() == 0
