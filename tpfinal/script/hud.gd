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

# Asistente de primera ejecución: idioma -> disco -> controles.
enum PasoConfiguracionInicial {
	NINGUNO,
	IDIOMA,
	DISCO,
	CONTROLES
}

var configuracion_inicial_activa: bool = false
var paso_configuracion_inicial: PasoConfiguracionInicial = PasoConfiguracionInicial.NINGUNO
var panel_explicacion_controles: PanelContainer
var etiqueta_explicacion_modo_a: Label
var etiqueta_explicacion_modo_b: Label


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	# El español es el idioma predeterminado en la primera ejecución.
	# Si ya hay un idioma guardado, se respeta.
	if Settings.language.is_empty():
		Settings.language = "es"

		# Guardar el idioma inicial para que las siguientes ejecuciones
		# no vuelvan a arrancar con el idioma vacío.
		Save.guardar_idioma()

	$Confirmacion.hide()
	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()

	var pantalla_controles_inicial = get_node_or_null("Controles")
	if pantalla_controles_inicial is Control:
		pantalla_controles_inicial.hide()

	_crear_panel_advertencia_disco()
	_configurar_pantalla_sonido()
	_cargar_volumenes()

	# Recuperar la partida antes de actualizar el estado de los botones.
	if FileAccess.file_exists(Save.RUTA_GUARDADO):
		Save.cargar_partida()

	var start_button = $MainMenu/MarginContainer/CenterContainer/VBoxContainer/StartButton
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)

	var continue_button = $MainMenu/MarginContainer/CenterContainer/VBoxContainer/ContinueButton
	if not continue_button.pressed.is_connected(_on_continuar_partida_pressed):
		continue_button.pressed.connect(_on_continuar_partida_pressed)

	var selector_button = $MainMenu/MarginContainer/CenterContainer/VBoxContainer/SelectorNiveles
	if not selector_button.pressed.is_connected(_on_selector_niveles_pressed):
		selector_button.pressed.connect(_on_selector_niveles_pressed)

	# Botón Opciones del menú principal.
	var opciones_button: Button = null
	var vbox_principal = $MainMenu/MarginContainer/CenterContainer/VBoxContainer

	for nombre in ["Opciones", "OpcionesButton", "OptionsButton", "Options"]:
		var nodo = vbox_principal.get_node_or_null(nombre)
		if nodo is Button:
			opciones_button = nodo
			break

	if opciones_button != null:
		if not opciones_button.pressed.is_connected(_on_opciones_button_pressed):
			opciones_button.pressed.connect(_on_opciones_button_pressed)

	var quit_button = $MainMenu/MarginContainer/CenterContainer/VBoxContainer/QuitGameButton
	if not quit_button.pressed.is_connected(_on_quit_game_button_pressed):
		quit_button.pressed.connect(_on_quit_game_button_pressed)

	var retry_button = $GameOver/CenterContainer/VBoxContainer/RetryButton
	if not retry_button.pressed.is_connected(_on_retry_button_pressed):
		retry_button.pressed.connect(_on_retry_button_pressed)

	var game_over_menu_button = $GameOver/CenterContainer/VBoxContainer/MainMenuButton
	if not game_over_menu_button.pressed.is_connected(_on_main_menu_button_pressed):
		game_over_menu_button.pressed.connect(_on_main_menu_button_pressed)

	# Botones del menú de idioma.
	var spanish_button = $LanguageMenu/CenterContainer/VBoxContainer/SpanishButton
	if not spanish_button.pressed.is_connected(_on_spanish_button_pressed):
		spanish_button.pressed.connect(_on_spanish_button_pressed)

	var english_button = $LanguageMenu/CenterContainer/VBoxContainer/EnglishButton
	if not english_button.pressed.is_connected(_on_english_button_pressed):
		english_button.pressed.connect(_on_english_button_pressed)

	var back_button = $LanguageMenu/CenterContainer/VBoxContainer/BackButton
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

	# Botones de Opciones.
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

	var opciones_controles_button = opciones_vbox.get_node_or_null("Controles")
	if opciones_controles_button is Button and not opciones_controles_button.pressed.is_connected(_on_controles_button_pressed):
		opciones_controles_button.pressed.connect(_on_controles_button_pressed)

	# Botones del menú de discos.
	var c_button = $Disco/CenterContainer/VBoxContainer/cButton
	if not c_button.pressed.is_connected(_on_c_button_pressed):
		c_button.pressed.connect(_on_c_button_pressed)

	var d_button = $Disco/CenterContainer/VBoxContainer/dButton
	if not d_button.pressed.is_connected(_on_d_button_pressed):
		d_button.pressed.connect(_on_d_button_pressed)

	var disco_back_button = $Disco/CenterContainer/VBoxContainer/BackButton
	if not disco_back_button.pressed.is_connected(_on_disco_back_button_pressed):
		disco_back_button.pressed.connect(_on_disco_back_button_pressed)

	# Botones de pausa.
	var continuar_button = $Pause/CenterContainer/VBoxContainer/Continuar
	if not continuar_button.pressed.is_connected(_on_continuar_button_pressed):
		continuar_button.pressed.connect(_on_continuar_button_pressed)

	var pause_menu_button = $Pause/CenterContainer/VBoxContainer/MainMenuButton
	if not pause_menu_button.pressed.is_connected(_on_main_menu_button2_pressed):
		pause_menu_button.pressed.connect(_on_main_menu_button2_pressed)

	# Confirmación de nueva partida.
	var yes_button = $Confirmacion/CenterContainer/VBoxContainer/YesButton
	if not yes_button.pressed.is_connected(_on_yes_button_pressed):
		yes_button.pressed.connect(_on_yes_button_pressed)

	var no_button = $Confirmacion/CenterContainer/VBoxContainer/NoButton
	if not no_button.pressed.is_connected(_on_no_button_pressed):
		no_button.pressed.connect(_on_no_button_pressed)

	# Selector de niveles.
	var selector_back_button = $SelectorNiveles/CenterContainer/VBoxContainer/BackButton
	if not selector_back_button.pressed.is_connected(_on_selector_niveles_back_pressed):
		selector_back_button.pressed.connect(_on_selector_niveles_back_pressed)

	# Inicializar controles y sus explicaciones.
	_inicializar_pantalla_controles()
	_configurar_selectores_controles()
	_crear_panel_explicacion_controles()

	# Traducir los textos antes de mostrar cualquier menú.
	update_language()
	actualizar_estado_botones()

	# El asistente inicial sigue solicitando las preferencias que falten.
	if not Save.configuracion_inicial_completa():
		configuracion_inicial_activa = true
		_continuar_asistente_configuracion()
	else:
		show_main_menu()


