extends Node

# =========================================================
# CONFIGURACIÓN DE GUARDADO
# =========================================================

const NOMBRE_CARPETA_GUARDADO := "evaTwoTalesSave"
const DISCO_POR_DEFECTO := "C"
const RUTA_CONFIGURACION_PREFERENCIAS := "user://preferencias_eva.cfg"

# Estas variables solo existen mientras el juego está abierto.
# La preferencia elegida se guarda además en preferencias_eva.cfg.
var DISCO_ACTUAL: String = ""
var CARPETA_GUARDADO: String = ""
var RUTA_GUARDADO: String = ""

var advertencia_disco: String = ""
var partidaFinalizada: bool = false

# Indicadores persistentes de configuración inicial.
# Si alguno es false, HUD muestra el paso correspondiente.
var idioma_configurado: bool = false
var disco_configurado: bool = false
var controles_configurados: bool = false


func _ready() -> void:
	_cargar_configuracion_preferencias()

	if (
		disco_configurado
		and _es_disco_valido(str(DISCO_ACTUAL))
		and DirAccess.open(str(DISCO_ACTUAL) + ":/") != null
	):
		_configurar_disco(DISCO_ACTUAL)
	else:
		if disco_configurado:
			disco_configurado = false
		detectar_disco_actual()

	# Restaurar controles guardados si se completó su configuración.
	# El tipo int está declarado explícitamente para evitar el error de inferencia
	# que GDScript puede dar con expresiones que combinan valores de enum.
	if controles_configurados:
		var modo_restaurado: int = int(Settings.modo_controles)
		Settings.cambiar_modo_controles(modo_restaurado)
		Settings.cambiar_opcion_interaccion(int(Settings.opcion_interaccion))


# =========================================================
# PREFERENCIAS INDEPENDIENTES DE LA PARTIDA
# =========================================================

func _cargar_configuracion_preferencias() -> void:
	var config := ConfigFile.new()
	var error_carga := config.load(RUTA_CONFIGURACION_PREFERENCIAS)

	if error_carga != OK:
		idioma_configurado = false
		disco_configurado = false
		controles_configurados = false
		return

	idioma_configurado = bool(
		config.get_value("estado", "idioma_configurado", false)
	)
	disco_configurado = bool(
		config.get_value("estado", "disco_configurado", false)
	)
	controles_configurados = bool(
		config.get_value("estado", "controles_configurados", false)
	)

	if idioma_configurado:
		Settings.language = str(
			config.get_value("preferencias", "language", "es")
		)
		if Settings.language not in ["es", "en"]:
			Settings.language = "es"
			idioma_configurado = false

	if disco_configurado:
		var disco_guardado := str(
			config.get_value("preferencias", "disco", DISCO_POR_DEFECTO)
		).to_upper()
		if _es_disco_valido(disco_guardado):
			DISCO_ACTUAL = disco_guardado
		else:
			disco_configurado = false

	if controles_configurados:
		var modo_guardado := int(
			config.get_value(
				"preferencias",
				"modo_controles",
				Settings.ModoControles.MODO_A
			)
		)
		Settings.modo_controles = (
			Settings.ModoControles.MODO_B
			if modo_guardado == Settings.ModoControles.MODO_B
			else Settings.ModoControles.MODO_A
		)
		Settings.opcion_interaccion = clampi(
			int(config.get_value("preferencias", "opcion_interaccion", 0)),
			0,
			1
		)


