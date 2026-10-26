extends CanvasLayer


signal start_game
signal retry_game
signal main_menu
signal continue_game

# Estado temporal de la confirmación de transferencia.
var confirmando_transferencia_disco: bool = false
var disco_destino_pendiente: String = ""
var mostrando_advertencia_disco: bool = false
var pantallas_visibles_antes_de_advertencia: Array[Control] = []
var panel_advertencia_disco: PanelContainer
var etiqueta_advertencia_disco: Label


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# =====================================================
	# MAIN MENU
	# =====================================================

	$Confirmacion.hide()
	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()
	_crear_panel_advertencia_disco()

	# Configurar la pantalla de sonido y cargar los volúmenes guardados.
	_configurar_pantalla_sonido()
	_cargar_volumenes()


	# =====================================================
	# CARGAR PARTIDA GUARDADA
	# =====================================================
	# Recuperar los niveles completados antes de actualizar
	# el estado de los botones del menú.
	# Esto también funciona si la partida está finalizada.

	if FileAccess.file_exists(Save.RUTA_GUARDADO):
		Save.cargar_partida()


	# =====================================================
	# CONECTAR BOTONES DEL MENÚ PRINCIPAL
	# =====================================================

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


	# El botón del menú principal abre la pantalla Opciones.
	# Se admiten los nombres habituales para evitar depender de uno solo.
	var opciones_button: Button = null
	var ruta_opciones_button = $MainMenu/MarginContainer/CenterContainer/VBoxContainer.get_node_or_null("Opciones")
	if ruta_opciones_button == null:
		ruta_opciones_button = $MainMenu/MarginContainer/CenterContainer/VBoxContainer.get_node_or_null("OpcionesButton")
	if ruta_opciones_button == null:
		ruta_opciones_button = $MainMenu/MarginContainer/CenterContainer/VBoxContainer.get_node_or_null("OptionsButton")
	if ruta_opciones_button == null:
		ruta_opciones_button = $MainMenu/MarginContainer/CenterContainer/VBoxContainer.get_node_or_null("Options")
	if ruta_opciones_button is Button:
		opciones_button = ruta_opciones_button
		if not opciones_button.pressed.is_connected(_on_opciones_button_pressed):
			opciones_button.pressed.connect(_on_opciones_button_pressed)

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
	# OPCIONES
	# =====================================================

	var opciones_vbox = $Opciones/MarginContainer/CenterContainer/VBoxContainer
	var opciones_back_button = opciones_vbox.get_node_or_null("BackButton")
	if opciones_back_button is Button and not opciones_back_button.pressed.is_connected(_on_opciones_back_button_pressed):
		opciones_back_button.pressed.connect(_on_opciones_back_button_pressed)

	var opciones_sonido_button = opciones_vbox.get_node_or_null("Sonido")
	if opciones_sonido_button is Button and not opciones_sonido_button.pressed.is_connected(_on_sonido_button_pressed):
		opciones_sonido_button.pressed.connect(_on_sonido_button_pressed)

	var opciones_language_button = opciones_vbox.get_node_or_null("LanguageButton")
	if opciones_language_button is Button and not opciones_language_button.pressed.is_connected(_on_language_button_pressed):
		opciones_language_button.pressed.connect(_on_language_button_pressed)

	var opciones_disco_button = opciones_vbox.get_node_or_null("Disco")
	if opciones_disco_button is Button and not opciones_disco_button.pressed.is_connected(_on_disco_button_pressed):
		opciones_disco_button.pressed.connect(_on_disco_button_pressed)


	# =====================================================
	# DISCO
	# =====================================================

	var c_button = $Disco/CenterContainer/VBoxContainer/cButton
	if not c_button.pressed.is_connected(_on_c_button_pressed):
		c_button.pressed.connect(_on_c_button_pressed)

	var d_button = $Disco/CenterContainer/VBoxContainer/dButton
	if not d_button.pressed.is_connected(_on_d_button_pressed):
		d_button.pressed.connect(_on_d_button_pressed)

	var disco_back_button = $Disco/CenterContainer/VBoxContainer/BackButton
	if not disco_back_button.pressed.is_connected(_on_disco_back_button_pressed):
		disco_back_button.pressed.connect(_on_disco_back_button_pressed)


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



