extends Node
## Slim world anchors shared by every node.
##
## Keeps only the two world anchors plus the projectile cap; the live count that
## backs BULLET_MAX is owned by the Spawner. Nothing else here — coupling lives
## in the services that own their own state.

var player = null
var maintower = null

## Hard cap on live projectiles to protect performance.
## The Spawner owns the live count that this caps.
const BULLET_MAX := 2000
