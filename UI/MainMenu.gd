extends Control
## Main menu. Deploy, view controls, or quit.

func _ready() -> void:
	$Center/DeployButton.grab_focus()

func _on_deploy_pressed() -> void:
	get_tree().change_scene_to_file("res://ProxyamStarsystem/game_world.tscn")

func _on_controls_pressed() -> void:
	$ControlsPanel.visible = true
	$ControlsPanel/Margin/VBox/CloseButton.grab_focus()

func _on_close_pressed() -> void:
	$ControlsPanel.visible = false
	$Center/DeployButton.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()