func actualizar_menu_discos() -> void:
	var titulo: Label = $Disco/CenterContainer/VBoxContainer/Title2
	var c_button: Button = $Disco/CenterContainer/VBoxContainer/cButton
	var d_button: Button = $Disco/CenterContainer/VBoxContainer/dButton

	if Settings.language == "es":
		titulo.text = "Disco actual: " + Save.DISCO_ACTUAL
	else:
		titulo.text = "Current disk: " + Save.DISCO_ACTUAL

	# No ofrecer unidades que no existen. Durante la configuración inicial
	# sí se permite confirmar la unidad activa; en Opciones normal, la actual
	# queda deshabilitada para evitar una transferencia innecesaria.
	var c_disponible: bool = DirAccess.open("C:/") != null
	var d_disponible: bool = DirAccess.open("D:/") != null
	var durante_asistente := configuracion_inicial_activa and paso_configuracion_inicial == PasoConfiguracionInicial.DISCO
	if durante_asistente:
		c_button.disabled = not c_disponible
		d_button.disabled = not d_disponible
	else:
		c_button.disabled = not c_disponible or Save.DISCO_ACTUAL == "C"
		d_button.disabled = not d_disponible or Save.DISCO_ACTUAL == "D"
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
		$Sonido,
		$Controles
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
	$Controles.hide()
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
	Save.disco_configurado = true
	Save.guardar_configuracion_preferencias()
	update_language()
	show_opciones()


# =========================================================
# ASISTENTE DE CONFIGURACIÓN INICIAL
# =========================================================

func _continuar_asistente_configuracion() -> void:
	if not configuracion_inicial_activa:
		return

	if not Save.idioma_configurado:
		paso_configuracion_inicial = PasoConfiguracionInicial.IDIOMA
		show_language_menu()
		var volver_idioma = $LanguageMenu/CenterContainer/VBoxContainer.get_node_or_null("BackButton")
		if volver_idioma is Control:
			volver_idioma.hide()
		return

	if not Save.disco_configurado:
		paso_configuracion_inicial = PasoConfiguracionInicial.DISCO
		show_disco_menu()
		var vbox_disco = $Disco/CenterContainer/VBoxContainer
		var volver_disco = vbox_disco.get_node_or_null("BackButton")
		if volver_disco is Control:
			volver_disco.hide()
			volver_disco.focus_mode = Control.FOCUS_NONE
		actualizar_menu_discos()
		var boton_c = vbox_disco.get_node_or_null("cButton")
		if boton_c is Control:
			boton_c.grab_focus()
		return

	if not Save.controles_configurados:
		paso_configuracion_inicial = PasoConfiguracionInicial.CONTROLES
		show_controles_menu(true)
		return

	# Las tres preferencias ya están configuradas.
	configuracion_inicial_activa = false
	paso_configuracion_inicial = PasoConfiguracionInicial.NINGUNO
	_guardar_visibilidad_botones_asistente(false)
	Save.guardar_configuracion_preferencias()
	show_main_menu()


func _guardar_visibilidad_botones_asistente(es_asistente: bool) -> void:
	var volver_idioma = $LanguageMenu/CenterContainer/VBoxContainer.get_node_or_null("BackButton")
	if volver_idioma is Control:
		volver_idioma.visible = not es_asistente
		volver_idioma.focus_mode = Control.FOCUS_ALL if not es_asistente else Control.FOCUS_NONE

	var volver_disco = $Disco/CenterContainer/VBoxContainer.get_node_or_null("BackButton")
	if volver_disco is Control:
		volver_disco.visible = not es_asistente
		volver_disco.focus_mode = Control.FOCUS_ALL if not es_asistente else Control.FOCUS_NONE

	var raiz_controles = get_node_or_null("Controles")
	if raiz_controles != null:
		var volver_controles = _buscar_nodo_por_nombre(raiz_controles, "BackButton")
		if volver_controles == null:
			volver_controles = _buscar_nodo_por_nombre(raiz_controles, "BotonVolver")
		if volver_controles is Control:
			volver_controles.visible = not es_asistente
			volver_controles.focus_mode = Control.FOCUS_ALL if not es_asistente else Control.FOCUS_NONE

		var continuar_controles = _obtener_boton_continuar_controles()
		if continuar_controles is Control:
			continuar_controles.visible = es_asistente