func guardar_configuracion_preferencias() -> bool:
	var config := ConfigFile.new()
	# Cargar primero para no perder futuras preferencias agregadas a este archivo.
	config.load(RUTA_CONFIGURACION_PREFERENCIAS)

	config.set_value("estado", "idioma_configurado", idioma_configurado)
	config.set_value("estado", "disco_configurado", disco_configurado)
	config.set_value("estado", "controles_configurados", controles_configurados)

	config.set_value("preferencias", "language", Settings.language)
	config.set_value("preferencias", "disco", DISCO_ACTUAL)
	config.set_value("preferencias", "modo_controles", int(Settings.modo_controles))
	config.set_value("preferencias", "opcion_interaccion", Settings.opcion_interaccion)

	var error_guardado := config.save(RUTA_CONFIGURACION_PREFERENCIAS)
	if error_guardado != OK:
		push_warning(
			"No se pudo guardar la configuración general. Error: "
			+ str(error_guardado)
		)
		return false

	_actualizar_preferencias_guardado_existente()
	return true


func configuracion_inicial_completa() -> bool:
	return idioma_configurado and disco_configurado and controles_configurados


func confirmar_controles_configurados() -> void:
	controles_configurados = true
	guardar_configuracion_preferencias()


func _actualizar_preferencias_guardado_existente() -> void:
	# No crear una falsa partida solo por elegir opciones.
	# Si ya existe un archivo de partida, actualizar sus preferencias sin
	# borrar el progreso ni otros campos almacenados.
	if RUTA_GUARDADO.is_empty() or not FileAccess.file_exists(RUTA_GUARDADO):
		return

	var lectura := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if lectura == null:
		push_warning("No se pudieron leer las preferencias de la partida guardada.")
		return
	var existentes = lectura.get_var()
	lectura.close()
	if not existentes is Dictionary:
		# No sobrescribir un archivo de partida que no se pudo interpretar.
		push_warning("El archivo de partida no contiene un diccionario válido; no se actualizaron sus preferencias.")
		return
	var datos: Dictionary = existentes

	datos["language"] = Settings.language
	datos["idiomaConfigurado"] = idioma_configurado
	datos["disco"] = DISCO_ACTUAL
	datos["discoConfigurado"] = disco_configurado
	datos["modoControles"] = int(Settings.modo_controles)
	datos["opcionInteraccion"] = Settings.opcion_interaccion
	datos["controlesConfigurados"] = controles_configurados

	var escritura := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if escritura == null:
		push_warning("No se pudieron actualizar las preferencias dentro de la partida guardada.")
		return
	escritura.store_var(datos)
	escritura.close()


func seleccionar_disco_inicial(disco: String) -> bool:
	disco = disco.to_upper()
	if not _es_disco_valido(disco):
		advertencia_disco = "El disco seleccionado no es válido."
		return false
	if DirAccess.open(disco + ":/") == null:
		advertencia_disco = "El disco " + disco + " no está disponible. Selecciona una unidad existente."
		return false

	_configurar_disco(disco)
	disco_configurado = true

	if not guardar_configuracion_preferencias():
		advertencia_disco = "No se pudo guardar la selección del disco."
		return false

	advertencia_disco = ""
	print("DISCO CONFIGURADO: ", DISCO_ACTUAL)
	print("Carpeta de guardado: ", CARPETA_GUARDADO)
	return true


func _es_disco_valido(disco: String) -> bool:
	return disco.to_upper() in ["C", "D"]


# =========================================================
# SELECCIONAR EL DISCO AL INICIAR
# =========================================================

func detectar_disco_actual() -> String:
	# Primero priorizar un archivo de partida real. Después, carpetas existentes.
	# Esto evita elegir C solo porque quedó una carpeta vacía allí cuando la
	# partida real está guardada en D.
	var ruta_c := _ruta_carpeta_para_disco("C")
	var ruta_d := _ruta_carpeta_para_disco("D")
	var save_c := ruta_c.path_join("partida.save")
	var save_d := ruta_d.path_join("partida.save")

	if FileAccess.file_exists(save_c):
		_configurar_disco("C")
		disco_configurado = true
	elif FileAccess.file_exists(save_d):
		_configurar_disco("D")
		disco_configurado = true
	elif DirAccess.dir_exists_absolute(ruta_c):
		_configurar_disco("C")
	elif DirAccess.dir_exists_absolute(ruta_d):
		_configurar_disco("D")
	else:
		_configurar_disco(DISCO_POR_DEFECTO)

	print("DISCO DE GUARDADO DETECTADO: ", DISCO_ACTUAL)
	print("Carpeta de guardado: ", CARPETA_GUARDADO)
	return DISCO_ACTUAL


