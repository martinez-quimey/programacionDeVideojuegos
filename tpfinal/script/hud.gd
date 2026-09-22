
# HUD.gd

extends CanvasLayer

signal start_game
signal retry_game
signal main_menu
signal continue_game


func _ready() -> void:

	# =====================================================
	# MAIN MENU
	# =====================================================
	$Confirmacion.hide()
	var start_button = $MainMenu/CenterContainer/VBoxContainer/StartButton
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)


	var continue_button = $MainMenu/CenterContainer/VBoxContainer/ContinueButton
	if not continue_button.pressed.is_connected(_on_continuar_partida_pressed):
		continue_button.pressed.connect(_on_continuar_partida_pressed)


	var selector_button = $MainMenu/CenterContainer/VBoxContainer/SelectorNiveles
	if not selector_button.pressed.is_connected(_on_selector_niveles_pressed):
		selector_button.pressed.connect(_on_selector_niveles_pressed)


	var language_button = $MainMenu/CenterContainer/VBoxContainer/LanguageButton
	if not language_button.pressed.is_connected(_on_language_button_pressed):
		language_button.pressed.connect(_on_language_button_pressed)


	var quit_button = $MainMenu/CenterContainer/VBoxContainer/QuitGameButton
	if not quit_button.pressed.is_connected(_on_quit_game_button_pressed):
		quit_button.pressed.connect(_on_quit_game_button_pressed)


	# =====================================================
	# GAME OVER
	# =====================================================

	var retry_button = $GameOver/CenterContainer/VBoxContainer/RetryButton
	if not retry_button.pressed.is_connected(_on_retry_button_pressed):
		retry_button.pressed.connect(_on_retry_button_pressed)


	var game_over_menu_button = $GameOver/CenterContainer/VBoxContainer/MainMenuButton
	if not game_over_menu_button.pressed.is_connected(_on_main_menu_button_pressed):
		game_over_menu_button.pressed.connect(_on_main_menu_button_pressed)


	# =====================================================
	# LANGUAGE
	# =====================================================

	var spanish_button = $LanguageMenu/CenterContainer/VBoxContainer/SpanishButton
	if not spanish_button.pressed.is_connected(_on_spanish_button_pressed):
		spanish_button.pressed.connect(_on_spanish_button_pressed)


	var english_button = $LanguageMenu/CenterContainer/VBoxContainer/EnglishButton
	if not english_button.pressed.is_connected(_on_english_button_pressed):
		english_button.pressed.connect(_on_english_button_pressed)


	var back_button = $LanguageMenu/CenterContainer/VBoxContainer/BackButton
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)


	# =====================================================
	# PAUSE
	# =====================================================

	var continuar_button = $Pause/CenterContainer/VBoxContainer/Continuar
	if not continuar_button.pressed.is_connected(_on_continuar_button_pressed):
		continuar_button.pressed.connect(_on_continuar_button_pressed)


	var pause_menu_button = $Pause/CenterContainer/VBoxContainer/MainMenuButton
	if not pause_menu_button.pressed.is_connected(_on_main_menu_button2_pressed):
		pause_menu_button.pressed.connect(_on_main_menu_button2_pressed)

	# =====================================================
	# Confirmacion
	# =====================================================

	var YesButton = $Confirmacion/CenterContainer/VBoxContainer/YesButton
	if not YesButton.pressed.is_connected(_on_yes_button_pressed):
		YesButton.pressed.connect(_on_yes_button_pressed)


	var NoButton = $Confirmacion/CenterContainer/VBoxContainer/NoButton
	if not NoButton.pressed.is_connected(_on_no_button_pressed):
		NoButton.pressed.connect(_on_no_button_pressed)


	# =====================================================
	# SELECTOR DE NIVELES
	# =====================================================

	var selector_back_button = $SelectorNiveles/CenterContainer/VBoxContainer/BackButton
	if not selector_back_button.pressed.is_connected(_on_selector_niveles_back_pressed):
		selector_back_button.pressed.connect(_on_selector_niveles_back_pressed)


	# =====================================================
	# INICIO
	# =====================================================

	update_language()
	actualizar_estado_botones()
	show_main_menu()


# =========================================================
# MENÚS
# =========================================================

func show_main_menu() -> void:

	$MainMenu.show()
	$GameOver.hide()
	$LanguageMenu.hide()
	$Pause.hide()
	$SelectorNiveles.hide()

	actualizar_estado_botones()


func show_game_over() -> void:

	$MainMenu.hide()
	$GameOver.show()
	$LanguageMenu.hide()
	$Pause.hide()
	$SelectorNiveles.hide()


func show_language_menu() -> void:

	$MainMenu.hide()
	$GameOver.hide()
	$LanguageMenu.show()
	$Pause.hide()
	$SelectorNiveles.hide()


