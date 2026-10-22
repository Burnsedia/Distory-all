extends Node
## Lives on /root so it survives scene changes. Drives the gameplay arc:
## scene load -> wave spawns -> wave cleared -> towers -> shipyards -> victory.

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

func _finish() -> void:
	print("")
	if _failures == 0:
		print("SMOKE TEST PASSED (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		printerr("%d/%d CHECKS FAILED" % [_failures, _checks])
		get_tree().quit(1)

func _run() -> void:
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://ProxyamStarsystem/game_world.tscn")
	for i in 20:
		await get_tree().process_frame

	print("== scene boot ==")
	check(get_tree().root.find_child("SectorCore", true, false) != null, "core in scene")
	check(GameState.core != null, "GameState.core bound")
	check(Global.player != null, "player registered")
	check(Global.maintower != null, "core registered in Global")
	check(GameState.shipyards_alive == 10, "10 shipyards spawned")
	check(get_tree().get_nodes_in_group("enemy_stations").size() == 10, "shipyards grouped")
	check(GameState.minerals == 10000, "starting minerals")
	check(get_tree().root.find_child("HUD", true, false) != null, "HUD present")

	print("== wave cycle ==")
	GameState._begin_wave()
	await get_tree().process_frame
	check(GameState.enemies_alive > 0, "wave spawns enemies")
	check(get_tree().get_nodes_in_group("enemies").size() > 0, "enemies grouped")
	for i in 30:
		await get_tree().process_frame
	GameState.pending_spawns.clear()
	GameState._spawn_timer.stop()
	GameState.wave_state = "fighting"
	for body in get_tree().get_nodes_in_group("enemies"):
		DamageSystem.find_in(body).die()
	for i in 5:
		await get_tree().process_frame
	check(GameState.enemies_alive == 0, "all enemies counted as cleared")
	check(GameState.wave_state == "intermission", "wave cleared -> intermission")
	check(GameState.minerals > 10000, "wave clear bonus awarded")

	print("== economy ==")
	var before := GameState.minerals
	check(GameState.spend_minerals(1000) and GameState.minerals == before - 1000, "spend_minerals works")
	check(not GameState.spend_minerals(9999999), "cannot overspend")

	print("== tower placement ==")
	check(get_tree().get_nodes_in_group("player_stations").size() == 1, "only core in player_stations at start")
	GameState.set_build_station(GameState.GUN_STATION)
	check(GameState.build_mode and GameState.ghost != null, "build mode + ghost")
	check(get_tree().get_nodes_in_group("player_stations").size() == 1, "ghost does not join gameplay groups")
	Global.player.global_position = Vector3(0, 2, 200)
	for i in 3:
		await get_tree().process_frame
	check(GameState.ghost_valid, "ghost valid inside build radius")
	check(GameState.confirm_build(), "station placed")
	check(not GameState.build_mode, "build mode ended after placement")
	check(get_tree().get_nodes_in_group("player_stations").size() == 2, "station in player_stations group")
	GameState.set_build_station(GameState.GUN_STATION)
	Global.player.global_position = Vector3(0, 2, 600)
	for i in 3:
		await get_tree().process_frame
	check(not GameState.ghost_valid, "ghost invalid outside build radius")
	check(not GameState.confirm_build(), "cannot place out of range")
	GameState.cancel_build()
	check(not GameState.build_mode and GameState.ghost == null, "build mode cancelled")

	print("== damage & victory ==")
	var core_ds := DamageSystem.find_in(Global.maintower)
	core_ds.take_damage_raw(core_ds.max_health * 0.5)
	for i in 3:
		await get_tree().process_frame
	check(not GameState.game_ended, "partial core damage does not end game")
	for yard in get_tree().get_nodes_in_group("enemy_stations"):
		DamageSystem.find_in(yard).die()
	for i in 3:
		await get_tree().process_frame
	check(GameState.shipyards_alive == 0, "all shipyards destroyed")
	check(GameState.game_ended, "game ended")
	check(GameState.wave_state == "idle", "wave cycle stopped")

	_finish()