func actualizar_menu_discos() -> void:
	var titulo: Label = $Disco/CenterContainer/VBoxContainer/Title2
	var c_button: Button = $Disco/CenterContainer/VBoxContainer/cButton
	var d_button: Button = $Disco/CenterContainer/VBoxContainer/dButton

	if Settings.language == "es":
		titulo.text = "Disco actual: " + Save.DISCO_ACTUAL
	else:
		titulo.text = "Current disk: " + Save.DISCO_ACTUAL

	# El disco actual queda deshabilitado para evitar seleccionarlo.
	c_button.disabled = Save.DISCO_ACTUAL == "C"
	d_button.disabled = Save.DISCO_ACTUAL == "D"
# =========================================================
# ADVERTENCIAS DE DISCO
# =========================================================

func _process(_delta: float) -> void:
	# Save.advertencia_disco permite detectar fallos de escritura que ocurran
	# desde otras partes del juego, no solamente desde estos botones.
	if confirmando_transferencia_disco:
		return

	if not Save.advertencia_disco.is_empty() and not mostrando_advertencia_disco:
		var mensaje: String = str(Save.advertencia_disco)
		Save.advertencia_disco = ""
		_mostrar_advertencia_disco(mensaje)


func _crear_panel_advertencia_disco() -> void:
	panel_advertencia_disco = PanelContainer.new()
	panel_advertencia_disco.name = "AdvertenciaDiscoPanel"
	panel_advertencia_disco.anchor_left = 0.15
	panel_advertencia_disco.anchor_top = 0.35
	panel_advertencia_disco.anchor_right = 0.85
	panel_advertencia_disco.anchor_bottom = 0.65
	panel_advertencia_disco.offset_left = 0
	panel_advertencia_disco.offset_top = 0
	panel_advertencia_disco.offset_right = 0
	panel_advertencia_disco.offset_bottom = 0
	panel_advertencia_disco.z_index = 100
	panel_advertencia_disco.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel_advertencia_disco)

	etiqueta_advertencia_disco = Label.new()
	etiqueta_advertencia_disco.name = "Mensaje"
	etiqueta_advertencia_disco.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_advertencia_disco.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta_advertencia_disco.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_advertencia_disco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta_advertencia_disco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_advertencia_disco.add_child(etiqueta_advertencia_disco)

	panel_advertencia_disco.hide()


func _mostrar_advertencia_disco(mensaje: String) -> void:
	if mostrando_advertencia_disco:
		return

	mostrando_advertencia_disco = true
	pantallas_visibles_antes_de_advertencia.clear()

	var pantallas: Array[Control] = [
		$MainMenu,
		$GameOver,
		$Opciones,
		$LanguageMenu,
		$Disco,
		$Pause,
		$Confirmacion,
		$SelectorNiveles,
		$Sonido
	]

	for pantalla in pantallas:
		if pantalla.visible:
			pantallas_visibles_antes_de_advertencia.append(pantalla)
			pantalla.hide()

	var mensaje_minusculas := mensaje.to_lower()
	if mensaje_minusculas.contains("espacio") or mensaje_minusculas.contains("lleno"):
		if Settings.language == "en":
			etiqueta_advertencia_disco.text = "The disk you are trying to write to is full.\n" + mensaje
		else:
			etiqueta_advertencia_disco.text = "El disco al que intentas escribir está lleno.\n" + mensaje
	else:
		etiqueta_advertencia_disco.text = mensaje

	panel_advertencia_disco.show()
	await get_tree().create_timer(5.0).timeout

	panel_advertencia_disco.hide()
	for pantalla in pantallas_visibles_antes_de_advertencia:
		if is_instance_valid(pantalla):
			pantalla.show()

	pantallas_visibles_antes_de_advertencia.clear()
	mostrando_advertencia_disco = false


# =========================================================
# CONFIRMACIÓN PARA SOBRESCRIBIR UN DISCO
# Se reutiliza LanguageMenu: los botones pasan a ser Sí y No.
# =========================================================

