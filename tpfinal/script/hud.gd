extends CanvasLayer


signal start_game
signal retry_game
signal main_menu
signal continue_game


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# =====================================================
	# MAIN MENU
	# =====================================================

	$Confirmacion.hide()


	var start_button = (
		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/StartButton
	)

	if not start_button.pressed.is_connected(
		_on_start_button_pressed
	):

		start_button.pressed.connect(
			_on_start_button_pressed
	)


	var continue_button = (
		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/ContinueButton
	)

	if not continue_button.pressed.is_connected(
		_on_continuar_partida_pressed
	):

		continue_button.pressed.connect(
			_on_continuar_partida_pressed
	)


	var selector_button = (
		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/SelectorNiveles
	)

	if not selector_button.pressed.is_connected(
		_on_selector_niveles_pressed
	):

		selector_button.pressed.connect(
			_on_selector_niveles_pressed
	)


	var language_button = (
		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/LanguageButton
	)

	if not language_button.pressed.is_connected(
		_on_language_button_pressed
	):

		language_button.pressed.connect(
		_on_language_button_pressed
	)


	var quit_button = (
		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/QuitGameButton
	)

	if not quit_button.pressed.is_connected(
		_on_quit_game_button_pressed
	):

		quit_button.pressed.connect(
			_on_quit_game_button_pressed
		)


	# =====================================================
	# GAME OVER
	# =====================================================

	var retry_button = (
		$GameOver/CenterContainer/VBoxContainer/RetryButton
	)

	if not retry_button.pressed.is_connected(
		_on_retry_button_pressed
	):

		retry_button.pressed.connect(
			_on_retry_button_pressed
		)


	var game_over_menu_button = (
		$GameOver/CenterContainer/VBoxContainer/MainMenuButton
	)

	if not game_over_menu_button.pressed.is_connected(
		_on_main_menu_button_pressed
	):

		game_over_menu_button.pressed.connect(
			_on_main_menu_button_pressed
		)


	# =====================================================
	# LANGUAGE
	# =====================================================

	var spanish_button = (
		$LanguageMenu/CenterContainer/VBoxContainer/SpanishButton
	)

	if not spanish_button.pressed.is_connected(
		_on_spanish_button_pressed
	):

		spanish_button.pressed.connect(
			_on_spanish_button_pressed
		)


	var english_button = (
		$LanguageMenu/CenterContainer/VBoxContainer/EnglishButton
	)

	if not english_button.pressed.is_connected(
		_on_english_button_pressed
	):

		english_button.pressed.connect(
			_on_english_button_pressed
		)


	var back_button = (
		$LanguageMenu/CenterContainer/VBoxContainer/BackButton
	)

	if not back_button.pressed.is_connected(
		_on_back_button_pressed
	):

		back_button.pressed.connect(
			_on_back_button_pressed
		)


	# =====================================================
	# PAUSE
	# =====================================================

	var continuar_button = (
		$Pause/CenterContainer/VBoxContainer/Continuar
	)

	if not continuar_button.pressed.is_connected(
		_on_continuar_button_pressed
	):

		continuar_button.pressed.connect(
			_on_continuar_button_pressed
		)


	var pause_menu_button = (
		$Pause/CenterContainer/VBoxContainer/MainMenuButton
	)

	if not pause_menu_button.pressed.is_connected(
		_on_main_menu_button2_pressed
	):

		pause_menu_button.pressed.connect(
			_on_main_menu_button2_pressed
		)


	# =====================================================
	# CONFIRMACION
	# =====================================================

	var YesButton = (
		$Confirmacion/CenterContainer/VBoxContainer/YesButton
	)

	if not YesButton.pressed.is_connected(
		_on_yes_button_pressed
	):

		YesButton.pressed.connect(
			_on_yes_button_pressed
		)


	var NoButton = (
		$Confirmacion/CenterContainer/VBoxContainer/NoButton
	)

	if not NoButton.pressed.is_connected(
		_on_no_button_pressed
	):

		NoButton.pressed.connect(
			_on_no_button_pressed
		)


	# =====================================================
	# SELECTOR DE NIVELES
	# =====================================================

	var selector_back_button = (
		$SelectorNiveles/CenterContainer/VBoxContainer/BackButton
	)

	if not selector_back_button.pressed.is_connected(
		_on_selector_niveles_back_pressed
	):

		selector_back_button.pressed.connect(
			_on_selector_niveles_back_pressed
		)


	# =====================================================
	# INICIO
	# =====================================================

	update_language()
	actualizar_estado_botones()
	show_main_menu()


