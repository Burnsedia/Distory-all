extends Node
## Small shared state and counters. GameState owns the actual game rules.

var player = null
var maintower = null
var droneCount = 0
var bulletCount = 0

const maxDroinds = 600
const maxbullets = 10000

## Hard cap on live bullets to protect performance.
const BULLET_MAX = 2000

func _process(_delta):
	if droneCount < 0:
		droneCount = 0
	if bulletCount < 0:
		bulletCount = 0
