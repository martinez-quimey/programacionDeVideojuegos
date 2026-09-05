#hud
extends CanvasLayer

signal start_game
signal retry_game
signal main_menu


func _ready() -> void:
	# Conectar botones
	$MainMenu/CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$MainMenu/CenterContainer/VBoxContainer/LanguageButton.pressed.connect(_on_language_button_pressed)

	$GameOver/CenterContainer/VBoxContainer/RetryButton.pressed.connect(_on_retry_button_pressed)
	$GameOver/CenterContainer/VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_button_pressed)

	$LanguageMenu/CenterContainer/VBoxContainer/SpanishButton.pressed.connect(_on_spanish_button_pressed)
	$LanguageMenu/CenterContainer/VBoxContainer/EnglishButton.pressed.connect(_on_english_button_pressed)
	$LanguageMenu/CenterContainer/VBoxContainer/BackButton.pressed.connect(_on_back_button_pressed)


	$Pause/CenterContainer/VBoxContainer/Continuar.pressed.connect(_on_continuar_button_pressed)
	$Pause/CenterContainer/VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_button2_pressed)


	update_language()
	show_main_menu()


# =========================
# MENÚS
# =========================

func show_main_menu() -> void:
	$MainMenu.show()
	$GameOver.hide()
	$LanguageMenu.hide()
	$Pause.hide()


func show_game_over() -> void:
	$MainMenu.hide()
	$GameOver.show()
	$LanguageMenu.hide()
	$Pause.hide()


func show_language_menu() -> void:
	$MainMenu.hide()
	$GameOver.hide()
	$LanguageMenu.show()
	$Pause.hide()
	
func show_pause_menu() ->void:
	$MainMenu.hide()
	$Pause.show()
	$LanguageMenu.hide()
	$GameOver.hide()


# =========================
# IDIOMA
# =========================

func update_language() -> void:
	if Settings.language == "es":
		$MainMenu/CenterContainer/VBoxContainer/Title.text = "Eva Two Tales Kitsune"
		$MainMenu/CenterContainer/VBoxContainer/StartButton.text = "Jugar"
		$MainMenu/CenterContainer/VBoxContainer/LanguageButton.text = "Idioma"

		$GameOver/CenterContainer/VBoxContainer/Message.text = "Game Over"
		$GameOver/CenterContainer/VBoxContainer/RetryButton.text = "Reintentar"
		$GameOver/CenterContainer/VBoxContainer/MainMenuButton.text = "Menú principal"

		$LanguageMenu/CenterContainer/VBoxContainer/Title.text = "Idioma"
		$LanguageMenu/CenterContainer/VBoxContainer/SpanishButton.text = "Español"
		$LanguageMenu/CenterContainer/VBoxContainer/EnglishButton.text = "Inglés"
		$LanguageMenu/CenterContainer/VBoxContainer/BackButton.text = "Volver"
		
		$Pause/CenterContainer/VBoxContainer/Message.text = "Pausa"
		$Pause/CenterContainer/VBoxContainer/Continuar.text = "Continuar"
		$Pause/CenterContainer/VBoxContainer/MainMenuButton.text = "volver al menu principal"

	elif Settings.language == "en":
		$MainMenu/CenterContainer/VBoxContainer/Title.text = "Eva Two Tales Kitsune"
		$MainMenu/CenterContainer/VBoxContainer/StartButton.text = "Play"
		$MainMenu/CenterContainer/VBoxContainer/LanguageButton.text = "Language"

		$GameOver/CenterContainer/VBoxContainer/Message.text = "Game Over"
		$GameOver/CenterContainer/VBoxContainer/RetryButton.text = "Retry"
		$GameOver/CenterContainer/VBoxContainer/MainMenuButton.text = "Main Menu"

		$LanguageMenu/CenterContainer/VBoxContainer/Title.text = "Language"
		$LanguageMenu/CenterContainer/VBoxContainer/SpanishButton.text = "Spanish"
		$LanguageMenu/CenterContainer/VBoxContainer/EnglishButton.text = "English"
		$LanguageMenu/CenterContainer/VBoxContainer/BackButton.text = "Back"
		
		$Pause/CenterContainer/VBoxContainer/Message.text = "Pause"
		$Pause/CenterContainer/VBoxContainer/Continuar.text = "Resume"
		$Pause/CenterContainer/VBoxContainer/MainMenuButton.text = "Back to principal menu"


# =========================
# MAIN MENU
# =========================

func _on_start_button_pressed() -> void:
	print("JUGAR")
	$MainMenu.hide()
	start_game.emit()


func _on_language_button_pressed() -> void:
	print("IDIOMA")
	show_language_menu()


# =========================
# GAME OVER
# =========================

func _on_retry_button_pressed() -> void:
	print("REINTENTAR")
	$GameOver.hide()
	retry_game.emit()


func _on_main_menu_button_pressed() -> void:
	print("VOLVER AL MENU")
	main_menu.emit()


# =========================
# LANGUAGE MENU
# =========================

func _on_spanish_button_pressed() -> void:
	Settings.language = "es"
	update_language()
	show_main_menu()


func _on_english_button_pressed() -> void:
	Settings.language = "en"
	update_language()
	show_main_menu()


func _on_back_button_pressed() -> void:
	show_main_menu()
	
# =========================
# Pause Menu
# =========================

func _on_continuar_button_pressed() -> void:
	print("continuar")
	get_tree().paused = false
	Settings.sePuedePausar = true
	$Pause.hide()
	
func _on_main_menu_button2_pressed() -> void:
	print("VOLVER AL MENU")
	main_menu.emit()