# =========================================================
# NAVEGACIÓN CON TECLADO
# =========================================================
#
# La acción "pausa" NO se procesa acá.
#
# Main.gd se encarga de detectar "pausa".
#
# HUD solamente procesa:
#
# arriba
# abajo
# adelante
#

func _unhandled_input(event: InputEvent) -> void:

	if not event.is_pressed():
		return


	# =====================================================
	# SUBIR
	# =====================================================

	if event.is_action_pressed("arriba"):

		mover_seleccion(-1)

		get_viewport().set_input_as_handled()


	# =====================================================
	# BAJAR
	# =====================================================

	elif event.is_action_pressed("abajo"):

		mover_seleccion(1)

		get_viewport().set_input_as_handled()


	# =====================================================
	# SELECCIONAR
	# =====================================================

	elif event.is_action_pressed("adelante"):

		activar_seleccion()

		get_viewport().set_input_as_handled()


# =========================================================
# OBTENER BOTONES VISIBLES
# =========================================================

func obtener_botones_visibles() -> Array[Button]:

	var botones: Array[Button] = []


	var menus = [
		$MainMenu,
		$GameOver,
		$LanguageMenu,
		$Pause,
		$Confirmacion,
		$SelectorNiveles
	]


	for menu in menus:

		if not menu.visible:
			continue


		var botones_menu = buscar_botones(
			menu
		)


		for boton in botones_menu:

			if not boton.disabled and boton.visible:

				botones.append(
					boton
				)


	return botones


# =========================================================
# BUSCAR BOTONES
# =========================================================

func buscar_botones(
	nodo: Node
) -> Array[Button]:

	var resultado: Array[Button] = []


	for hijo in nodo.get_children():

		if hijo is Button:

			resultado.append(
				hijo
			)


		resultado.append_array(
			buscar_botones(hijo)
		)


	return resultado


# =========================================================
# MOVER SELECCIÓN
# =========================================================

func mover_seleccion(
	direccion: int
) -> void:

	var botones = (
		obtener_botones_visibles()
	)


	if botones.is_empty():
		return


	var boton_actual = (
		get_viewport().gui_get_focus_owner()
	)


	var indice_actual = (
		botones.find(
			boton_actual
		)
	)


	if indice_actual == -1:

		botones[0].grab_focus()

		return


	var nuevo_indice = (
		indice_actual + direccion
	)


	if nuevo_indice < 0:

		nuevo_indice = 0


	if nuevo_indice >= botones.size():

		nuevo_indice = (
			botones.size() - 1
		)


	botones[
		nuevo_indice
	].grab_focus()


# =========================================================
# ACTIVAR SELECCIÓN
# =========================================================

func activar_seleccion() -> void:

	var boton_actual = (
		get_viewport().gui_get_focus_owner()
	)


	if boton_actual is Button:

		if not boton_actual.disabled:

			boton_actual.pressed.emit()


# =========================================================
# MENÚ PRINCIPAL
# =========================================================

func show_main_menu() -> void:

	$MainMenu.show()

	$GameOver.hide()

	$LanguageMenu.hide()

	$Pause.hide()

	$SelectorNiveles.hide()

	$Confirmacion.hide()


	actualizar_estado_botones()


	$MainMenu/MarginContainer/CenterContainer/VBoxContainer/StartButton.grab_focus()


