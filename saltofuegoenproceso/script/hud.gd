#hud
extends CanvasLayer

signal start_game


func _ready() -> void:
	print("HUD READY")
	$StartButton.show()
	$Message.hide()


func show_game_over() -> void:
	print("SHOW GAME OVER")
	$Message.text = "Game Over"
	$Message.show()
	$StartButton.show()


func hide_game_over() -> void:
	print("HIDE GAME OVER")

	$Message.hide()
	$StartButton.hide()

	print("Start visible:", $StartButton.visible)


func _on_start_button_pressed() -> void:
	print("START PRESSED")
	start_game.emit()
