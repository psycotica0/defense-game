extends Spatial

var wire_scene = preload("res://Wires.tscn")
var circuits = {}
var maxCircuit = 1

var allWires = {}
var proposal = []
 
func _ready():
	pass

func startWire():
	proposal.clear()

func wireStep(pos, normal):
	var coord = [pos, normal]
	
	if proposal.back() != coord:
		var prev = proposal.back()
		proposal.push_back([pos, normal])
		var wire = addWire(pos, normal)
		wire.startPropose()
		if prev: # This isn't the first item, so we're making a connection
			var prevWire = allWires.get(prev)
			wire.proposeConnection(prevWire)

func finishWire():
	for p in proposal:
		allWires.get(p).commitProposal()
	proposal.clear()

func addWire(pos, normal):
	var existing = allWires.get([pos, normal])
	if existing:
		print("Existing")
		return existing
	else:
		print("New one")
		var new_wires = wire_scene.instance()
		new_wires.circuitManager = self
		allWires[[pos, normal]] = new_wires
		get_tree().root.add_child(new_wires)
		new_wires.setPosition(pos, normal)
		return new_wires

func newCircuit():
	var c = Circuit.new()
	c.identifier = maxCircuit
	maxCircuit += 1
	circuits[c.identifier] = c
	return c

func merge(first, second):
	if first.members.size() >= second.members.size():
		for m in second.members:
			m.changeCircuit(first)
		circuits.erase(second.identifier)
	else:
		for m in first.members:
			m.changeCircuit(second)
		circuits.erase(first.identifier)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