# =========================================================
# GAME OVER
# =========================================================

func show_game_over() -> void:

	$MainMenu.hide()

	$GameOver.show()

	$LanguageMenu.hide()

	$Pause.hide()

	$SelectorNiveles.hide()

	$Confirmacion.hide()


	$GameOver/CenterContainer/VBoxContainer/RetryButton.grab_focus()


# =========================================================
# MENÚ IDIOMA
# =========================================================

func show_language_menu() -> void:

	$MainMenu.hide()

	$GameOver.hide()

	$LanguageMenu.show()

	$Pause.hide()

	$SelectorNiveles.hide()

	$Confirmacion.hide()


	$LanguageMenu/CenterContainer/VBoxContainer/SpanishButton.grab_focus()


# =========================================================
# MENÚ PAUSA
# =========================================================

func show_pause_menu() -> void:

	$MainMenu.hide()

	$Pause.show()

	$LanguageMenu.hide()

	$GameOver.hide()

	$SelectorNiveles.hide()

	$Confirmacion.hide()


	$Pause/CenterContainer/VBoxContainer/Continuar.grab_focus()


# =========================================================
# SELECTOR DE NIVELES
# =========================================================

func show_selector_niveles() -> void:

	$MainMenu.hide()

	$GameOver.hide()

	$LanguageMenu.hide()

	$Pause.hide()

	$SelectorNiveles.show()

	$Confirmacion.hide()


	actualizar_selector_niveles()


# =========================================================
# IDIOMA
# =========================================================