func _inicializar_pantalla_controles() -> void:
	var raiz = get_node_or_null("Controles")
	if raiz == null:
		push_warning("No existe la pantalla raíz 'Controles' en el HUD.")
		return

	var volver = _buscar_nodo_por_nombre(raiz, "BackButton")
	if volver == null:
		volver = _buscar_nodo_por_nombre(raiz, "BotonVolver")
	if volver is Button and not volver.pressed.is_connected(_on_controles_back_button_pressed):
		volver.pressed.connect(_on_controles_back_button_pressed)

	var continuar = _obtener_boton_continuar_controles()
	if continuar is Button and not continuar.pressed.is_connected(_on_continuar_controles_pressed):
		continuar.pressed.connect(_on_continuar_controles_pressed)


func _obtener_boton_continuar_controles() -> Node:
	var raiz = get_node_or_null("Controles")
	if raiz == null:
		return null
	for nombre in ["Continuar", "ContinueButton", "BotonContinuar", "ContinuarButton"]:
		var nodo = _buscar_nodo_por_nombre(raiz, nombre)
		if nodo is Button:
			return nodo

	# Si la escena todavía no tiene botón Continuar, crearlo como hermano del
	# botón Volver o dentro del VBoxContainer de la pantalla de controles.
	var contenedor: Node = raiz.get_node_or_null("CenterContainer/VBoxContainer")
	if contenedor == null:
		var boton_volver = _buscar_nodo_por_nombre(raiz, "BackButton")
		if boton_volver == null:
			boton_volver = _buscar_nodo_por_nombre(raiz, "BotonVolver")
		if boton_volver != null:
			contenedor = boton_volver.get_parent()
	if contenedor == null:
		var selector = _obtener_selector_control()
		if selector != null:
			contenedor = selector.get_parent()
	if contenedor == null:
		contenedor = raiz

	var boton_nuevo := Button.new()
	boton_nuevo.name = "Continuar"
	boton_nuevo.text = "Continuar" if Settings.language == "es" else "Continue"
	boton_nuevo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton_nuevo.hide()
	contenedor.add_child(boton_nuevo)
	return boton_nuevo


func _obtener_selector_control() -> Node:
	var raiz = get_node_or_null("Controles")
	if raiz == null:
		return null
	for nombre in ["BotonControl", "Boton Control", "Control"]:
		var nodo = _buscar_nodo_por_nombre(raiz, nombre)
		if nodo is OptionButton or nodo is Button:
			return nodo
	return null


func _obtener_selector_interaccion() -> Node:
	var raiz = get_node_or_null("Controles")
	if raiz == null:
		return null
	for nombre in ["BotonDeInteract", "BotonDeInteraccion", "Boton Interact"]:
		var nodo = _buscar_nodo_por_nombre(raiz, nombre)
		if nodo is OptionButton or nodo is Button:
			return nodo
	return null


func _buscar_nodo_por_nombre(raiz: Node, nombre_buscado: String) -> Node:
	if raiz.name == nombre_buscado:
		return raiz
	for hijo in raiz.get_children():
		var encontrado = _buscar_nodo_por_nombre(hijo, nombre_buscado)
		if encontrado != null:
			return encontrado
	return null


func _configurar_selectores_controles() -> void:
	var selector_control = _obtener_selector_control()
	if selector_control == null:
		push_warning("No se encontró BotonControl en la pantalla Controles.")
	elif selector_control is OptionButton:
		selector_control.clear()
		selector_control.add_item("Modo A")
		selector_control.add_item("Modo B")
		if not selector_control.item_selected.is_connected(_on_selector_modo_controles_elegido):
			selector_control.item_selected.connect(_on_selector_modo_controles_elegido)
	elif selector_control is Button:
		if not selector_control.pressed.is_connected(_on_boton_control_pressed):
			selector_control.pressed.connect(_on_boton_control_pressed)

	var selector_interaccion = _obtener_selector_interaccion()
	if selector_interaccion == null:
		push_warning("No se encontró BotonDeInteract en la pantalla Controles.")
	elif selector_interaccion is OptionButton:
		if not selector_interaccion.item_selected.is_connected(_on_selector_interaccion_elegido):
			selector_interaccion.item_selected.connect(_on_selector_interaccion_elegido)
	elif selector_interaccion is Button:
		if not selector_interaccion.pressed.is_connected(_on_boton_interaccion_pressed):
			selector_interaccion.pressed.connect(_on_boton_interaccion_pressed)

	_actualizar_selectores_controles()

	_crear_flechas_selector(
		_obtener_selector_control() as Control,
		"control"
	)

	_crear_flechas_selector(
		_obtener_selector_interaccion() as Control,
		"interaccion"
	)

	_actualizar_selectores_controles()