func _mostrar_confirmacion_transferencia(disco_destino: String) -> void:
	confirmando_transferencia_disco = true
	disco_destino_pendiente = disco_destino
	Save.advertencia_disco = ""

	$MainMenu.hide()
	$GameOver.hide()
	$Opciones.hide()
	$Sonido.hide()
	$Disco.hide()
	$Pause.hide()
	$SelectorNiveles.hide()
	$Confirmacion.hide()

	var vbox = $LanguageMenu/CenterContainer/VBoxContainer
	vbox.get_node("Title").text = (
		"El disco " + disco_destino + " ya contiene una partida de Eva. "
		+ "Si continúas, se borrará ese archivo y se reemplazará por la partida "
		+ "del disco " + Save.DISCO_ACTUAL + ". ¿Quieres continuar?"
		if Settings.language == "es"
		else
		"Disk " + disco_destino + " already contains an Eva save. "
		+ "If you continue, that file will be deleted and replaced with the save "
		+ "from disk " + Save.DISCO_ACTUAL + ". Do you want to continue?"
	)

	var boton_espanol: Button = vbox.get_node("SpanishButton")
	var boton_ingles: Button = vbox.get_node("EnglishButton")
	var boton_volver = vbox.get_node_or_null("BackButton")

	boton_espanol.text = "Sí" if Settings.language == "es" else "Yes"
	boton_ingles.text = "No"
	boton_espanol.show()
	boton_ingles.show()
	if boton_volver is Control:
		boton_volver.hide()

	$LanguageMenu.show()
	boton_espanol.grab_focus()


func _resolver_confirmacion_transferencia(aceptar: bool) -> void:
	if not confirmando_transferencia_disco:
		return

	var disco_destino := disco_destino_pendiente
	confirmando_transferencia_disco = false
	disco_destino_pendiente = ""

	# Restaurar el botón oculto antes de volver a usar la pantalla de idioma.
	var boton_volver_idioma = $LanguageMenu/CenterContainer/VBoxContainer.get_node_or_null("BackButton")
	if boton_volver_idioma is Control:
		boton_volver_idioma.show()

	if not aceptar:
		update_language()
		show_disco_menu()
		return

	var disco_origen: String = str(Save.DISCO_ACTUAL)
	var carpeta_origen := Save.CARPETA_GUARDADO

	# Cambiar temporalmente la ruta activa al destino para usar la escritura
	# destructiva solicitada. El origen se conserva hasta que la escritura acabe.
	Save._configurar_disco(disco_destino)
	if not Save.escribir_en_disco():
		var mensaje: String = str(Save.advertencia_disco)
		Save._configurar_disco(disco_origen)
		Save.advertencia_disco = ""
		update_language()
		show_opciones()
		_mostrar_advertencia_disco(mensaje if not mensaje.is_empty() else "No se pudo escribir en el disco " + disco_destino + ".")
		return

	# Solo se borra el origen después de que la escritura en el destino termine.
	if not Save._borrar_carpeta_completa(carpeta_origen):
		Save.advertencia_disco = "La partida se escribió en el disco " + disco_destino + ", pero no se pudo borrar la carpeta anterior del disco " + disco_origen + ". Hay una copia adicional."
		update_language()
		show_opciones()
		return

	Save.advertencia_disco = ""
	update_language()
	show_opciones()


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
		$Opciones,
		$LanguageMenu,
		$Disco,
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

	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()
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

	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()
	$MainMenu.hide()

	$GameOver.show()

	$LanguageMenu.hide()

	$Pause.hide()

	$SelectorNiveles.hide()

	$Confirmacion.hide()


	$GameOver/CenterContainer/VBoxContainer/RetryButton.grab_focus()


# =========================================================
# MENÚ OPCIONES
# =========================================================

func show_opciones() -> void:
	$MainMenu.hide()
	$GameOver.hide()
	$LanguageMenu.hide()
	$Sonido.hide()
	$Disco.hide()
	$Pause.hide()
	$SelectorNiveles.hide()
	$Confirmacion.hide()
	$Opciones.show()
	var vbox = $Opciones/MarginContainer/CenterContainer/VBoxContainer
	var primer_boton = vbox.get_node_or_null("LanguageButton")
	if primer_boton == null:
		primer_boton = vbox.get_node_or_null("Sonido")
	if primer_boton == null:
		primer_boton = vbox.get_node_or_null("Disco")
	if primer_boton is Control:
		primer_boton.grab_focus()

func show_disco_menu() -> void:
	$MainMenu.hide()
	$GameOver.hide()
	$LanguageMenu.hide()
	$Sonido.hide()
	$Opciones.hide()
	$Pause.hide()
	$SelectorNiveles.hide()
	$Confirmacion.hide()

	actualizar_menu_discos()
	$Disco.show()

	var c_button: Button = $Disco/CenterContainer/VBoxContainer/cButton
	var d_button: Button = $Disco/CenterContainer/VBoxContainer/dButton

	if not c_button.disabled:
		c_button.grab_focus()
	elif not d_button.disabled:
		d_button.grab_focus()
	else:
		$Disco/CenterContainer/VBoxContainer/BackButton.grab_focus()