func _ruta_carpeta_para_disco(disco: String) -> String:
	return disco + ":/" + NOMBRE_CARPETA_GUARDADO


func _configurar_disco(disco: String) -> void:
	DISCO_ACTUAL = disco.to_upper()
	CARPETA_GUARDADO = _ruta_carpeta_para_disco(DISCO_ACTUAL)
	RUTA_GUARDADO = CARPETA_GUARDADO + "/partida.save"


func _asegurar_disco_inicializado() -> void:
	if DISCO_ACTUAL == "" or CARPETA_GUARDADO == "" or RUTA_GUARDADO == "":
		detectar_disco_actual()


# =========================================================
# ASEGURAR CARPETA
# =========================================================

func asegurar_carpeta() -> bool:
	_asegurar_disco_inicializado()
	if DirAccess.dir_exists_absolute(CARPETA_GUARDADO):
		return true

	var resultado := DirAccess.make_dir_recursive_absolute(CARPETA_GUARDADO)
	if resultado != OK:
		advertencia_disco = "No se pudo crear la carpeta de guardado en el disco " + DISCO_ACTUAL + ". Puede que el disco no esté disponible o que no haya permisos/espacio."
		push_warning(advertencia_disco)
		return false

	print("CARPETA DE GUARDADO CREADA: ", CARPETA_GUARDADO)
	return true


# =========================================================
# GUARDAR SOLAMENTE EL IDIOMA
# =========================================================

func guardar_idioma() -> void:
	idioma_configurado = true
	guardar_configuracion_preferencias()
	print("IDIOMA CONFIGURADO: ", Settings.language)


# =========================================================
# PREPARAR DATOS DE PARTIDA
# =========================================================

func _obtener_datos_partida() -> Dictionary:
	# No recuperar automáticamente un nivel actual cuando la partida terminó.
	if Settings.nivelActual == "" and not partidaFinalizada:
		var main = Settings.getMain()
		if main != null:
			var ruta_nivel = main.obtener_ruta_nivel_actual()
			if ruta_nivel != "":
				Settings.nivelActual = ruta_nivel
				print("NIVEL ACTUAL GUARDADO AUTOMÁTICAMENTE: ", Settings.nivelActual)
			else:
				print("ADVERTENCIA: no se pudo obtener el nivel actual")
		else:
			print("ADVERTENCIA: Main todavía no está disponible")

	return {
		"language": Settings.language,
		"idiomaConfigurado": idioma_configurado,
		"disco": DISCO_ACTUAL,
		"discoConfigurado": disco_configurado,
		"modoControles": int(Settings.modo_controles),
		"opcionInteraccion": Settings.opcion_interaccion,
		"controlesConfigurados": controles_configurados,
		"vida": Settings.vidaActual,
		"energia": Settings.energiaActual,
		"nivelActual": Settings.nivelActual,
		"nivelesCompletados": Settings.obtener_ids_niveles_completados(),
		"objetosVidaObtenidos": Settings.objetosVidaObtenidos,
		"objetosEnergiaObtenidos": Settings.objetosEnergiaObtenidos,
		"partidaFinalizada": partidaFinalizada
	}


# =========================================================
# GUARDAR PARTIDA COMPLETA
# =========================================================

func guardar_partida() -> void:
	if not asegurar_carpeta():
		return
	if not _escribir_datos_partida():
		return
	print("PARTIDA GUARDADA")
	print("Nivel guardado: ", Settings.nivelActual)
	print("Partida finalizada: ", partidaFinalizada)
	print("Ubicación: ", RUTA_GUARDADO)