func _actualizar_selectores_controles() -> void:
	var selector_control = _obtener_selector_control()
	var modo: int = int(Settings.modo_controles)
	var texto_modo: String = "Modo A" if modo == int(Settings.ModoControles.MODO_A) else "Modo B"

	if selector_control is OptionButton:
		if selector_control.item_count < 2:
			selector_control.clear()
			selector_control.add_item("Modo A")
			selector_control.add_item("Modo B")
		selector_control.select(modo)
	elif selector_control is Button:
		selector_control.text = ("Control: " if Settings.language == "es" else "Controls: ") + texto_modo

	var selector_interaccion = _obtener_selector_interaccion()
	var opciones_interaccion: Array = []

	if Settings.modo_controles == Settings.ModoControles.MODO_A:
		if Settings.language == "es":
			opciones_interaccion = ["Arriba", "E"]
		else:
			opciones_interaccion = ["Up", "E"]
	else:
		opciones_interaccion = ["W", "E"]
	if selector_interaccion is OptionButton:
		selector_interaccion.clear()
		for opcion in opciones_interaccion:
			selector_interaccion.add_item(opcion)
		selector_interaccion.select(clampi(Settings.opcion_interaccion, 0, 1))
	elif selector_interaccion is Button:
		var nombre_interaccion := "Interacción: " if Settings.language == "es" else "Interact: "
		selector_interaccion.text = nombre_interaccion + opciones_interaccion[clampi(Settings.opcion_interaccion, 0, 1)]

	_actualizar_textos_controles()
	_actualizar_estado_flechas("control")
	_actualizar_estado_flechas("interaccion")

func _actualizar_textos_controles() -> void:
	var raiz = get_node_or_null("Controles")
	if raiz == null:
		return

	var boton_control = _obtener_selector_control()
	var boton_interaccion = _obtener_selector_interaccion()

	# Actualizar el botón del modo de controles.
	if boton_control is Button and not (boton_control is OptionButton):
		var texto_modo: String = (
			"Modo A"
			if Settings.modo_controles == Settings.ModoControles.MODO_A
			else "Modo B"
		)

		boton_control.text = (
			"Control: " if Settings.language == "es"
			else "Controls: "
		) + texto_modo

	# Actualizar el botón de interacción.
	if boton_interaccion is Button and not (boton_interaccion is OptionButton):
		var opciones_interaccion: Array = []

		if Settings.modo_controles == Settings.ModoControles.MODO_A:
			if Settings.language == "es":
				opciones_interaccion = ["Arriba", "E"]
			else:
				opciones_interaccion = ["Up", "E"]
		else:
			opciones_interaccion = ["W", "E"]

		var indice_opcion: int = clampi(
			Settings.opcion_interaccion,
			0,
			opciones_interaccion.size() - 1
		)

		var nombre_interaccion: String = (
			"Interacción: "
			if Settings.language == "es"
			else "Interact: "
		)

		boton_interaccion.text = (
			nombre_interaccion
			+ str(opciones_interaccion[indice_opcion])
		)

	# Actualizar los textos generales de la pantalla.
	var titulo = _buscar_nodo_por_nombre(raiz, "Title")

	if titulo is Label:
		titulo.text = (
			"Controles"
			if Settings.language == "es"
			else "Controls"
		)

	var volver = _buscar_nodo_por_nombre(raiz, "BackButton")

	if volver is Button:
		volver.text = (
			"Volver"
			if Settings.language == "es"
			else "Back"
		)

	var continuar = _obtener_boton_continuar_controles()

	if continuar is Button:
		continuar.text = (
			"Continuar"
			if Settings.language == "es"
			else "Continue"
		)

	# Explicación lateral de ambos modos.
	if (
		is_instance_valid(etiqueta_explicacion_modo_a)
		and is_instance_valid(etiqueta_explicacion_modo_b)
	):
		if Settings.language == "es":
			etiqueta_explicacion_modo_a.text = (
				"MODO A · FLECHAS\n"
				+ "Mover: ← / →\n"
				+ "Saltar: Espacio\n"
				+ "Salto fuego: Z\n"
				+ "Diálogo: Z o Espacio\n"
				+ "Interacción: ↑ o E\n"
				+ "Madriguera: ↓\n"
				+ "Tornado: X\n"
				+ "TurboFuego: C"
			)

			etiqueta_explicacion_modo_b.text = (
				"MODO B · WASD\n"
				+ "Mover: A / D\n"
				+ "Saltar: N\n"
				+ "Salto fuego: J\n"
				+ "Diálogo: J o N\n"
				+ "Interacción: W o E\n"
				+ "Madriguera: S\n"
				+ "Tornado: K\n"
				+ "TurboFuego: L"
			)
		else:
			etiqueta_explicacion_modo_a.text = (
				"MODE A · ARROW KEYS\n"
				+ "Move: ← / →\n"
				+ "Jump: Space\n"
				+ "Fire jump: Z\n"
				+ "Dialogue: Z or Space\n"
				+ "Interact: ↑ or E\n"
				+ "Burrow: ↓\n"
				+ "Tornado: X\n"
				+ "TurboFire: C"
			)

			etiqueta_explicacion_modo_b.text = (
				"MODE B · WASD\n"
				+ "Move: A / D\n"
				+ "Jump: N\n"
				+ "Fire jump: Y\n"
				+ "Dialogue: J or N\n"
				+ "Interact: W or E\n"
				+ "Burrow: S\n"
				+ "Tornado: K\n"
				+ "TurboFire: L"
			)
