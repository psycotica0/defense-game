extends Spatial

var wanderer_scene = preload("res://Wanderer.tscn")

export var probability = 0.2
var rand = RandomNumberGenerator.new()

func _ready():
	rand.randomize()

func _on_Timer_timeout():
	if rand.randf() < probability:
		var enemy = wanderer_scene.instance()
		enemy.transform = transform
		get_parent().add_child(enemy)
