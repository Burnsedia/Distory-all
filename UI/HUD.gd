extends CanvasLayer
## In-game HUD: resources, wave info, build menu, pause and game-over screens.
## process_mode ALWAYS so menus work while the tree is paused.

var game_over_visible: bool = false

@onready var minerals_label: Label = $TopBar/MineralsLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var enemies_label: Label = $TopBar/EnemiesLabel
@onready var shipyards_label: Label = $TopBar/ShipyardsLabel
@onready var banner: Label = $Banner
@onready var player_health_bar: ProgressBar = $PlayerHealthBar
@onready var core_health_bar: ProgressBar = $CoreHealthBar
@onready var build_menu: PanelContainer = $BuildMenu
@onready var pause_menu: PanelContainer = $PauseMenu
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var game_over_title: Label = $GameOverPanel/Margin/VBox/TitleLabel
@onready var game_over_stats: Label = $GameOverPanel/Margin/VBox/StatsLabel

@onready var economy = get_node("../Managers/Economy")
@onready var wave_director = get_node("../Managers/WaveDirector")
@onready var game_flow = get_node("../Managers/GameFlow")
@onready var build = get_node("../Managers/Build")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	economy.minerals_changed.connect(_on_minerals_changed)
	wave_director.wave_changed.connect(_on_wave_changed)
	wave_director.enemies_changed.connect(_on_enemies_changed)
	wave_director.shipyards_changed.connect(_on_shipyards_changed)
	Events.game_over.connect(_on_game_over)
	Events.message.connect(_show_banner)

	$BuildMenu/Margin/VBox/GunButton.pressed.connect(_on_gun_pressed)
	$BuildMenu/Margin/VBox/MissileButton.pressed.connect(_on_missile_pressed)
	$PauseMenu/Margin/VBox/ResumeButton.pressed.connect(_resume)
	$PauseMenu/Margin/VBox/RestartButton.pressed.connect(_restart)
	$PauseMenu/Margin/VBox/MenuButton.pressed.connect(_to_menu)
	$GameOverPanel/Margin/VBox/RetryButton.pressed.connect(_restart)
	$GameOverPanel/Margin/VBox/MenuButton.pressed.connect(_to_menu)

	await get_tree().process_frame
	if Global.player != null:
		_bind_health(Global.player, player_health_bar)
	if Global.maintower != null:
		_bind_health(Global.maintower, core_health_bar)
	_on_minerals_changed(economy.minerals)
	_on_wave_changed(wave_director.wave)
	_on_enemies_changed(wave_director.enemies_alive)
	_on_shipyards_changed(wave_director.shipyards_alive)

func _bind_health(owner: Node, bar: ProgressBar) -> void:
	var ds := DamageSystem.find_in(owner)
	if ds == null:
		return
	bar.max_value = ds.max_health
	bar.value = ds.health
	ds.health_changed.connect(func(current: float, _max: float) -> void:
		bar.value = current)

# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_handle_cancel()
	elif event.is_action_pressed("ui_accept"):
		_handle_accept()
	elif event.is_action_pressed("PlaceStation"):
		_toggle_build_menu()
	elif event.is_action_pressed("selectGunStation"):
		_select_station(build.GUN_STATION)
	elif event.is_action_pressed("selectMissileStation"):
		_select_station(build.MISSILE_STATION)
	elif event.is_action_pressed("retry"):
		if game_over_visible:
			_restart()

func _handle_cancel() -> void:
	if game_over_visible:
		return
	if build.build_mode:
		build.cancel_build()
	elif pause_menu.visible:
		_resume()
	else:
		_pause()

func _handle_accept() -> void:
	if game_over_visible:
		_restart()
	elif build.build_mode:
		build.confirm_build()
	elif pause_menu.visible:
		_resume()

func _toggle_build_menu() -> void:
	if game_over_visible or pause_menu.visible:
		return
	build_menu.visible = not build_menu.visible

func _select_station(station: PackedScene) -> void:
	if game_over_visible or pause_menu.visible:
		return
	build.set_build_station(station)
	build_menu.visible = false

func _pause() -> void:
	if game_over_visible:
		return
	pause_menu.visible = true
	get_tree().paused = true

func _resume() -> void:
	pause_menu.visible = false
	get_tree().paused = false

func _restart() -> void:
	game_flow.restart()

func _to_menu() -> void:
	game_flow.quit_to_menu()

func _on_gun_pressed() -> void:
	_select_station(build.GUN_STATION)

func _on_missile_pressed() -> void:
	_select_station(build.MISSILE_STATION)

# ------------------------------------------------------------------ updates

func _on_minerals_changed(value: int) -> void:
	minerals_label.text = "MINERALS %d" % value

func _on_wave_changed(wave: int) -> void:
	wave_label.text = "WAVE %d" % wave

func _on_enemies_changed(remaining: int) -> void:
	enemies_label.text = "HOSTILES %d" % remaining

func _on_shipyards_changed(remaining: int) -> void:
	shipyards_label.text = "SHIPYARDS %d" % remaining

func _show_banner(text: String) -> void:
	banner.text = text
	banner.visible = true
	banner.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(banner, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func() -> void: banner.visible = false)

func _on_game_over(won: bool) -> void:
	if game_over_visible:
		return
	game_over_visible = true
	build_menu.visible = false
	pause_menu.visible = false
	if build.build_mode:
		build.cancel_build()
	game_over_title.text = "SECTOR SECURED" if won else "SECTOR LOST"
	game_over_stats.text = "WAVES SURVIVED: %d\nMINERALS HELD: %d" % [wave_director.wave, economy.minerals]
	game_over_panel.visible = true
	# Let the final moment breathe before freezing the scene.
	get_tree().create_timer(1.4, true).timeout.connect(func() -> void:
		if game_flow.game_ended:
			get_tree().paused = true)