func _crear_panel_explicacion_controles() -> void:
	var raiz = get_node_or_null("Controles")
	if not raiz is Control:
		return
	var existente = raiz.get_node_or_null("ExplicacionModosPanel")
	if existente is PanelContainer:
		panel_explicacion_controles = existente
		etiqueta_explicacion_modo_a = existente.get_node_or_null("VBox/ModoA") as Label
		etiqueta_explicacion_modo_b = existente.get_node_or_null("VBox/ModoB") as Label
		_actualizar_textos_controles()
		return

	panel_explicacion_controles = PanelContainer.new()
	panel_explicacion_controles.name = "ExplicacionModosPanel"
	panel_explicacion_controles.anchor_left = 0.63
	panel_explicacion_controles.anchor_top = 0.20
	panel_explicacion_controles.anchor_right = 0.98
	panel_explicacion_controles.anchor_bottom = 0.82
	panel_explicacion_controles.offset_left = 0
	panel_explicacion_controles.offset_top = 0
	panel_explicacion_controles.offset_right = 0
	panel_explicacion_controles.offset_bottom = 0
	panel_explicacion_controles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(panel_explicacion_controles)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_explicacion_controles.add_child(vbox)

	etiqueta_explicacion_modo_a = Label.new()
	etiqueta_explicacion_modo_a.name = "ModoA"
	etiqueta_explicacion_modo_a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_explicacion_modo_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(etiqueta_explicacion_modo_a)

	var separador := HSeparator.new()
	vbox.add_child(separador)

	etiqueta_explicacion_modo_b = Label.new()
	etiqueta_explicacion_modo_b.name = "ModoB"
	etiqueta_explicacion_modo_b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_explicacion_modo_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(etiqueta_explicacion_modo_b)

	_actualizar_textos_controles()


func show_controles_menu(es_asistente: bool = false) -> void:
	$MainMenu.hide()
	$GameOver.hide()
	$LanguageMenu.hide()
	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()
	$Pause.hide()
	$SelectorNiveles.hide()
	$Confirmacion.hide()

	var raiz = get_node_or_null("Controles")
	if raiz == null:
		push_error("No existe la pantalla Controles.")
		return

	_actualizar_selectores_controles()
	_guardar_visibilidad_botones_asistente(es_asistente)
	raiz.show()

	var selector = _obtener_selector_control()
	if selector is Control:
		selector.grab_focus()


func _on_controles_button_pressed() -> void:
	configuracion_inicial_activa = false
	paso_configuracion_inicial = PasoConfiguracionInicial.NINGUNO
	show_controles_menu(false)


func _on_controles_back_button_pressed() -> void:
	if configuracion_inicial_activa:
		return
	show_opciones()


func _on_continuar_controles_pressed() -> void:
	if configuracion_inicial_activa and paso_configuracion_inicial == PasoConfiguracionInicial.CONTROLES:
		Save.confirmar_controles_configurados()
		_continuar_asistente_configuracion()
	else:
		Save.controles_configurados = true
		Save.guardar_configuracion_preferencias()
		show_opciones()


func _on_boton_control_pressed() -> void:
	# Se declara el tipo explícitamente y se asigna el siguiente perfil.
	var nuevo_modo: int = int(Settings.ModoControles.MODO_A)
	if int(Settings.modo_controles) == int(Settings.ModoControles.MODO_A):
		nuevo_modo = int(Settings.ModoControles.MODO_B)
	_aplicar_modo_controles_elegido(nuevo_modo)


func _on_selector_modo_controles_elegido(indice: int) -> void:
	var nuevo_modo: int = int(Settings.ModoControles.MODO_A)
	if indice == 1:
		nuevo_modo = int(Settings.ModoControles.MODO_B)
	_aplicar_modo_controles_elegido(nuevo_modo)


func _aplicar_modo_controles_elegido(nuevo_modo: int) -> void:
	Settings.cambiar_modo_controles(nuevo_modo)
	_actualizar_selectores_controles()
	_guardar_cambio_controles_si_corresponde()


func _on_boton_interaccion_pressed() -> void:
	var nueva_opcion: int = 0 if int(Settings.opcion_interaccion) == 1 else 1
	_aplicar_opcion_interaccion_elegida(nueva_opcion)


func _on_selector_interaccion_elegido(indice: int) -> void:
	_aplicar_opcion_interaccion_elegida(indice)


func _aplicar_opcion_interaccion_elegida(nueva_opcion: int) -> void:
	Settings.cambiar_opcion_interaccion(nueva_opcion)
	_actualizar_selectores_controles()
	_guardar_cambio_controles_si_corresponde()