# =========================================================
# MENÚ IDIOMA
# =========================================================

func show_language_menu() -> void:

	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()
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

	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()
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

	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()
	$MainMenu.hide()

	$GameOver.hide()

	$LanguageMenu.hide()

	$Pause.hide()

	$SelectorNiveles.show()

	$Confirmacion.hide()


	actualizar_selector_niveles()


func _actualizar_texto_boton_opciones_menu(texto: String) -> void:
	var vbox = $MainMenu/MarginContainer/CenterContainer/VBoxContainer
	for nombre in ["Opciones", "OpcionesButton", "OptionsButton", "Options"]:
		var boton = vbox.get_node_or_null(nombre)
		if boton is Button:
			boton.text = texto
			return


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
		_actualizar_texto_boton_opciones_menu("Opciones")

		$Opciones/MarginContainer/CenterContainer/VBoxContainer/LanguageButton.text = (
			"Idioma"
		)

		$Opciones/MarginContainer/CenterContainer/VBoxContainer/Sonido.text = (
			"Sonido"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/QuitGameButton.text = (
			"Cerrar juego"
		)


		$Sonido/CenterContainer/VBoxContainer/LabelSonido.text = "Efectos de sonido"
		$Sonido/CenterContainer/VBoxContainer/LabelMusica.text = "Música"
		$Sonido/CenterContainer/VBoxContainer/LabelVoces.text = "Voces"
		$Sonido/CenterContainer/VBoxContainer/BackButton.text = "Volver"


		$Opciones/MarginContainer/CenterContainer/VBoxContainer/LanguageButton.text = "Idioma"
		$Opciones/MarginContainer/CenterContainer/VBoxContainer/Sonido.text = "Sonido"
		$Opciones/MarginContainer/CenterContainer/VBoxContainer/Disco.text = "Disco"
		var opciones_back = $Opciones/MarginContainer/CenterContainer/VBoxContainer.get_node_or_null("BackButton")
		if opciones_back is Button:
			opciones_back.text = "Volver"

		$Disco/CenterContainer/VBoxContainer/Title.text = "Disco"
		$Disco/CenterContainer/VBoxContainer/cButton.text = "Disco C"
		$Disco/CenterContainer/VBoxContainer/dButton.text = "Disco D"
		$Disco/CenterContainer/VBoxContainer/BackButton.text = "Volver"

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
		_actualizar_texto_boton_opciones_menu("Options")

		$Opciones/MarginContainer/CenterContainer/VBoxContainer/LanguageButton.text = (
			"Language"
		)

		$Opciones/MarginContainer/CenterContainer/VBoxContainer/Sonido.text = (
			"Sound"
		)

		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/QuitGameButton.text = (
			"Quit Game"
		)


		$Sonido/CenterContainer/VBoxContainer/LabelSonido.text = "Sound Effects"
		$Sonido/CenterContainer/VBoxContainer/LabelMusica.text = "Music"
		$Sonido/CenterContainer/VBoxContainer/LabelVoces.text = "Voices"
		$Sonido/CenterContainer/VBoxContainer/BackButton.text = "Back"

		$Opciones/MarginContainer/CenterContainer/VBoxContainer/LanguageButton.text = "Language"
		$Opciones/MarginContainer/CenterContainer/VBoxContainer/Sonido.text = "Sound"
		$Opciones/MarginContainer/CenterContainer/VBoxContainer/Disco.text = "Disk"
		var opciones_back_en = $Opciones/MarginContainer/CenterContainer/VBoxContainer.get_node_or_null("BackButton")
		if opciones_back_en is Button:
			opciones_back_en.text = "Back"

		$Disco/CenterContainer/VBoxContainer/Title.text = "Disk"
		$Disco/CenterContainer/VBoxContainer/cButton.text = "Disk C"
		$Disco/CenterContainer/VBoxContainer/dButton.text = "Disk D"
		$Disco/CenterContainer/VBoxContainer/BackButton.text = "Back"

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
		
	if is_node_ready():
		actualizar_menu_discos()


# =========================================================
# ESTADO DE LOS BOTONES
# =========================================================

func actualizar_estado_botones() -> void:
	var hay_partida = Save.existe_partida()

	var boton_continuar = (
		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/ContinueButton
	)

	var boton_selector = (
		$MainMenu/MarginContainer/CenterContainer/VBoxContainer/SelectorNiveles
	)

	# Continuar solo funciona si hay una partida activa.
	boton_continuar.disabled = not hay_partida

	# El selector se habilita si hay al menos un nivel completado.
	boton_selector.disabled = Settings.obtener_ids_niveles_completados().is_empty()

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

func _on_opciones_button_pressed() -> void:
	show_opciones()


func _on_opciones_back_button_pressed() -> void:
	show_main_menu()


func _on_language_button_pressed() -> void:
	show_language_menu()


func _on_disco_button_pressed() -> void:
	show_disco_menu()


func _on_c_button_pressed() -> void:
	_intentar_cambiar_disco("C")


func _on_d_button_pressed() -> void:
	_intentar_cambiar_disco("D")


func _intentar_cambiar_disco(disco_destino: String) -> void:
	if disco_destino == Save.DISCO_ACTUAL:
		Save.advertencia_disco = ""
		show_opciones()
		return

	var carpeta_origen := Save.CARPETA_GUARDADO
	var carpeta_destino: String = "C:/" + str(Save.NOMBRE_CARPETA_GUARDADO) if disco_destino == "C" else "D:/" + str(Save.NOMBRE_CARPETA_GUARDADO)
	var existe_partida_origen := FileAccess.file_exists(carpeta_origen.path_join("partida.save"))
	var existe_partida_destino := FileAccess.file_exists(carpeta_destino.path_join("partida.save"))

	var transferencia_correcta: bool
	if disco_destino == "C":
		transferencia_correcta = Save.cambiar_a_c()
	else:
		transferencia_correcta = Save.cambiar_a_d()

	if transferencia_correcta:
		Save.advertencia_disco = ""
		show_opciones()
		return

	var mensaje: String = str(Save.advertencia_disco)
	Save.advertencia_disco = ""

	# Solo pedir confirmación destructiva cuando hay una partida de Eva en
	# ambos discos. Si no, se muestra la advertencia normal de Save.
	if existe_partida_origen and existe_partida_destino:
		_mostrar_confirmacion_transferencia(disco_destino)
		return

	show_opciones()
	if not mensaje.is_empty():
		_mostrar_advertencia_disco(mensaje)


func _on_disco_back_button_pressed() -> void:
	show_opciones()


# =========================================================
# CERRAR JUEGO
# =========================================================

func _on_quit_game_button_pressed() -> void:

	get_tree().quit()


# =========================================================
# CONTINUAR PARTIDA
# =========================================================

func _on_continuar_partida_pressed() -> void:

	if not Save.existe_partida():
		actualizar_estado_botones()
		return

	if not Save.cargar_partida():
		return

	if Save.partidaFinalizada:
		actualizar_estado_botones()
		return

	if Settings.nivelActual == "":
		actualizar_estado_botones()
		return

	$MainMenu.hide()

	continue_game.emit()


# =========================================================
# SELECTOR DE NIVELES
# =========================================================

func _on_selector_niveles_pressed() -> void:
	# Cargar los datos guardados aunque la partida haya terminado.
	if not Save.cargar_partida():
		actualizar_estado_botones()
		return

	# No hay niveles disponibles si nunca se completó ninguno.
	if Settings.obtener_ids_niveles_completados().is_empty():
		actualizar_estado_botones()
		return

	show_selector_niveles()

# =========================================================
# ACTUALIZAR SELECTOR DE NIVELES
# =========================================================


func actualizar_selector_niveles() -> void:
	var vbox = $SelectorNiveles/CenterContainer/VBoxContainer
	var titulo: Control = vbox.get_node("Title")
	var boton_volver: Button = vbox.get_node("BackButton")

	# Eliminar los botones dinámicos anteriores.
	for hijo in vbox.get_children():
		if hijo is Button and hijo != boton_volver and hijo != titulo:
			vbox.remove_child(hijo)
			hijo.queue_free()

	vbox.move_child(titulo, 0)

	# Crear un botón por cada nivel completado.
	for nivel in Settings.registro_niveles:
		if not bool(nivel.get("completado", false)):
			continue

		var id_nivel: int = int(nivel.get("id", 0))
		var ruta_nivel: String = str(nivel.get("ruta", ""))

		if id_nivel <= 0:
			push_warning("Hay un nivel con un ID inválido en Settings.")
			continue

		if ruta_nivel.is_empty():
			push_warning(
				"El nivel " + str(id_nivel)
				+ " no tiene una ruta configurada en Settings."
			)
			continue

		var boton := Button.new()
		boton.name = "Nivel_" + str(id_nivel)
		boton.text = Settings.obtener_nombre_nivel(id_nivel)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		boton.pressed.connect(
			_on_nivel_seleccionado.bind(ruta_nivel)
		)

		vbox.add_child(boton)
		vbox.move_child(boton, boton_volver.get_index())

	vbox.move_child(boton_volver, vbox.get_child_count() - 1)

	await get_tree().process_frame

	for hijo in vbox.get_children():
		if hijo is Button and hijo != boton_volver and not hijo.disabled:
			hijo.grab_focus()
			return

	boton_volver.grab_focus()



func obtener_nombre_nivel(ruta_nivel: String) -> String:
	var nivel: Dictionary = Settings.obtener_nivel_por_ruta(ruta_nivel)

	if nivel.is_empty():
		return ruta_nivel.get_file().get_basename()

	return Settings.obtener_nombre_nivel(int(nivel["id"]))
# =========================================================
# NIVEL SELECCIONADO
# =========================================================


func _on_nivel_seleccionado(ruta_nivel: String) -> void:
	var escena := load(ruta_nivel) as PackedScene

	if escena == null:
		push_error("No se pudo cargar el nivel: " + ruta_nivel)
		return

	Settings.nivelActual = ruta_nivel
	Save.partidaFinalizada = false
	Save.guardar_partida()

	$SelectorNiveles.hide()

	var main = Settings.getMain()
	if main == null:
		push_error("No se encontró Main para cargar el nivel")
		return

	main.load_level(escena)

# =========================================================
# VOLVER DESDE SELECTOR
# =========================================================

func _on_selector_niveles_back_pressed() -> void:

	show_main_menu()


# =========================================================
# PANTALLA DE SONIDO
# =========================================================

const RUTA_OPCIONES_SONIDO := "user://opciones.cfg"


func _configurar_pantalla_sonido() -> void:

	var vbox_sonido = $Sonido/CenterContainer/VBoxContainer

	var sonido_slider: HSlider = vbox_sonido.get_node("SonidoSlider")
	var musica_slider: HSlider = vbox_sonido.get_node("MusicaSlider")
	var voces_slider: HSlider = vbox_sonido.get_node("VocesSlider")
	var back_button: Button = vbox_sonido.get_node("BackButton")


	# Los tres deslizadores usan porcentajes de 0 a 100.
	for slider in [sonido_slider, musica_slider, voces_slider]:

		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1


	if not sonido_slider.value_changed.is_connected(
		_on_sonido_slider_changed
	):
		sonido_slider.value_changed.connect(
			_on_sonido_slider_changed
		)


	if not musica_slider.value_changed.is_connected(
		_on_musica_slider_changed
	):
		musica_slider.value_changed.connect(
			_on_musica_slider_changed
		)


	if not voces_slider.value_changed.is_connected(
		_on_voces_slider_changed
	):
		voces_slider.value_changed.connect(
			_on_voces_slider_changed
		)


	if not back_button.pressed.is_connected(
		_on_sonido_back_button_pressed
	):
		back_button.pressed.connect(
			_on_sonido_back_button_pressed
		)


func _on_sonido_button_pressed() -> void:

	print("1. Se presionó Sonido")

	$MainMenu.hide()
	$GameOver.hide()
	$LanguageMenu.hide()
	$Opciones.hide()
	$Disco.hide()
	$Pause.hide()
	$SelectorNiveles.hide()
	$Confirmacion.hide()

	print("2. Voy a mostrar la pantalla")

	$Sonido.show()

	print("3. Pantalla mostrada")

	$Sonido/CenterContainer/VBoxContainer/SonidoSlider.grab_focus()

	print("4. Foco asignado")


func _on_sonido_back_button_pressed() -> void:
	show_opciones()


func _on_sonido_slider_changed(valor: float) -> void:

	_cambiar_volumen_bus("Sonido", valor)
	_guardar_volumenes()


func _on_musica_slider_changed(valor: float) -> void:

	_cambiar_volumen_bus("Musica", valor)
	_guardar_volumenes()


func _on_voces_slider_changed(valor: float) -> void:

	_cambiar_volumen_bus("Voces", valor)
	_guardar_volumenes()


func _cambiar_volumen_bus(nombre_bus: String, valor: float) -> void:

	var indice_bus := AudioServer.get_bus_index(nombre_bus)

	if indice_bus == -1:
		push_warning("No se encontró el bus de audio: " + nombre_bus)
		return

	if valor <= 0.0:
		AudioServer.set_bus_volume_db(indice_bus, -80.0)
	else:
		AudioServer.set_bus_volume_db(
			indice_bus,
			linear_to_db(valor / 100.0)
		)


func _guardar_volumenes() -> void:

	var config := ConfigFile.new()
	var vbox_sonido = $Sonido/CenterContainer/VBoxContainer

	config.set_value(
		"sonido",
		"efectos",
		vbox_sonido.get_node("SonidoSlider").value
	)

	config.set_value(
		"sonido",
		"musica",
		vbox_sonido.get_node("MusicaSlider").value
	)

	config.set_value(
		"sonido",
		"voces",
		vbox_sonido.get_node("VocesSlider").value
	)


	var error := config.save(RUTA_OPCIONES_SONIDO)

	if error != OK:

		push_error(
			"No se pudieron guardar las opciones de sonido. Error: "
			+ str(error)
		)

	else:

		print("VOLUMENES GUARDADOS")
		print("Efectos: ", config.get_value("sonido", "efectos"))
		print("Música: ", config.get_value("sonido", "musica"))
		print("Voces: ", config.get_value("sonido", "voces"))
		print("Ruta: ", RUTA_OPCIONES_SONIDO)


func _cargar_volumenes() -> void:

	var config := ConfigFile.new()
	var error := config.load(RUTA_OPCIONES_SONIDO)

	var vbox_sonido = $Sonido/CenterContainer/VBoxContainer

	var sonido_slider: HSlider = vbox_sonido.get_node("SonidoSlider")
	var musica_slider: HSlider = vbox_sonido.get_node("MusicaSlider")
	var voces_slider: HSlider = vbox_sonido.get_node("VocesSlider")


	if error == OK:

		# Recuperar los valores guardados.
		sonido_slider.set_value_no_signal(
			config.get_value("sonido", "efectos", 50.0)
		)

		musica_slider.set_value_no_signal(
			config.get_value("sonido", "musica", 50.0)
		)

		voces_slider.set_value_no_signal(
			config.get_value("sonido", "voces", 50.0)
		)

		print("VOLUMENES CARGADOS")

	else:

		# Si no hay configuración, empezar en 50 %.
		sonido_slider.set_value_no_signal(50.0)
		musica_slider.set_value_no_signal(50.0)
		voces_slider.set_value_no_signal(50.0)

		print("No se pudo cargar opciones.cfg. Error: ", error)
		print("Se usarán los valores predeterminados: 50 %.")


	# Aplicar los valores al mezclador.
	_cambiar_volumen_bus("Sonido", sonido_slider.value)
	_cambiar_volumen_bus("Musica", musica_slider.value)
	_cambiar_volumen_bus("Voces", voces_slider.value)


	# Si no existía la configuración, crear los valores iniciales.
	if error != OK:
		_guardar_volumenes()


	print("Efectos: ", sonido_slider.value)
	print("Música: ", musica_slider.value)
	print("Voces: ", voces_slider.value)
	print("Archivo: ", RUTA_OPCIONES_SONIDO)


# =========================================================
# ESPAÑOL
# =========================================================

func _on_spanish_button_pressed() -> void:

	if confirmando_transferencia_disco:
		_resolver_confirmacion_transferencia(true)
		return

	Settings.language = "es"

	Save.guardar_idioma()

	update_language()

	show_opciones()


# =========================================================
# INGLÉS
# =========================================================

func _on_english_button_pressed() -> void:

	if confirmando_transferencia_disco:
		_resolver_confirmacion_transferencia(false)
		return

	Settings.language = "en"

	Save.guardar_idioma()

	update_language()

	show_opciones()


# =========================================================
# VOLVER DESDE IDIOMA
# =========================================================

func _on_back_button_pressed() -> void:
	if confirmando_transferencia_disco:
		_resolver_confirmacion_transferencia(false)
		return
	show_opciones()


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