func _escribir_datos_partida() -> bool:
	var datos := _obtener_datos_partida()
	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo == null:
		advertencia_disco = "No se pudo escribir la partida en el disco " + DISCO_ACTUAL + ". Puede que no haya espacio o que no se tengan permisos."
		push_warning(advertencia_disco)
		return false

	archivo.store_var(datos)
	var error_escritura := archivo.get_error()
	archivo.close()
	if error_escritura != OK:
		advertencia_disco = "No se pudo completar el guardado. Comprueba el espacio disponible en el disco " + DISCO_ACTUAL + "."
		push_warning(advertencia_disco)
		return false

	advertencia_disco = ""
	return true


# =========================================================
# CARGAR PARTIDA COMPLETA
# =========================================================

func cargar_partida() -> bool:
	_asegurar_disco_inicializado()
	if not FileAccess.file_exists(RUTA_GUARDADO):
		print("No existe una partida guardada")
		print("Ruta buscada: ", RUTA_GUARDADO)
		return false

	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo == null:
		print("No se pudo abrir la partida")
		return false

	var datos = archivo.get_var()
	archivo.close()
	if datos == null or not datos is Dictionary:
		print("El archivo de guardado no contiene datos válidos")
		return false

	partidaFinalizada = bool(datos.get("partidaFinalizada", false))

	# Las preferencias globales ya guardadas tienen prioridad. Si no hay una
	# preferencia global, se intenta recuperar la que hubiera en el save antiguo.
	if not idioma_configurado and datos.has("language"):
		Settings.language = str(datos.get("language", "es"))
		if Settings.language not in ["es", "en"]:
			Settings.language = "es"
		idioma_configurado = true

	if not controles_configurados and datos.has("modoControles"):
		var modo_guardado: int = int(
			datos.get("modoControles", Settings.ModoControles.MODO_A)
		)
		var modo_partida: int = int(Settings.ModoControles.MODO_A)
		if modo_guardado == int(Settings.ModoControles.MODO_B):
			modo_partida = int(Settings.ModoControles.MODO_B)
		Settings.cambiar_modo_controles(modo_partida)
		Settings.cambiar_opcion_interaccion(
			int(datos.get("opcionInteraccion", 0))
		)
		controles_configurados = bool(datos.get("controlesConfigurados", true))

	Settings.vidaActual = int(datos.get("vida", Settings.vidaInicial))
	Settings.energiaActual = int(datos.get("energia", Settings.energiaInicial))
	Settings.nivelActual = str(datos.get("nivelActual", ""))
	var ids_guardados: Array = datos.get("nivelesCompletados", [])
	Settings.establecer_niveles_completados(ids_guardados)
	Settings.objetosVidaObtenidos = datos.get("objetosVidaObtenidos", [])
	Settings.objetosEnergiaObtenidos = datos.get("objetosEnergiaObtenidos", [])

	# Si se recuperaron preferencias de un save antiguo, migrarlas al archivo
	# global para que no dependan únicamente de la existencia de esa partida.
	guardar_configuracion_preferencias()

	print("PARTIDA CARGADA")
	print("Nivel guardado: ", Settings.nivelActual)
	print("Partida finalizada: ", partidaFinalizada)
	print("Disco actual: ", DISCO_ACTUAL)
	return true


# =========================================================
# OBTENER IDIOMA GUARDADO
# =========================================================

func obtener_idioma_guardado():
	var config := ConfigFile.new()
	if config.load(RUTA_CONFIGURACION_PREFERENCIAS) == OK:
		if bool(config.get_value("estado", "idioma_configurado", false)):
			return str(config.get_value("preferencias", "language", "es"))

	_asegurar_disco_inicializado()
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return null

	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo == null:
		return null
	var datos = archivo.get_var()
	archivo.close()
	if datos == null or not datos is Dictionary or not datos.has("language"):
		return null
	return datos["language"]


# =========================================================
# INICIAR NUEVA PARTIDA
# =========================================================