func _guardar_cambio_controles_si_corresponde() -> void:
	if configuracion_inicial_activa:
		# Se guardan los valores provisionales, pero el indicador de controles
		# solo pasa a true al pulsar Continuar.
		Save.guardar_configuracion_preferencias()
	else:
		Save.controles_configurados = true
		Save.guardar_configuracion_preferencias()


func _cambiar_selector_con_flechas(nodo: Node, direccion: int) -> void:
	if nodo == _obtener_selector_control():
		var nuevo_modo: int = int(Settings.ModoControles.MODO_A)
		if direccion > 0:
			nuevo_modo = int(Settings.ModoControles.MODO_B)
		_aplicar_modo_controles_elegido(nuevo_modo)
	elif nodo == _obtener_selector_interaccion():
		var nueva_opcion: int = 0
		if direccion > 0:
			nueva_opcion = 1
		_aplicar_opcion_interaccion_elegida(nueva_opcion)


func _input(event: InputEvent) -> void:
	var raiz = get_node_or_null("Controles")
	if raiz == null or not raiz.visible:
		return
	if not event is InputEventKey:
		return

	var tecla := event as InputEventKey
	if not tecla.pressed or tecla.echo:
		return

	var enfocado := get_viewport().gui_get_focus_owner()
	if enfocado != _obtener_selector_control() and enfocado != _obtener_selector_interaccion():
		return

	var codigo_fisico := tecla.physical_keycode
	var codigo_logico := tecla.keycode
	if codigo_fisico in [KEY_LEFT, KEY_A] or codigo_logico in [KEY_LEFT, KEY_A]:
		_cambiar_selector_con_flechas(enfocado, -1)
		get_viewport().set_input_as_handled()
	elif codigo_fisico in [KEY_RIGHT, KEY_D] or codigo_logico in [KEY_RIGHT, KEY_D]:
		_cambiar_selector_con_flechas(enfocado, 1)
		get_viewport().set_input_as_handled()


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
		$SelectorNiveles,
		$Controles
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
	var boton_actual = get_viewport().gui_get_focus_owner()

	# Los selectores centrales no ejecutan acciones.
	if boton_actual == _obtener_selector_control():
		return

	if boton_actual == _obtener_selector_interaccion():
		return

	if boton_actual is Button and not boton_actual.disabled:
		boton_actual.pressed.emit()
# =========================================================
# MENÚ PRINCIPAL
# =========================================================

func show_main_menu() -> void:

	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()
	$Controles.hide()
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
	$Controles.hide()
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
	$Controles.hide()
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
	if primer_boton == null:
		primer_boton = vbox.get_node_or_null("Controles")
	if primer_boton is Control:
		primer_boton.grab_focus()

func show_disco_menu() -> void:
	$MainMenu.hide()
	$GameOver.hide()
	$LanguageMenu.hide()
	$Sonido.hide()
	$Opciones.hide()
	$Controles.hide()
	$Pause.hide()
	$SelectorNiveles.hide()
	$Confirmacion.hide()

	actualizar_menu_discos()
	$Disco.show()
	var boton_volver_disco = $Disco/CenterContainer/VBoxContainer.get_node_or_null("BackButton")
	var durante_asistente := configuracion_inicial_activa and paso_configuracion_inicial == PasoConfiguracionInicial.DISCO
	if boton_volver_disco is Control:
		boton_volver_disco.visible = not durante_asistente
		boton_volver_disco.focus_mode = Control.FOCUS_NONE if durante_asistente else Control.FOCUS_ALL

	var c_button: Button = $Disco/CenterContainer/VBoxContainer/cButton
	var d_button: Button = $Disco/CenterContainer/VBoxContainer/dButton

	if not c_button.disabled:
		c_button.grab_focus()
	elif not d_button.disabled:
		d_button.grab_focus()
	elif not durante_asistente:
		$Disco/CenterContainer/VBoxContainer/BackButton.grab_focus()
# =========================================================
# MENÚ IDIOMA
# =========================================================

func show_language_menu() -> void:

	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()
	$Controles.hide()
	$MainMenu.hide()

	$GameOver.hide()

	$LanguageMenu.show()

	$Pause.hide()

	$SelectorNiveles.hide()

	$Confirmacion.hide()


	var boton_volver_idioma = $LanguageMenu/CenterContainer/VBoxContainer.get_node_or_null("BackButton")
	if boton_volver_idioma is Control:
		var durante_asistente := configuracion_inicial_activa and paso_configuracion_inicial == PasoConfiguracionInicial.IDIOMA
		boton_volver_idioma.visible = not durante_asistente
		boton_volver_idioma.focus_mode = Control.FOCUS_NONE if durante_asistente else Control.FOCUS_ALL

	$LanguageMenu/CenterContainer/VBoxContainer/SpanishButton.grab_focus()


# =========================================================
# MENÚ PAUSA
# =========================================================

