extends CanvasLayer


# Notifies `Main` node that the button has been pressed
signal start_game

func show_message(text):
	$Message.text = text
	$Message.show()

	
func show_game_over():
	show_message("Game Over")
	

	$Message.text = "Eva Two Tales Kitsune!"
	$Message.show()
	# Make a one-shot timer and wait for it to finish.
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()
	
func _on_start_button_pressed():
	$StartButton.hide()
	start_game.emit()

	var parent = get_parent()

	var player = parent.get_node_or_null("Player")
	var enemy = parent.get_node_or_null("Turret")
	var start_position = parent.get_node_or_null("StartPosition")
	var projectile_container = parent.get_node_or_null("Projectiles")


	player.start(start_position.position)
	
	enemy.setValues(player, projectile_container)