func update_language() -> void:

	if Settings.language == "es":

		# =================================================
		# MAIN MENU
		# =================================================

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/Title.text = (
			"Eva Two Tales Kitsune"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/StartButton.text = (
			"Nueva partida"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/ContinueButton.text = (
			"Continuar"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/SelectorNiveles.text = (
			"Selector de niveles"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/LanguageButton.text = (
			"Idioma"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/QuitGameButton.text = (
			"Cerrar juego"
		)


		# =================================================
		# GAME OVER
		# =================================================

		$GameOver/CenterContainer/VBoxContainer/Message.text = (
			"Game Over"
		)

		$GameOver/CenterContainer/VBoxContainer/RetryButton.text = (
			"Reintentar"
		)

		$GameOver/CenterContainer/VBoxContainer/MainMenuButton.text = (
			"Menú principal"
		)


		# =================================================
		# LANGUAGE
		# =================================================

		$LanguageMenu/CenterContainer/VBoxContainer/Title.text = (
			"Idioma"
		)

		$LanguageMenu/CenterContainer/VBoxContainer/SpanishButton.text = (
			"Español"
		)

		$LanguageMenu/CenterContainer/VBoxContainer/EnglishButton.text = (
			"English"
		)

		$LanguageMenu/CenterContainer/VBoxContainer/BackButton.text = (
			"Volver"
		)


		# =================================================
		# PAUSE
		# =================================================

		$Pause/CenterContainer/VBoxContainer/Message.text = (
			"Pausa"
		)

		$Pause/CenterContainer/VBoxContainer/Continuar.text = (
			"Continuar"
		)

		$Pause/CenterContainer/VBoxContainer/MainMenuButton.text = (
			"Volver al menú principal"
		)


		# =================================================
		# SELECTOR
		# =================================================

		$SelectorNiveles/CenterContainer/VBoxContainer/Title.text = (
			"Selector de niveles"
		)

		$SelectorNiveles/CenterContainer/VBoxContainer/BackButton.text = (
			"Volver"
		)


		# =================================================
		# CONFIRMACION
		# =================================================

		$Confirmacion/CenterContainer/VBoxContainer/Message.text = (
			"¿Está seguro de que desea iniciar una nueva partida? Los datos actuales se borrarán."
		)

		$Confirmacion/CenterContainer/VBoxContainer/YesButton.text = (
			"Sí"
		)

		$Confirmacion/CenterContainer/VBoxContainer/NoButton.text = (
			"No"
		)


	elif Settings.language == "en":

		# =================================================
		# MAIN MENU
		# =================================================

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/Title.text = (
			"Eva Two Tales Kitsune"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/StartButton.text = (
			"New Game"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/ContinueButton.text = (
			"Continue"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/SelectorNiveles.text = (
			"Level Select"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/LanguageButton.text = (
			"Language"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/QuitGameButton.text = (
			"Quit Game"
		)


		# =================================================
		# GAME OVER
		# =================================================

		$GameOver/CenterContainer/VBoxContainer/Message.text = (
			"Game Over"
		)

		$GameOver/CenterContainer/VBoxContainer/RetryButton.text = (
			"Retry"
		)

		$GameOver/CenterContainer/VBoxContainer/MainMenuButton.text = (
			"Main Menu"
		)


		# =================================================
		# LANGUAGE
		# =================================================

		$LanguageMenu/CenterContainer/VBoxContainer/Title.text = (
			"Language"
		)

		$LanguageMenu/CenterContainer/VBoxContainer/SpanishButton.text = (
			"Español"
		)

		$LanguageMenu/CenterContainer/VBoxContainer/EnglishButton.text = (
			"English"
		)

		$LanguageMenu/CenterContainer/VBoxContainer/BackButton.text = (
			"Back"
		)


		# =================================================
		# PAUSE
		# =================================================

		$Pause/CenterContainer/VBoxContainer/Message.text = (
			"Pause"
		)

		$Pause/CenterContainer/VBoxContainer/Continuar.text = (
			"Resume"
		)

		$Pause/CenterContainer/VBoxContainer/MainMenuButton.text = (
			"Back to Main Menu"
		)


		# =================================================
		# SELECTOR
		# =================================================

		$SelectorNiveles/CenterContainer/VBoxContainer/Title.text = (
			"Level Select"
		)

		$SelectorNiveles/CenterContainer/VBoxContainer/BackButton.text = (
			"Back"
		)


		# =================================================
		# CONFIRMACION
		# =================================================

		$Confirmacion/CenterContainer/VBoxContainer/Message.text = (
			"Are you sure you want to start a new game? Current data will be deleted."
		)

		$Confirmacion/CenterContainer/VBoxContainer/YesButton.text = (
			"Yes"
		)

		$Confirmacion/CenterContainer/VBoxContainer/NoButton.text = (
			"No"
		)


# =========================================================
# ESTADO DE LOS BOTONES
# =========================================================

func actualizar_estado_botones() -> void:

	var hay_partida = Save.existe_partida()


	$MainMenu/MarginContainer/CenterContainer/VBoxContainer/ContinueButton.disabled = (
		not hay_partida
	)


	$MainMenu/MarginContainer/CenterContainer/VBoxContainer/SelectorNiveles.disabled = (
		not hay_partida
		or Settings.nivelesCompletados.is_empty()
	)


# =========================================================
# NUEVA PARTIDA
# =========================================================

func _on_start_button_pressed() -> void:

	if Save.existe_partida():

		$Confirmacion.show()

		$MainMenu.hide()

		$Confirmacion/CenterContainer/VBoxContainer/YesButton.grab_focus()

	else:

		Save.iniciar_nueva_partida()

		$MainMenu.hide()

		start_game.emit()


# =========================================================
# CONFIRMAR NUEVA PARTIDA
# =========================================================

func _on_yes_button_pressed() -> void:

	Save.iniciar_nueva_partida()

	$Confirmacion.hide()

	$MainMenu.hide()

	start_game.emit()


# =========================================================
# CANCELAR NUEVA PARTIDA
# =========================================================

func _on_no_button_pressed() -> void:

	$Confirmacion.hide()

	$MainMenu.show()

	$MainMenu/MarginContainer/CenterContainer/VBoxContainer/StartButton.grab_focus()


# =========================================================
# IDIOMA
# =========================================================

func _on_language_button_pressed() -> void:

	show_language_menu()


# =========================================================
# CERRAR JUEGO
# =========================================================

func _on_quit_game_button_pressed() -> void:

	get_tree().quit()


# =========================================================
# CONTINUAR PARTIDA
# =========================================================

func _on_continuar_partida_pressed() -> void:

	if not Save.cargar_partida():

		return


	if Settings.nivelActual == "":

		return


	$MainMenu.hide()

	continue_game.emit()


# =========================================================
# SELECTOR DE NIVELES
# =========================================================

func _on_selector_niveles_pressed() -> void:

	if not Save.existe_partida():

		return


	Save.cargar_partida()

	show_selector_niveles()


# =========================================================
# ACTUALIZAR SELECTOR DE NIVELES
# =========================================================

func actualizar_selector_niveles() -> void:

	var vbox = (
		$SelectorNiveles/CenterContainer/VBoxContainer
	)


	for hijo in vbox.get_children():

		if (
			hijo.name != "Title"
			and hijo.name != "BackButton"
		):

			hijo.queue_free()


	for nivel in Settings.nivelesCompletados:

		var boton = Button.new()


		boton.text = (
			obtener_nombre_nivel(nivel)
		)


		boton.pressed.connect(
			func():
				_on_nivel_seleccionado(nivel)
		)


		vbox.add_child(
			boton
		)


	await get_tree().process_frame


	var botones = (
		obtener_botones_visibles()
	)


	if not botones.is_empty():

		botones[0].grab_focus()


# =========================================================
# OBTENER NOMBRE DEL NIVEL
# =========================================================

func obtener_nombre_nivel(
	ruta_nivel: String
) -> String:

	var nombre = (
		ruta_nivel.get_file()
	)


	nombre = (
		nombre.trim_suffix(".tscn")
	)


	return nombre


# =========================================================
# NIVEL SELECCIONADO
# =========================================================

func _on_nivel_seleccionado(
	nivel: String
) -> void:

	Settings.nivelActual = nivel

	Save.guardar_partida()

	$SelectorNiveles.hide()

	continue_game.emit()


# =========================================================
# VOLVER DESDE SELECTOR
# =========================================================

func _on_selector_niveles_back_pressed() -> void:

	show_main_menu()


# =========================================================
# ESPAÑOL
# =========================================================

func _on_spanish_button_pressed() -> void:

	Settings.language = "es"

	Save.guardar_idioma()

	update_language()

	show_main_menu()


# =========================================================
# INGLÉS
# =========================================================

func _on_english_button_pressed() -> void:

	Settings.language = "en"

	Save.guardar_idioma()

	update_language()

	show_main_menu()


# =========================================================
# VOLVER DESDE IDIOMA
# =========================================================

func _on_back_button_pressed() -> void:

	show_main_menu()


# =========================================================
# GAME OVER: REINTENTAR
# =========================================================

func _on_retry_button_pressed() -> void:

	$GameOver.hide()

	retry_game.emit()


# =========================================================
# GAME OVER: MENÚ PRINCIPAL
# =========================================================

func _on_main_menu_button_pressed() -> void:

	main_menu.emit()

	Settings.checkpoint = 0


# =========================================================
# PAUSA: CONTINUAR
# =========================================================

func _on_continuar_button_pressed() -> void:

	get_tree().paused = false

	Settings.sePuedePausar = true

	$Pause.hide()


# =========================================================
# PAUSA: MENÚ PRINCIPAL
# =========================================================

func _on_main_menu_button2_pressed() -> void:

	get_tree().paused = false

	$Pause.hide()

	main_menu.emit()

	Settings.checkpoint = 0
