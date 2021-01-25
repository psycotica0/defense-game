extends Node

const WANDERER_SCENE = preload("res://Wanderer.tscn")

class EnemyPrice:
	# This is the price of the enemy when there are 0 of them
	var minPrice
	# This is inverse of density. It's number of empty squares per unit
	# So 25 means the true density is 1/25 or 1 enemy per 25 empty squares
	var expectedDensity
	# This is the price of this enemy at the expected density
	var expectedPrice
	# This is the scene that represents this baddie
	var scene
	
	func _init(minPrice, expectedPrice, expectedDensity, scene):
		self.minPrice = minPrice
		self.expectedPrice = expectedPrice
		self.expectedDensity = expectedDensity
		self.scene = scene
	
	func calculateCost(density):
		# I reciprocate the expectedDensity here to put it in the same units that are coming in
		var a = (expectedPrice - minPrice) * pow(expectedDensity, 2)
		# This just represents a parabola that goes through the min price at 0
		# and then hits my expected price at my expected density
		return a*pow(density, 2) + minPrice

var ENEMIES = {
	"wanderer": EnemyPrice.new(3, 60, 25, WANDERER_SCENE)
}

var rand = RandomNumberGenerator.new()

var level

var currentMoney = 0

func _ready():
	rand.randomize()

func takeTurn():
	# Make new money
	# These numbers were chosen to always make 1 dollar, never more than 10
	currentMoney += pow(10, rand.randf())
	prints("Current Money", currentMoney)
	
	# Calculate the current density for each enemy
	var spaces = level.spawnableLocations.size()
	if spaces == 0:
		prints("No more spaces!")
		return
	
	var cost = {}
	for k in ENEMIES.keys():
		var currentDensity = float(level.enemies[k]) / spaces
		# Calculate the current price for each enemy
		cost[k] = ENEMIES[k].calculateCost(currentDensity)
	
	# How much of our money do we want to spend this turn
	var spendAmount = currentMoney * rand.randf()
	
	# Spend our money on the first thing we can
	var shuffled = ENEMIES.keys()
	shuffled.shuffle()
	for k in shuffled:
		if cost[k] < spendAmount:
			prints("Spent", cost[k])
			currentMoney -= cost[k]
			
			var where = rand.randi_range(0, level.spawnableLocations.size() - 1)
			var sprite = ENEMIES[k].scene.instance()
			sprite.transform.origin = level.spawnableLocations[where] * 10 + Vector3(5, 0, 5)
			level.add_child(sprite)
			break

func _on_Timer_timeout():
	takeTurn()
