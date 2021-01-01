tool
extends Spatial

onready var debugCone = $DebugLook
onready var collisionShape = $Area/CollisionShape

export var height = 10.0 setget setHeight
export var angle = 90.0 setget setAngle
var halfAngleRad = deg2rad(angle)
export var length = 10.0 setget setLength
export(int, LAYERS_3D_PHYSICS) var collision_mask = 0

# These are the things that are inside the box _and_ inside the wedge
var inside = {}

# These are the things that are only inside the box, but outside the wedge
var purgatory = {}

signal vision_entered(body)
signal vision_exited(body)

func setHeight(value):
	height = value
	toolSucks()
	if debugCone:
		setShapes()

func setAngle(value):
	angle = value
	halfAngleRad = deg2rad(angle / 2)
	if debugCone:
		setShapes()

func setLength(value):
	length = value
	toolSucks()
	if debugCone:
		setShapes()

func setCollisionMask(value):
	collision_mask = value
	if $Area:
		$Area.collision_mask = collision_mask

func setShapes():
	var half_width = tan(halfAngleRad) * length
	if debugCone:
		debugCone.scale.x = half_width * 2
		debugCone.scale.y = length
		debugCone.scale.z = height
		
		debugCone.translation.z = length / 2
	
	if collisionShape:
		collisionShape.shape.extents.x = half_width
		collisionShape.shape.extents.y = height / 2
		collisionShape.shape.extents.z = length / 2
		
		collisionShape.translation.z = length / 2

func _ready():
	print("Ready")
	setShapes()
	$Area.collision_mask = collision_mask

func _physics_process(delta):
	if not Engine.is_editor_hint():
		physics_process(delta)

func physics_process(_delta):
	for b in purgatory:
		if pointInWedge(b.global_transform.origin):
			emit_signal("vision_entered", b)
			print("Enter")
			purgatory.erase(b)
			inside[b] = true
	
	for b in inside:
		if not pointInWedge(b.global_transform.origin):
			emit_signal("vision_exited", b)
			print("Exit")
			inside.erase(b)
			purgatory[b] = true

func toolSucks():
	if Engine.is_editor_hint():
		if not debugCone:
			debugCone = get_node("DebugLook")
		
		if not collisionShape:
			collisionShape = get_node("Area/CollisionShape")

func pointInWedge(point):
	# Since I already know it's in the box, and the box's dimensions line up
	# with the wedge mostly I just have to figure out if it's inside the angled
	# part or not
	var local = to_local(point)
	var local2d = Vector2(local.x, local.z)
	var localAngle = Vector2.DOWN.angle_to(local2d)
	
	return abs(localAngle) < halfAngleRad

func _on_Area_body_entered(body):
	purgatory[body] = true

func _on_Area_body_exited(body):
	if inside.get(body):
		emit_signal("vision_exited", body)
		print("Exit")
	inside.erase(body)
	purgatory.erase(body)