func show_pause_menu() -> void:

	$Sonido.hide()
	$Opciones.hide()
	$Disco.hide()
	$Controles.hide()
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
	$Controles.hide()
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
	# Evitar que un idioma vacío o inválido deje los textos originales
	# de la escena, como "Start".
	if Settings.language != "es" and Settings.language != "en":
		Settings.language = "es"

	var es: bool = Settings.language == "es"

	# Menú principal.
	$MainMenu/MarginContainer/CenterContainer/VBoxContainer/Title.text = "Eva Two Tales Kitsune"
	$MainMenu/MarginContainer/CenterContainer/VBoxContainer/StartButton.text = "Nueva partida" if es else "New Game"
	$MainMenu/MarginContainer/CenterContainer/VBoxContainer/ContinueButton.text = "Continuar" if es else "Continue"
	$MainMenu/MarginContainer/CenterContainer/VBoxContainer/SelectorNiveles.text = "Selector de niveles" if es else "Level Select"
	$MainMenu/MarginContainer/CenterContainer/VBoxContainer/QuitGameButton.text = "Cerrar juego" if es else "Quit Game"
	_actualizar_texto_boton_opciones_menu("Opciones" if es else "Options")

	# Menú de opciones.
	var opciones = $Opciones/MarginContainer/CenterContainer/VBoxContainer
	opciones.get_node("LanguageButton").text = "Idioma" if es else "Language"
	opciones.get_node("Sonido").text = "Sonido" if es else "Sound"
	opciones.get_node("Disco").text = "Disco" if es else "Disk"

	var controles_opciones = opciones.get_node_or_null("Controles")
	if controles_opciones is Button:
		controles_opciones.text = "Controles" if es else "Controls"

	var volver_opciones = opciones.get_node_or_null("BackButton")
	if volver_opciones is Button:
		volver_opciones.text = "Volver" if es else "Back"

	# Menú de sonido.
	var sonido = $Sonido/CenterContainer/VBoxContainer
	sonido.get_node("LabelSonido").text = "Efectos de sonido" if es else "Sound Effects"
	sonido.get_node("LabelMusica").text = "Música" if es else "Music"
	sonido.get_node("LabelVoces").text = "Voces" if es else "Voices"
	sonido.get_node("BackButton").text = "Volver" if es else "Back"

	# Menú de discos.
	var disco = $Disco/CenterContainer/VBoxContainer
	disco.get_node("Title").text = "Disco" if es else "Disk"
	disco.get_node("cButton").text = "Disco C" if es else "Disk C"
	disco.get_node("dButton").text = "Disco D" if es else "Disk D"
	disco.get_node("BackButton").text = "Volver" if es else "Back"

	# Menú de idioma.
	var idioma = $LanguageMenu/CenterContainer/VBoxContainer
	idioma.get_node("Title").text = "Idioma" if es else "Language"
	idioma.get_node("SpanishButton").text = "Español"
	idioma.get_node("EnglishButton").text = "English"
	idioma.get_node("BackButton").text = "Volver" if es else "Back"

	# Pantalla de Game Over.
	var game_over = $GameOver/CenterContainer/VBoxContainer
	game_over.get_node("Message").text = "Fin de la partida" if es else "Game Over"
	game_over.get_node("RetryButton").text = "Reintentar" if es else "Retry"
	game_over.get_node("MainMenuButton").text = "Menú principal" if es else "Main Menu"

	# Menú de pausa.
	var pausa = $Pause/CenterContainer/VBoxContainer
	pausa.get_node("Message").text = "Pausa" if es else "Pause"
	pausa.get_node("Continuar").text = "Continuar" if es else "Resume"
	pausa.get_node("MainMenuButton").text = "Volver al menú principal" if es else "Back to Main Menu"

	# Selector de niveles.
	var selector = $SelectorNiveles/CenterContainer/VBoxContainer
	selector.get_node("Title").text = "Selector de niveles" if es else "Level Select"
	selector.get_node("BackButton").text = "Volver" if es else "Back"

	# Confirmación de nueva partida.
	var confirmacion = $Confirmacion/CenterContainer/VBoxContainer
	confirmacion.get_node("Message").text = (
		"¿Está seguro de que desea iniciar una nueva partida? Los datos actuales se borrarán."
		if es
		else
		"Are you sure you want to start a new game? Current data will be deleted."
	)
	confirmacion.get_node("YesButton").text = "Sí" if es else "Yes"
	confirmacion.get_node("NoButton").text = "No"

	# Actualizar también los controles y el menú de discos.
	_actualizar_textos_controles()

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
	_manejar_seleccion_disco("C")


func _on_d_button_pressed() -> void:
	_manejar_seleccion_disco("D")


func _manejar_seleccion_disco(disco: String) -> void:
	if configuracion_inicial_activa and paso_configuracion_inicial == PasoConfiguracionInicial.DISCO:
		if not Save.seleccionar_disco_inicial(disco):
			var mensaje := Save.advertencia_disco
			Save.advertencia_disco = ""
			_mostrar_advertencia_disco(mensaje if not mensaje.is_empty() else "No se pudo seleccionar el disco " + disco + ".")
			return
		_continuar_asistente_configuracion()
		return
	_intentar_cambiar_disco(disco)


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
	$Controles.hide()

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


func _on_spanish_button_pressed() -> void:
	if confirmando_transferencia_disco:
		_resolver_confirmacion_transferencia(true)
		return

	Settings.language = "es"
	Save.guardar_idioma()
	update_language()

	if configuracion_inicial_activa and paso_configuracion_inicial == PasoConfiguracionInicial.IDIOMA:
		_continuar_asistente_configuracion()
	else:
		show_opciones()