func show_pause_menu() -> void:

	$MainMenu.hide()
	$Pause.show()
	$LanguageMenu.hide()
	$GameOver.hide()
	$SelectorNiveles.hide()


func show_selector_niveles() -> void:

	$MainMenu.hide()
	$GameOver.hide()
	$LanguageMenu.hide()
	$Pause.hide()
	$SelectorNiveles.show()

	actualizar_selector_niveles()


# =========================================================
# IDIOMA
# =========================================================

func update_language() -> void:

	if Settings.language == "es":

		# MAIN MENU

		$MainMenu/CenterContainer/VBoxContainer/Title.text = "Eva Two Tales Kitsune"
		$MainMenu/CenterContainer/VBoxContainer/StartButton.text = "Nueva partida"
		$MainMenu/CenterContainer/VBoxContainer/ContinueButton.text = "Continuar"
		$MainMenu/CenterContainer/VBoxContainer/SelectorNiveles.text = "Selector de niveles"
		$MainMenu/CenterContainer/VBoxContainer/LanguageButton.text = "Idioma"
		$MainMenu/CenterContainer/VBoxContainer/QuitGameButton.text = "Cerrar juego"


		# GAME OVER

		$GameOver/CenterContainer/VBoxContainer/Message.text = "Game Over"
		$GameOver/CenterContainer/VBoxContainer/RetryButton.text = "Reintentar"
		$GameOver/CenterContainer/VBoxContainer/MainMenuButton.text = "Menú principal"


		# LANGUAGE

		$LanguageMenu/CenterContainer/VBoxContainer/Title.text = "Idioma"
		$LanguageMenu/CenterContainer/VBoxContainer/SpanishButton.text = "Español"
		$LanguageMenu/CenterContainer/VBoxContainer/EnglishButton.text = "English"
		$LanguageMenu/CenterContainer/VBoxContainer/BackButton.text = "Volver"


		# PAUSE

		$Pause/CenterContainer/VBoxContainer/Message.text = "Pausa"
		$Pause/CenterContainer/VBoxContainer/Continuar.text = "Continuar"
		$Pause/CenterContainer/VBoxContainer/MainMenuButton.text = "Volver al menú principal"


		# SELECTOR

		$SelectorNiveles/CenterContainer/VBoxContainer/Title.text = "Selector de niveles"
		$SelectorNiveles/CenterContainer/VBoxContainer/BackButton.text = "Volver"
		#confirmacion
		
		$Confirmacion/CenterContainer/VBoxContainer/Message.text = "¿Está seguro de que desea iniciar una nueva partida? Los datos actuales se borrarán."
		$Confirmacion/CenterContainer/VBoxContainer/YesButton.text = "Si"
		$Confirmacion/CenterContainer/VBoxContainer/YesButton.text = "No"
		
	elif Settings.language == "en":

		# MAIN MENU

		$MainMenu/CenterContainer/VBoxContainer/Title.text = "Eva Two Tales Kitsune"
		$MainMenu/CenterContainer/VBoxContainer/StartButton.text = "New Game"
		$MainMenu/CenterContainer/VBoxContainer/ContinueButton.text = "Continue"
		$MainMenu/CenterContainer/VBoxContainer/SelectorNiveles.text = "Level Select"
		$MainMenu/CenterContainer/VBoxContainer/LanguageButton.text = "Language"
		$MainMenu/CenterContainer/VBoxContainer/QuitGameButton.text = "Quit Game"


		# GAME OVER

		$GameOver/CenterContainer/VBoxContainer/Message.text = "Game Over"
		$GameOver/CenterContainer/VBoxContainer/RetryButton.text = "Retry"
		$GameOver/CenterContainer/VBoxContainer/MainMenuButton.text = "Main Menu"


		# LANGUAGE

		$LanguageMenu/CenterContainer/VBoxContainer/Title.text = "Language"
		$LanguageMenu/CenterContainer/VBoxContainer/SpanishButton.text = "Español"
		$LanguageMenu/CenterContainer/VBoxContainer/EnglishButton.text = "English"
		$LanguageMenu/CenterContainer/VBoxContainer/BackButton.text = "Back"


		# PAUSE

		$Pause/CenterContainer/VBoxContainer/Message.text = "Pause"
		$Pause/CenterContainer/VBoxContainer/Continuar.text = "Resume"
		$Pause/CenterContainer/VBoxContainer/MainMenuButton.text = "Back to Main Menu"


		# SELECTOR

		$SelectorNiveles/CenterContainer/VBoxContainer/Title.text = "Level Select"
		$SelectorNiveles/CenterContainer/VBoxContainer/BackButton.text = "Back"
		#confirmacion
		
		$Confirmacion/CenterContainer/VBoxContainer/Message.text = "Are you sure you want to start a new game? rent data will be deleted."
		$Confirmacion/CenterContainer/VBoxContainer/YesButton.text = "Yes"
		$Confirmacion/CenterContainer/VBoxContainer/YesButton.text = "No"

