tool
extends Spatial

onready var debugShape = $DebugLook
onready var collisionShape = $Area/CollisionShape

export var radius = 10.0 setget setRadius
export(int, LAYERS_3D_PHYSICS) var collision_mask = 0

# Sphere is for things in our bounding box (simplest)
# Hemi is for things in the defined hemisphere
# Visible is for things inside the cone and with clear line of sight
enum VisionState {SPHERE, HEMI, VISIBLE}

var bodies = {}
var visibleBodiesCache = []
var arrayCache = false

signal vision_entered(body)
signal vision_exited(body)

func setRadius(value):
	radius = value
	toolSucks()
	if debugShape:
		setShapes()

func setShapes():
	if debugShape:
		debugShape.mesh.radius = radius
		debugShape.mesh.height = radius
	
	if collisionShape:
		collisionShape.shape.radius = radius

func toolSucks():
	if Engine.is_editor_hint():
		if not debugShape:
			debugShape = get_node_or_null("DebugLook")
		
		if not collisionShape:
			collisionShape = get_node_or_null("Area/CollisionShape")

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
		if b.has_method("getAimTarget"):
			p = b.getAimTarget()
		
		if pointInHemi(p):
			if pointVisible(p):
				if s != VisionState.VISIBLE:
					bodies[b] = VisionState.VISIBLE
					arrayCache = false
					emit_signal("vision_entered", b)
			else:
				bodies[b] = VisionState.HEMI
				if s == VisionState.VISIBLE:
					arrayCache = false
					emit_signal("vision_exited", b)
		else:
			bodies[b] = VisionState.SPHERE
			if s == VisionState.VISIBLE:
				arrayCache = false
				emit_signal("vision_exited", b)

func pointInHemi(point):
	# Since I already know it's in the sphere, I just have to figure out if it's
	# in the top half or not
	var local = to_local(point)
	
	
	return local.y > 0

func pointVisible(point):
	var state = get_world().direct_space_state
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
	bodies[body] = VisionState.SPHERE

func _on_Area_body_exited(body):
	var s = bodies[body]
	bodies.erase(body)
	if s == VisionState.VISIBLE:
		arrayCache = false
		emit_signal("vision_exited", body)