func _on_english_button_pressed() -> void:
	if confirmando_transferencia_disco:
		_resolver_confirmacion_transferencia(false)
		return

	Settings.language = "en"
	Save.guardar_idioma()
	update_language()

	if configuracion_inicial_activa and paso_configuracion_inicial == PasoConfiguracionInicial.IDIOMA:
		_continuar_asistente_configuracion()
	else:
		show_opciones()


# =========================================================
# VOLVER DESDE IDIOMA
# =========================================================

func _on_back_button_pressed() -> void:
	if confirmando_transferencia_disco:
		_resolver_confirmacion_transferencia(false)
		return
	if configuracion_inicial_activa:
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


func _crear_flechas_selector(selector: Control, tipo: String) -> void:
	if selector == null:
		return

	# Evitar crear las flechas dos veces.
	if selector.get_parent().name == "ContenedorFlechas_" + tipo:
		return

	var padre := selector.get_parent()
	var indice := selector.get_index()

	# El selector central deja de ejecutar acciones.
	if selector is Button:
		if selector.pressed.is_connected(_on_boton_control_pressed):
			selector.pressed.disconnect(_on_boton_control_pressed)

		if selector.pressed.is_connected(_on_boton_interaccion_pressed):
			selector.pressed.disconnect(_on_boton_interaccion_pressed)

	if selector is OptionButton:
		if selector.item_selected.is_connected(_on_selector_modo_controles_elegido):
			selector.item_selected.disconnect(_on_selector_modo_controles_elegido)

		if selector.item_selected.is_connected(_on_selector_interaccion_elegido):
			selector.item_selected.disconnect(_on_selector_interaccion_elegido)

		# No permitir que el selector abra su lista al pulsarlo.
		selector.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var contenedor := HBoxContainer.new()
	contenedor.name = "ContenedorFlechas_" + tipo
	contenedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenedor.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor.add_theme_constant_override("separation", 8)

	# Conservar la posición del selector dentro del contenedor original.
	padre.add_child(contenedor)
	padre.move_child(contenedor, indice)

	padre.remove_child(selector)
	contenedor.add_child(selector)

	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Flecha izquierda.
	var izquierda := Button.new()
	izquierda.name = "FlechaIzquierda"
	izquierda.text = "◀"
	izquierda.custom_minimum_size = Vector2(40, 0)
	izquierda.focus_mode = Control.FOCUS_NONE
	izquierda.pressed.connect(_on_flecha_selector_pressed.bind(tipo, -1))
	contenedor.add_child(izquierda)

	# La flecha izquierda debe aparecer antes del selector.
	contenedor.move_child(izquierda, 0)

	# Flecha derecha.
	var derecha := Button.new()
	derecha.name = "FlechaDerecha"
	derecha.text = "▶"
	derecha.custom_minimum_size = Vector2(40, 0)
	derecha.focus_mode = Control.FOCUS_NONE
	derecha.pressed.connect(_on_flecha_selector_pressed.bind(tipo, 1))
	contenedor.add_child(derecha)

	_actualizar_estado_flechas(tipo)


func _on_flecha_selector_pressed(tipo: String, direccion: int) -> void:
	if tipo == "control":
		var modo_actual := int(Settings.modo_controles)

		if direccion < 0 and modo_actual == int(Settings.ModoControles.MODO_A):
			return

		if direccion > 0 and modo_actual == int(Settings.ModoControles.MODO_B):
			return

		var nuevo_modo := (
			int(Settings.ModoControles.MODO_A)
			if direccion < 0
			else int(Settings.ModoControles.MODO_B)
		)

		_aplicar_modo_controles_elegido(nuevo_modo)

	elif tipo == "interaccion":
		var opcion_actual := int(Settings.opcion_interaccion)

		if direccion < 0 and opcion_actual <= 0:
			return

		if direccion > 0 and opcion_actual >= 1:
			return

		_aplicar_opcion_interaccion_elegida(
			clampi(opcion_actual + direccion, 0, 1)
		)


func _actualizar_estado_flechas(tipo: String) -> void:
	var raiz = get_node_or_null("Controles")
	if raiz == null:
		return

	var selector: Control
	var posicion: int

	if tipo == "control":
		selector = _obtener_selector_control()
		posicion = int(Settings.modo_controles)
	else:
		selector = _obtener_selector_interaccion()
		posicion = int(Settings.opcion_interaccion)

	if selector == null:
		return

	var contenedor := selector.get_parent()
	if contenedor == null:
		return

	var izquierda := contenedor.get_node_or_null("FlechaIzquierda")
	var derecha := contenedor.get_node_or_null("FlechaDerecha")

	if izquierda is Button:
		izquierda.disabled = posicion <= 0
		izquierda.modulate = (
			Color(0.4, 0.4, 0.4, 1.0)
			if izquierda.disabled
			else Color.WHITE
		)

	if derecha is Button:
		derecha.disabled = posicion >= 1
		derecha.modulate = (
			Color(0.4, 0.4, 0.4, 1.0)
			if derecha.disabled
			else Color.WHITE
		)