# =========================================================
# ESTADO DE LOS BOTONES
# =========================================================

func actualizar_estado_botones() -> void:

	var hay_partida = Save.existe_partida()

	$MainMenu/CenterContainer/VBoxContainer/ContinueButton.disabled = not hay_partida

	$MainMenu/CenterContainer/VBoxContainer/SelectorNiveles.disabled = (
		not hay_partida
		or Settings.nivelesCompletados.is_empty()
	)


# =========================================================
# MAIN MENU
# =========================================================

func _on_start_button_pressed() -> void:

	if (Save.existe_partida()):
		$Confirmacion.show()
		$MainMenu.hide()
	else:
		
		# Crear una partida completamente nueva.

		Save.iniciar_nueva_partida()


		# El Main se encargará de cargar el nivel inicial
		# y de obtener su ruta real mediante game.scene_file_path.

		$MainMenu.hide()

		start_game.emit()


func _on_yes_button_pressed() -> void:
		# Crear una partida completamente nueva.

		Save.iniciar_nueva_partida()


		# El Main se encargará de cargar el nivel inicial
		# y de obtener su ruta real mediante game.scene_file_path.
		$Confirmacion.hide()
		$MainMenu.hide()
		

		start_game.emit()



func _on_no_button_pressed() -> void:
	$Confirmacion.hide()
	$MainMenu.show()

func _on_language_button_pressed() -> void:

	print("IDIOMA")

	show_language_menu()


func _on_quit_game_button_pressed() -> void:

	get_tree().quit()


# =========================================================
# CONTINUAR PARTIDA
# =========================================================

func _on_continuar_partida_pressed() -> void:

	print("CONTINUAR PARTIDA")


	# Cargar todos los datos del archivo.

	if not Save.cargar_partida():

		print("No se pudo cargar la partida")

		return


	# Comprobar que el guardado tenga un nivel.

	if Settings.nivelActual == "":

		print("La partida no tiene un nivel guardado")

		return


	print("Cargando nivel: ", Settings.nivelActual)


	$MainMenu.hide()


	# Main utilizará Settings.nivelActual.
	# No se fuerza ningún nivel concreto.

	continue_game.emit()


# =========================================================
# SELECTOR DE NIVELES
# =========================================================

func _on_selector_niveles_pressed() -> void:

	print("SELECTOR DE NIVELES")


	if not Save.existe_partida():

		return


	Save.cargar_partida()

	show_selector_niveles()


func actualizar_selector_niveles() -> void:

	var vbox = $SelectorNiveles/CenterContainer/VBoxContainer


	# Borrar botones creados anteriormente.

	for hijo in vbox.get_children():

		if hijo.name != "Title" and hijo.name != "BackButton":

			hijo.queue_free()


	# Crear un botón por cada nivel completado.

	for nivel in Settings.nivelesCompletados:

		var boton = Button.new()

		boton.text = obtener_nombre_nivel(nivel)

		boton.pressed.connect(
			func():
				_on_nivel_seleccionado(nivel)
		)

		vbox.add_child(boton)


func obtener_nombre_nivel(ruta_nivel: String) -> String:

	var nombre = ruta_nivel.get_file()

	nombre = nombre.trim_suffix(".tscn")

	return nombre


func _on_nivel_seleccionado(nivel: String) -> void:

	print("NIVEL SELECCIONADO: ", nivel)


	# El nivel seleccionado pasa a ser el nivel actual.

	Settings.nivelActual = nivel

	Save.guardar_partida()


	$SelectorNiveles.hide()


	# Main se encarga de cargar el nivel.

	continue_game.emit()


func _on_selector_niveles_back_pressed() -> void:

	show_main_menu()


# =========================================================
# LANGUAGE MENU
# =========================================================

func _on_spanish_button_pressed() -> void:

	Settings.language = "es"

	Save.guardar_idioma()

	update_language()

	show_main_menu()


func _on_english_button_pressed() -> void:

	Settings.language = "en"

	Save.guardar_idioma()

	update_language()

	show_main_menu()


func _on_back_button_pressed() -> void:

	show_main_menu()


# =========================================================
# GAME OVER
# =========================================================

func _on_retry_button_pressed() -> void:

	print("REINTENTAR")

	$GameOver.hide()

	retry_game.emit()


func _on_main_menu_button_pressed() -> void:

	print("VOLVER AL MENU")

	main_menu.emit()


# =========================================================
# PAUSE MENU
# =========================================================

func _on_continuar_button_pressed() -> void:

	print("CONTINUAR")

	get_tree().paused = false

	Settings.sePuedePausar = true

	$Pause.hide()


func _on_main_menu_button2_pressed() -> void:

	print("VOLVER AL MENU")

	get_tree().paused = false

	Settings.sePuedePausar = true

	$Pause.hide()

	main_menu.emit()
