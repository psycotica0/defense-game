tool
extends Spatial

onready var debugCone = $DebugLook
onready var collisionShape = $Area/CollisionShape

export var height = 10.0 setget setHeight
export var angle = 90.0 setget setAngle
var halfAngleRad = deg2rad(angle)
export var length = 10.0 setget setLength
export(int, LAYERS_3D_PHYSICS) var collision_mask = 0

# Box is for things in our bounding box (simplest)
# Cone is for things in the defined cone
# Visible is for things inside the cone and with clear line of sight
enum VisionState {BOX, CONE, VISIBLE}

var bodies = {}
var visibleBodiesCache = []
var arrayCache = false

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
	setShapes()
	$Area.collision_mask = collision_mask

func _physics_process(delta):
	if not Engine.is_editor_hint():
		physics_process(delta)

func physics_process(_delta):
	for b in bodies:
		var s = bodies[b]
		var p = b.global_transform.origin
		
		if pointInWedge(p):
			if pointVisible(p):
				if s != VisionState.VISIBLE:
					bodies[b] = VisionState.VISIBLE
					arrayCache = false
					emit_signal("vision_entered", b)
			else:
				bodies[b] = VisionState.CONE
				if s == VisionState.VISIBLE:
					arrayCache = false
					emit_signal("vision_exited", b)
		else:
			bodies[b] = VisionState.BOX
			if s == VisionState.VISIBLE:
				arrayCache = false
				emit_signal("vision_exited", b)

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

func pointVisible(point):
	var state = get_world().direct_space_state
	# I was running into a problem where the origin was near the ground and clipping through the floor when at a distance
	# So, this isn't great because it means the vision could just shoot over someone's head, but basically always scan at the middle of the cone
	point.y = global_transform.origin.y
	var ray_result = state.intersect_ray(global_transform.origin, point, [], Globals.WALLS_LAYER | collision_mask)
	if ray_result and ray_result.collider:
		if ray_result.collider.collision_layer & collision_mask:
			return true
	
	return false

func visibleBodies():
	if not arrayCache:
		arrayCache = true
		visibleBodiesCache.clear()
		for b in bodies:
			if bodies[b] == VisionState.VISIBLE:
				visibleBodiesCache.push_back(b)
	
	return visibleBodiesCache

func _on_Area_body_entered(body):
	bodies[body] = VisionState.BOX

func _on_Area_body_exited(body):
	var s = bodies[body]
	bodies.erase(body)
	if s == VisionState.VISIBLE:
		arrayCache = false
		emit_signal("vision_exited", body)
	