func iniciar_nueva_partida() -> void:
	partidaFinalizada = false
	Settings.vidaActual = Settings.vidaInicial
	Settings.energiaActual = Settings.energiaInicial
	Settings.nivelActual = ""
	Settings.reiniciar_niveles_completados()
	Settings.objetosVidaObtenidos.clear()
	Settings.objetosEnergiaObtenidos.clear()
	guardar_partida()
	print("NUEVA PARTIDA CREADA")


# =========================================================
# COMPROBAR SI EXISTE UNA PARTIDA CONTINUABLE
# =========================================================

func existe_partida() -> bool:
	_asegurar_disco_inicializado()
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return false

	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo == null:
		return false
	var datos = archivo.get_var()
	archivo.close()
	if datos == null or not datos is Dictionary:
		return false
	if datos.get("partidaFinalizada", false):
		return false
	if not datos.has("nivelActual") or str(datos["nivelActual"]) == "":
		return false
	return true


# =========================================================
# BORRAR PARTIDA ACTUAL
# =========================================================

func borrar_partida() -> void:
	_asegurar_disco_inicializado()
	if FileAccess.file_exists(RUTA_GUARDADO):
		var resultado := DirAccess.remove_absolute(RUTA_GUARDADO)
		if resultado == OK:
			print("PARTIDA BORRADA EN DISCO ", DISCO_ACTUAL)
			partidaFinalizada = false
		else:
			advertencia_disco = "No se pudo borrar la partida del disco " + DISCO_ACTUAL + "."
			push_warning(advertencia_disco)
	else:
		print("No existe una partida para borrar")


# =========================================================
# ESCRIBIR EN DISCO BORRANDO ANTES EL ARCHIVO ANTERIOR
# =========================================================

func escribir_en_disco() -> bool:
	if not asegurar_carpeta():
		return false

	if FileAccess.file_exists(RUTA_GUARDADO):
		var resultado := DirAccess.remove_absolute(RUTA_GUARDADO)
		if resultado != OK:
			advertencia_disco = "No se pudo borrar la partida existente del disco " + DISCO_ACTUAL + ". No se escribió una nueva partida."
			push_warning(advertencia_disco)
			return false

	return _escribir_datos_partida()


# =========================================================
# CAMBIAR AL DISCO C O D
# =========================================================

func cambiar_a_c() -> bool:
	return _transferir_a_disco("C")


func cambiar_a_d() -> bool:
	return _transferir_a_disco("D")


