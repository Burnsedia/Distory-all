extends Node
## Smoke test driver. Booted from test/smoke_launcher.tscn in normal mode.
## Runs a full gameplay arc against the real game scene and quits with a
## pass/fail exit code. Run with:
##   godot --headless --path . res://test/smoke_launcher.tscn

var _checks := 0
var _failures := 0

func _ready() -> void:
	call_deferred("_run")

func check(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("  PASS: %s" % name)
	else:
		_failures += 1
		printerr("  FAIL: %s" % name)

func _run() -> void:
	var runner: Node = load("res://test/smoke_core.gd").new()
	runner.name = "SmokeCore"
	get_tree().root.add_child(runner)
	queue_free()
