extends Spatial

var wire_scene = preload("res://Wires.tscn")
var lamp_scene = preload("res://Lamp.tscn")
var turret_scene = preload("res://Turret.tscn")
var shield_scene = preload("res://ShieldGenerator.tscn")
var generator_scene = preload("res://Generator.tscn")
var circuits = {}
var maxCircuit = 1

var allWires = {}
var proposal = []
var tileState = {}
var spawnableLocations = []

class TileState:
	var beacons = []
	var shields = []
	var wires = []
	var players = []
	var enemies = []
	
	func canSpawn():
		return beacons.empty() and shields.empty() and wires.empty() and players.empty() and enemies.empty()

func _enter_tree():
	Globals.currentLevel = self
	for f in $Floors2.get_used_cells():
		tileState[f] = TileState.new()

func _ready():
	updateSpawnLocations()

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
	var circuitsToSplit = []
	
	for p in proposal:
		var circuit = allWires.get(p).commitProposal()
		if circuit:
			if not circuitsToSplit.has(circuit):
				circuitsToSplit.push_back(circuit)
	
	proposal.clear()
	splitCircuits(circuitsToSplit)
	updateSpawnLocations()

func splitCircuits(circuitsToSplit):
	for c in circuitsToSplit:
		# I think I could have one wire return a split
		# but then another one later could have merged
		# So make sure this thing actually exists
		if circuits.has(c.identifier):
			# Then clear out all the existing ones
			for m in c.members:
				m.circuit = null
			
			# I don't love that I'm doing two passes, but to do it in one I'd
			# need to store some kind of generation so I can tell
			# "I've been reset by this pass" from "I'm still set from before"
			# I think this will be cleaner, until it's a problem
			
			for m in c.members:
				if not m.circuit:
					# This hasn't been set by a previous flood, so it must
					# be unconnected to anything we've seen so far
					m.floodCircuit(newCircuit(), true)
			
			# Now remove the old one, all its children are reassigned
			circuits.erase(c.identifier)
		
	# Now cleanup circuits with only one item (since it doesn't connect anything)
	var keys = circuits.keys()
	# I fetched the keys explictly first, because I was afraid some issue modifying while iterating
	for c in keys:
		var circuit = circuits[c]
		if circuit.is_trivial():
			for m in circuit.members:
				allWires.erase([m.position, m.normal])
				m.queue_free()
			circuits.erase(c)
			circuit.queue_free()

func lamp(pos, normal):
	var wire = addWire(pos, normal)
	wire.setDependent(lamp_scene)
	wire.commitProposal()

func turret(pos, normal):
	var wire = addWire(pos, normal)
	wire.setDependent(turret_scene)
	wire.commitProposal()

func shield(pos, normal, direction):
	var wire = addWire(pos, normal)
	wire.setDependent(shield_scene, direction)
	wire.commitProposal()

func toggle_switch(pos, normal):
	var wire = allWires.get([pos, normal])
	# If there's nothing here, do nothing
	if wire:
		wire.toggleSwitch()

func clear_wire(pos, normal):
	var wire = allWires.get([pos, normal])
	if wire:
		wire.removeDependent()

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
		new_wires.setPosition(pos, normal)
		get_tree().root.add_child(new_wires)
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

func initializeGenerator(generator):
	prints("Generator", generator.global_transform.origin)
	var pos = generator.global_transform.origin
	
	var wire = addWire((pos / 10).floor(), Vector3.UP)
	wire.setDependent(generator_scene)
	generator.queue_free()
	#addWire()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func updateSpawnLocations():
	spawnableLocations.clear()
	for k in tileState:
		if tileState[k].canSpawn():
			spawnableLocations.push_back(k)
	
	visualizeSpawnLocations()

func visualizeSpawnLocations():
	for child in $SpawnableHolder.get_children():
		$SpawnableHolder.remove_child(child)
	
	for p in spawnableLocations:
		var fake = $SpawnableTemplate.duplicate()
		fake.transform.origin = (p * 10) + Vector3(5,0,5)
		$SpawnableHolder.add_child(fake)

func getTileState(realPos):
	# This drops the square until it gets to floor
	for f in [0, 1, 2, 3]:
		var position = ((realPos - Vector3(5, 0, 5)) / 10).round() - Vector3(0, f, 0)
		var state = tileState.get(position)
		if state:
			return state
	return null
