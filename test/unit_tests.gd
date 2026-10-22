extends Node
## Unit tests for the damage system. Booted from test/unit_runner.tscn in
## normal mode (autoloads active). Run with:
##   godot --headless --path . res://test/unit_runner.tscn

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
	await get_tree().process_frame
	print("== damage types ==")
	test_damage_types()
	print("== resistances ==")
	test_resistances()
	print("== damage system ==")
	test_damage_system()
	print("== tres integrity ==")
	test_tres_files()
	await get_tree().process_frame
	print("")
	if _failures == 0:
		print("ALL TESTS PASSED (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		printerr("%d/%d CHECKS FAILED" % [_failures, _checks])
		get_tree().quit(1)

func test_damage_types() -> void:
	var kinetic := load("res://ECS/damage/types/kinetic.tres") as DamageType
	var energy := load("res://ECS/damage/types/energy.tres") as DamageType
	var heat := load("res://ECS/damage/types/heat.tres") as DamageType
	var radiation := load("res://ECS/damage/types/radiation.tres") as DamageType
	check(kinetic != null and kinetic.id == &"kinetic", "kinetic type loads")
	check(energy.id == &"energy", "energy type loads")
	check(heat.id == &"heat", "heat type loads")
	check(radiation.id == &"radiation", "radiation type loads")

func test_resistances() -> void:
	var kinetic := load("res://ECS/damage/types/kinetic.tres") as DamageType
	var res := Resistances.new()
	res.values = {"kinetic": 0.5, "energy": 1.0}
	check(is_equal_approx(res.apply(100.0, kinetic), 50.0), "50% kinetic reduction")
	var energy := load("res://ECS/damage/types/energy.tres") as DamageType
	check(is_equal_approx(res.apply(100.0, energy), 0.0), "100% energy immunity")
	var heat := load("res://ECS/damage/types/heat.tres") as DamageType
	check(is_equal_approx(res.apply(40.0, heat), 40.0), "unlisted type takes full damage")
	check(is_equal_approx(res.apply(25.0, null), 25.0), "null type takes full damage")

func test_damage_system() -> void:
	var ds := DamageSystem.new()
	ds.max_health = 100.0
	ds.health = ds.max_health
	var died_count := [0]
	ds.died.connect(func() -> void: died_count[0] += 1)
	var kinetic := load("res://ECS/damage/types/kinetic.tres") as DamageType
	check(is_equal_approx(ds.take_damage(DamageInstance.new(kinetic, 30.0)), 30.0), "no resistances: full damage")
	check(is_equal_approx(ds.health, 70.0), "health tracks damage")
	ds.take_damage(DamageInstance.new(kinetic, 200.0))
	check(ds.dead and ds.health == 0.0, "lethal damage kills and clamps health")
	check(died_count[0] == 1, "died emitted exactly once")
	check(is_equal_approx(ds.take_damage(DamageInstance.new(kinetic, 10.0)), 0.0), "no damage after death")
	check(died_count[0] == 1, "no duplicate died signal")
	ds.heal(50.0)
	check(ds.health == 0.0, "cannot heal when dead")

	var ds2 := DamageSystem.new()
	ds2.max_health = 100.0
	ds2.health = 100.0
	ds2.resistances = load("res://ECS/damage/resistances/cruiser.tres") as Resistances
	var energy := load("res://ECS/damage/types/energy.tres") as DamageType
	check(is_equal_approx(ds2.take_damage(DamageInstance.new(energy, 100.0)), 50.0), "cruiser energy resistance halves damage")
	var died2 := [false]
	ds2.died.connect(func() -> void: died2[0] = true)
	ds2.die()
	check(died2[0] and ds2.dead, "die() kills and emits")
	ds.free()
	ds2.free()

func test_tres_files() -> void:
	var files := [
		"res://ECS/damage/resistances/drone.tres",
		"res://ECS/damage/resistances/cruiser.tres",
		"res://ECS/damage/resistances/striker.tres",
		"res://ECS/damage/resistances/station.tres",
		"res://ECS/damage/resistances/player.tres",
		"res://ECS/damage/resistances/core.tres",
	]
	for path in files:
		var res := load(path)
		check(res is Resistances, "%s loads as Resistances" % path)
