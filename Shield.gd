extends Spatial

onready var template = $Template
onready var target = $RealShield

const STRENGTH = 3

var emitters = []

func _ready():
	remove_child(template)
	spreadShield()

func spreadShield():
	if emitters.empty():
		queue_free()
		return
	
	# Remove Existing Children
	for child in target.get_children():
		target.remove_child(child)
		child.queue_free()
	
	# Add a new child at each emitter
	for emitter in emitters:
		makePiece(to_local(emitter.shieldSpawn.global_transform.origin), STRENGTH, emitter)
	
	# Then for each child extend it if there's room
	for i in range(1, STRENGTH):
		for child in target.get_children():
			var neigh = child.getNeighbours()
			for f in neigh:
				var v = neigh[f]
				if v and ("shield" in v) and v.shield != self:
					# If any of my neighbours is a different shield, then immediately stop here and merge with them
					mergeShield(v.shield)
					return
			if not neigh[ShieldPiece.Spot.POSZ]:
				makePiece(child.transform.origin + Vector3(0, 0, 10), STRENGTH - i)
			if not neigh[ShieldPiece.Spot.NEGZ]:
				makePiece(child.transform.origin + Vector3(0, 0, -10), STRENGTH - i)
			if not neigh[ShieldPiece.Spot.POSX]:
				makePiece(child.transform.origin + Vector3(10, 0, 0), STRENGTH - i)
			if not neigh[ShieldPiece.Spot.NEGX]:
				makePiece(child.transform.origin + Vector3(-10, 0, 0), STRENGTH - i)

func mergeShield(otherShield):
	for emitter in emitters:
		emitter.shield = otherShield
	
	otherShield.emitters += emitters
	get_parent().remove_child(self)
	otherShield.spreadShield()
	self.queue_free()

func splitShield():
	if emitters.empty():
		queue_free()
		return
	
	# First we need to compute the current set of pieces with the new set of emitters
	spreadShield()
	
	var groups = []
	while not emitters.empty():
		var group = []
		# Group is an output variable things are added to during the trace
		emitters.front().shieldPiece.trace(group)
		for e in group:
			emitters.erase(e)
		groups.push_back(group)
	
	# Take the first group as our own
	emitters = groups.pop_front()
	spreadShield()
	
	# Make copies for the rest
	for group in groups:
		var new = self.duplicate()
		new.emitters = group
		for emitter in group:
			emitter.shield = new
		get_parent().add_child(new)

func makePiece(position, strength, emitter = null):
	var newOne = template.duplicate()
	newOne.shield = self
	newOne.transform.origin = position
	newOne.strength = strength
	newOne.emitter = emitter
	if emitter:
		emitter.shieldPiece = newOne
	target.add_child(newOne)

func addEmitter(emitter):
	if not emitters.has(emitter):
		emitters.push_back(emitter)

func removeEmitter(emitter):
	emitters.erase(emitter)

func receiveDamage(damage):
	# There is a race condition where I turn a shield off while it's being attacked
	# If so, ignore the damage and just don't crash
	if emitters.empty():
		return
	
	var damagePer = damage / emitters.size()
	for e in emitters:
		e.shieldDamage(damagePer)