func _transferir_a_disco(disco_destino: String) -> bool:
	_asegurar_disco_inicializado()
	advertencia_disco = ""
	disco_destino = disco_destino.to_upper()

	if not _es_disco_valido(disco_destino):
		advertencia_disco = "El disco de destino no es válido."
		push_warning(advertencia_disco)
		return false

	if disco_destino == DISCO_ACTUAL:
		print("La partida ya está en el disco ", disco_destino)
		return true

	var carpeta_origen := CARPETA_GUARDADO
	var carpeta_destino := _ruta_carpeta_para_disco(disco_destino)
	var origen_existe := DirAccess.dir_exists_absolute(carpeta_origen)

	# Si el destino ya tiene contenido, no se sobrescribe nada sin confirmación.
	if DirAccess.dir_exists_absolute(carpeta_destino) and _carpeta_tiene_contenido(carpeta_destino):
		advertencia_disco = "El disco " + disco_destino + " ya contiene datos en " + carpeta_destino + ". No se modificó ningún archivo."
		push_warning(advertencia_disco)
		return false

	if not origen_existe:
		var crear_resultado := DirAccess.make_dir_recursive_absolute(carpeta_destino)
		if crear_resultado != OK:
			advertencia_disco = "No se pudo crear la carpeta de guardado en el disco " + disco_destino + ". Comprueba permisos y espacio disponible."
			push_warning(advertencia_disco)
			return false
		_configurar_disco(disco_destino)
		disco_configurado = true
		guardar_configuracion_preferencias()
		print("DISCO DE GUARDADO CAMBIADO A ", DISCO_ACTUAL)
		return true

	var tamaño_origen := _obtener_tamano_carpeta(carpeta_origen)
	var espacio_libre := _obtener_espacio_libre(disco_destino)
	if espacio_libre >= 0 and espacio_libre < tamaño_origen:
		advertencia_disco = "No hay espacio suficiente en el disco " + disco_destino + " para transferir la partida."
		push_warning(advertencia_disco)
		return false

	# Copiar primero. El origen no se toca hasta verificar la copia.
	if not DirAccess.dir_exists_absolute(carpeta_destino):
		var crear_destino := DirAccess.make_dir_recursive_absolute(carpeta_destino)
		if crear_destino != OK:
			advertencia_disco = "No se pudo crear la carpeta de destino en el disco " + disco_destino + ". Comprueba permisos y espacio disponible."
			push_warning(advertencia_disco)
			return false

	if not _copiar_contenido(carpeta_origen, carpeta_destino):
		_vaciar_carpeta(carpeta_destino)
		advertencia_disco = "Falló la copia al disco " + disco_destino + ". El guardado original se conservó. Comprueba el espacio disponible y los permisos."
		push_warning(advertencia_disco)
		return false

	if not _verificar_copia(carpeta_origen, carpeta_destino):
		_vaciar_carpeta(carpeta_destino)
		advertencia_disco = "La copia al disco " + disco_destino + " no pasó la verificación. El guardado original se conservó."
		push_warning(advertencia_disco)
		return false

	# La copia está verificada: cambiar las rutas y luego borrar el origen.
	_configurar_disco(disco_destino)
	disco_configurado = true
	guardar_configuracion_preferencias()

	if not _borrar_carpeta_completa(carpeta_origen):
		advertencia_disco = "La partida se copió al disco " + disco_destino + ", pero no se pudo borrar la carpeta antigua del disco " + ("C" if disco_destino == "D" else "D") + ". Hay una copia adicional; revisa los archivos antes de volver a transferir."
		push_warning(advertencia_disco)
		return false

	advertencia_disco = ""
	print("TRANSFERENCIA COMPLETADA. DISCO ACTUAL: ", DISCO_ACTUAL)
	print("Carpeta activa: ", CARPETA_GUARDADO)
	return true


# =========================================================
# UTILIDADES PARA COPIAR Y BORRAR CARPETAS
# =========================================================

func _carpeta_tiene_contenido(ruta: String) -> bool:
	var directorio := DirAccess.open(ruta)
	if directorio == null:
		return true

	directorio.list_dir_begin()
	var nombre := directorio.get_next()
	while nombre != "":
		if nombre != "." and nombre != "..":
			directorio.list_dir_end()
			return true
		nombre = directorio.get_next()
	directorio.list_dir_end()
	return false


func _copiar_contenido(origen: String, destino: String) -> bool:
	var dir_origen := DirAccess.open(origen)
	if dir_origen == null:
		return false
	if not DirAccess.dir_exists_absolute(destino):
		if DirAccess.make_dir_recursive_absolute(destino) != OK:
			return false

	dir_origen.list_dir_begin()
	var nombre := dir_origen.get_next()
	while nombre != "":
		if nombre == "." or nombre == "..":
			nombre = dir_origen.get_next()
			continue

		var ruta_origen := origen.path_join(nombre)
		var ruta_destino := destino.path_join(nombre)
		if dir_origen.current_is_dir():
			if not _copiar_contenido(ruta_origen, ruta_destino):
				dir_origen.list_dir_end()
				return false
		else:
			var error_copia := DirAccess.copy_absolute(ruta_origen, ruta_destino)
			if error_copia != OK:
				dir_origen.list_dir_end()
				return false
		nombre = dir_origen.get_next()

	dir_origen.list_dir_end()
	return true


