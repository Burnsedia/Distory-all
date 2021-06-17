extends Area

var speed:float =  100.0;
var damage:int = 100;
var bullit_time:Timer = Timer.new()

#func _ready():
#	bullit_time.wait_time = 2.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	translate(self.transform.basis.x * speed)