func _verificar_copia(origen: String, destino: String) -> bool:
	var dir_origen := DirAccess.open(origen)
	if dir_origen == null or not DirAccess.dir_exists_absolute(destino):
		return false

	dir_origen.list_dir_begin()
	var nombre := dir_origen.get_next()
	while nombre != "":
		if nombre == "." or nombre == "..":
			nombre = dir_origen.get_next()
			continue

		var ruta_origen := origen.path_join(nombre)
		var ruta_destino := destino.path_join(nombre)
		if dir_origen.current_is_dir():
			if not _verificar_copia(ruta_origen, ruta_destino):
				dir_origen.list_dir_end()
				return false
		else:
			if not FileAccess.file_exists(ruta_destino):
				dir_origen.list_dir_end()
				return false
			if FileAccess.get_size(ruta_origen) != FileAccess.get_size(ruta_destino):
				dir_origen.list_dir_end()
				return false
		nombre = dir_origen.get_next()

	dir_origen.list_dir_end()
	return true


func _obtener_tamano_carpeta(ruta: String) -> int:
	var total := 0
	var directorio := DirAccess.open(ruta)
	if directorio == null:
		return 0

	directorio.list_dir_begin()
	var nombre := directorio.get_next()
	while nombre != "":
		if nombre == "." or nombre == "..":
			nombre = directorio.get_next()
			continue

		var ruta_hijo := ruta.path_join(nombre)
		if directorio.current_is_dir():
			total += _obtener_tamano_carpeta(ruta_hijo)
		else:
			total += FileAccess.get_size(ruta_hijo)
		nombre = directorio.get_next()

	directorio.list_dir_end()
	return total


func _obtener_espacio_libre(disco: String) -> int:
	# Godot no expone de forma portable el espacio libre de una unidad.
	# En Windows se consulta PowerShell. Si falla, devuelve -1 y se intenta copiar.
	if OS.get_name() != "Windows":
		return -1

	var salida: Array = []
	var codigo := OS.execute(
		"powershell.exe",
		["-NoProfile", "-Command", "(Get-PSDrive -Name " + disco + ").Free"],
		salida,
		true
	)
	if codigo != 0 or salida.is_empty():
		return -1

	var texto := str(salida[0]).strip_edges()
	if not texto.is_valid_int():
		return -1
	return texto.to_int()


func _vaciar_carpeta(ruta: String) -> void:
	if not DirAccess.dir_exists_absolute(ruta):
		return
	var directorio := DirAccess.open(ruta)
	if directorio == null:
		return

	directorio.list_dir_begin()
	var nombre := directorio.get_next()
	while nombre != "":
		if nombre == "." or nombre == "..":
			nombre = directorio.get_next()
			continue
		var ruta_hijo := ruta.path_join(nombre)
		if directorio.current_is_dir():
			_borrar_carpeta_completa(ruta_hijo)
		else:
			DirAccess.remove_absolute(ruta_hijo)
		nombre = directorio.get_next()
	directorio.list_dir_end()


func _borrar_carpeta_completa(ruta: String) -> bool:
	if not DirAccess.dir_exists_absolute(ruta):
		return true

	var directorio := DirAccess.open(ruta)
	if directorio == null:
		return false

	directorio.list_dir_begin()
	var nombre := directorio.get_next()
	while nombre != "":
		if nombre == "." or nombre == "..":
			nombre = directorio.get_next()
			continue

		var ruta_hijo := ruta.path_join(nombre)
		var es_directorio := directorio.current_is_dir()
		if es_directorio:
			if not _borrar_carpeta_completa(ruta_hijo):
				directorio.list_dir_end()
				return false
		else:
			if DirAccess.remove_absolute(ruta_hijo) != OK:
				directorio.list_dir_end()
				return false
		nombre = directorio.get_next()

	directorio.list_dir_end()
	return DirAccess.remove_absolute(ruta) == OK
