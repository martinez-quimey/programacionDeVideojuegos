extends Node

# =========================================================
# CONFIGURACIÓN DE GUARDADO
# =========================================================

const NOMBRE_CARPETA_GUARDADO := "evaTwoTalesKitsuneSave"
const DISCO_POR_DEFECTO := "C"
const NOMBRE_ARCHIVO_PARTIDA := "partida.save"
const NOMBRE_ARCHIVO_PREFERENCIAS := "preferencias_eva.cfg"

# El HUD selecciona el modo al entrar en el árbol.
# En modo navegador no se leen ni escriben archivos.
var modo_guardado_en_disco: bool = true
var modo_configurado_por_hud: bool = false

var DISCO_ACTUAL: String = ""
var CARPETA_GUARDADO: String = ""
var RUTA_GUARDADO: String = ""
var RUTA_PREFERENCIAS: String = ""

var advertencia_disco: String = ""
var partidaFinalizada: bool = false

var idioma_configurado: bool = false
var disco_configurado: bool = false
var controles_configurados: bool = false

# En modo navegador, estos diccionarios son la única fuente de datos.
# Se mantienen mientras el autoload Save siga vivo; no sobreviven al cierre
# o recarga de la página.
var datos_partida_memoria: Dictionary = {}

var preferencias_memoria: Dictionary = {
	"estado": {
		"idioma_configurado": false,
		"disco_configurado": true,
		"controles_configurados": false
	},
	"preferencias": {
		"language": "es",
		"modo_controles": 0,
		"opcion_interaccion": 0
	}
}

var volumenes_memoria: Dictionary = {
	"efectos": 50.0,
	"musica": 50.0,
	"voces": 50.0
}


# =========================================================
# INICIALIZACIÓN
# =========================================================

func _ready() -> void:
	# El modo se selecciona desde HUD._enter_tree().
	# No detectar discos aquí: el HUD aún no ha elegido el modo.
	pass


func configurar_modo_guardado(usar_guardado_en_disco: bool) -> void:
	modo_guardado_en_disco = usar_guardado_en_disco
	modo_configurado_por_hud = true
	advertencia_disco = ""

	if modo_guardado_en_disco:
		detectar_disco_actual()
		_cargar_configuracion_preferencias()
	else:
		# No acceder a C:/, D:/ ni a archivos user:// en este modo.
		DISCO_ACTUAL = ""
		CARPETA_GUARDADO = ""
		RUTA_GUARDADO = ""
		RUTA_PREFERENCIAS = ""
		disco_configurado = true
		_cargar_configuracion_preferencias()

	if controles_configurados:
		Settings.cambiar_modo_controles(int(Settings.modo_controles))
		Settings.cambiar_opcion_interaccion(int(Settings.opcion_interaccion))


# =========================================================
# RUTAS
# =========================================================

func _es_disco_valido(disco: String) -> bool:
	return disco.to_upper() in ["C", "D"]


func _ruta_carpeta_para_disco(disco: String) -> String:
	return disco.to_upper() + ":/" + NOMBRE_CARPETA_GUARDADO


func _configurar_disco(disco: String) -> void:
	DISCO_ACTUAL = disco.to_upper()
	CARPETA_GUARDADO = _ruta_carpeta_para_disco(DISCO_ACTUAL)
	RUTA_GUARDADO = CARPETA_GUARDADO.path_join(NOMBRE_ARCHIVO_PARTIDA)
	RUTA_PREFERENCIAS = CARPETA_GUARDADO.path_join(
		NOMBRE_ARCHIVO_PREFERENCIAS
	)


func _asegurar_disco_inicializado() -> void:
	if not modo_guardado_en_disco:
		return

	if (
		DISCO_ACTUAL.is_empty()
		or CARPETA_GUARDADO.is_empty()
		or RUTA_GUARDADO.is_empty()
		or RUTA_PREFERENCIAS.is_empty()
	):
		detectar_disco_actual()


# =========================================================
# DETECTAR EL DISCO
# =========================================================

func detectar_disco_actual() -> String:
	if not modo_guardado_en_disco:
		DISCO_ACTUAL = ""
		CARPETA_GUARDADO = ""
		RUTA_GUARDADO = ""
		RUTA_PREFERENCIAS = ""
		disco_configurado = true
		return ""

	var carpeta_c := _ruta_carpeta_para_disco("C")
	var carpeta_d := _ruta_carpeta_para_disco("D")

	var partida_c := carpeta_c.path_join(NOMBRE_ARCHIVO_PARTIDA)
	var partida_d := carpeta_d.path_join(NOMBRE_ARCHIVO_PARTIDA)
	var preferencias_c := carpeta_c.path_join(NOMBRE_ARCHIVO_PREFERENCIAS)
	var preferencias_d := carpeta_d.path_join(NOMBRE_ARCHIVO_PREFERENCIAS)

	if FileAccess.file_exists(partida_c):
		_configurar_disco("C")
		disco_configurado = true
	elif FileAccess.file_exists(partida_d):
		_configurar_disco("D")
		disco_configurado = true
	elif FileAccess.file_exists(preferencias_c):
		_configurar_disco("C")
	elif FileAccess.file_exists(preferencias_d):
		_configurar_disco("D")
	elif DirAccess.dir_exists_absolute(carpeta_c):
		_configurar_disco("C")
	elif DirAccess.dir_exists_absolute(carpeta_d):
		_configurar_disco("D")
	else:
		_configurar_disco(DISCO_POR_DEFECTO)

	print("DISCO DE GUARDADO: ", DISCO_ACTUAL)
	print("CARPETA: ", CARPETA_GUARDADO)
	print("PARTIDA: ", RUTA_GUARDADO)
	print("PREFERENCIAS: ", RUTA_PREFERENCIAS)

	return DISCO_ACTUAL


# =========================================================
# CARGAR PREFERENCIAS
# =========================================================

func _cargar_configuracion_preferencias() -> void:
	if not modo_guardado_en_disco:
		var estado_memoria: Dictionary = preferencias_memoria.get("estado", {})
		var opciones_memoria: Dictionary = preferencias_memoria.get("preferencias", {})

		idioma_configurado = bool(
			estado_memoria.get("idioma_configurado", false)
		)
		disco_configurado = true
		controles_configurados = bool(
			estado_memoria.get("controles_configurados", false)
		)

		if idioma_configurado:
			Settings.language = str(
				opciones_memoria.get("language", "es")
			)
			if Settings.language not in ["es", "en"]:
				Settings.language = "es"
				idioma_configurado = false

		if controles_configurados:
			var modo_memoria := int(
				opciones_memoria.get("modo_controles", 0)
			)
			if modo_memoria == int(Settings.ModoControles.MODO_B):
				Settings.modo_controles = Settings.ModoControles.MODO_B
			else:
				Settings.modo_controles = Settings.ModoControles.MODO_A

			Settings.opcion_interaccion = clampi(
				int(opciones_memoria.get("opcion_interaccion", 0)),
				0,
				1
			)

		return

	_asegurar_disco_inicializado()

	var config := ConfigFile.new()
	var error_carga := config.load(RUTA_PREFERENCIAS)

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

	if controles_configurados:
		var modo_guardado: int = int(
			config.get_value(
				"preferencias",
				"modo_controles",
				Settings.ModoControles.MODO_A
			)
		)

		if modo_guardado == int(Settings.ModoControles.MODO_B):
			Settings.modo_controles = Settings.ModoControles.MODO_B
		else:
			Settings.modo_controles = Settings.ModoControles.MODO_A

		Settings.opcion_interaccion = clampi(
			int(config.get_value("preferencias", "opcion_interaccion", 0)),
			0,
			1
		)

	print("PREFERENCIAS CARGADAS: ", RUTA_PREFERENCIAS)


# =========================================================
# GUARDAR PREFERENCIAS
# =========================================================

func guardar_configuracion_preferencias() -> bool:
	if not modo_guardado_en_disco:
		disco_configurado = true
		preferencias_memoria = {
			"estado": {
				"idioma_configurado": idioma_configurado,
				"disco_configurado": true,
				"controles_configurados": controles_configurados
			},
			"preferencias": {
				"language": Settings.language,
				"modo_controles": int(Settings.modo_controles),
				"opcion_interaccion": int(Settings.opcion_interaccion)
			}
		}
		return true

	_asegurar_disco_inicializado()

	if not asegurar_carpeta():
		return false

	var config := ConfigFile.new()
	config.load(RUTA_PREFERENCIAS)

	config.set_value("estado", "idioma_configurado", idioma_configurado)
	config.set_value("estado", "disco_configurado", disco_configurado)
	config.set_value("estado", "controles_configurados", controles_configurados)

	config.set_value("preferencias", "language", Settings.language)
	config.set_value("preferencias", "disco", DISCO_ACTUAL)
	config.set_value("preferencias", "modo_controles", int(Settings.modo_controles))
	config.set_value("preferencias", "opcion_interaccion", Settings.opcion_interaccion)

	var error_guardado := config.save(RUTA_PREFERENCIAS)
	if error_guardado != OK:
		advertencia_disco = (
			"No se pudieron guardar las preferencias. Error: "
			+ str(error_guardado)
		)
		push_warning(advertencia_disco)
		return false

	print("PREFERENCIAS GUARDADAS: ", RUTA_PREFERENCIAS)
	return true


func configuracion_inicial_completa() -> bool:
	if modo_guardado_en_disco:
		return (
			idioma_configurado
			and disco_configurado
			and controles_configurados
		)

	return idioma_configurado and controles_configurados


func confirmar_controles_configurados() -> void:
	controles_configurados = true
	guardar_configuracion_preferencias()


func guardar_idioma() -> void:
	idioma_configurado = true
	guardar_configuracion_preferencias()
	print("IDIOMA CONFIGURADO: ", Settings.language)


func obtener_idioma_guardado():
	if not modo_guardado_en_disco:
		if bool(
			preferencias_memoria.get("estado", {}).get(
				"idioma_configurado", false
			)
		):
			return str(
				preferencias_memoria.get("preferencias", {}).get(
					"language", "es"
				)
			)
		return null

	_asegurar_disco_inicializado()
	var config := ConfigFile.new()

	if config.load(RUTA_PREFERENCIAS) == OK:
		if bool(config.get_value("estado", "idioma_configurado", false)):
			return str(config.get_value("preferencias", "language", "es"))

	return null


# =========================================================
# SELECCIÓN INICIAL DEL DISCO
# =========================================================

func seleccionar_disco_inicial(disco: String) -> bool:
	if not modo_guardado_en_disco:
		advertencia_disco = "La selección de disco está desactivada en este modo."
		return false

	disco = disco.to_upper()
	if not _es_disco_valido(disco):
		advertencia_disco = "El disco seleccionado no es válido."
		return false

	if DirAccess.open(disco + ":/") == null:
		advertencia_disco = (
			"El disco " + disco
			+ " no está disponible. Selecciona una unidad existente."
		)
		return false

	_configurar_disco(disco)
	disco_configurado = true

	if not guardar_configuracion_preferencias():
		advertencia_disco = "No se pudo guardar la selección del disco."
		return false

	advertencia_disco = ""
	print("DISCO CONFIGURADO: ", DISCO_ACTUAL)
	print("CARPETA DE GUARDADO: ", CARPETA_GUARDADO)
	return true


# =========================================================
# ASEGURAR CARPETA
# =========================================================

func asegurar_carpeta() -> bool:
	if not modo_guardado_en_disco:
		return false

	_asegurar_disco_inicializado()

	if DirAccess.dir_exists_absolute(CARPETA_GUARDADO):
		return true

	var resultado := DirAccess.make_dir_recursive_absolute(CARPETA_GUARDADO)
	if resultado != OK:
		advertencia_disco = (
			"No se pudo crear la carpeta de guardado en el disco "
			+ DISCO_ACTUAL
			+ ". Comprueba los permisos y el espacio disponible."
		)
		push_warning(advertencia_disco)
		return false

	print("CARPETA CREADA: ", CARPETA_GUARDADO)
	return true


# =========================================================
# PREPARAR DATOS DE PARTIDA
# =========================================================

func _obtener_datos_partida() -> Dictionary:
	if Settings.nivelActual == "" and not partidaFinalizada:
		var main = Settings.getMain()
		if main != null:
			var ruta_nivel = main.obtener_ruta_nivel_actual()
			if ruta_nivel != "":
				Settings.nivelActual = ruta_nivel
				print("NIVEL ACTUAL GUARDADO: ", Settings.nivelActual)

	return {
		"vida": Settings.vidaActual,
		"energia": Settings.energiaActual,
		"nivelActual": Settings.nivelActual,
		"nivelesCompletados": Settings.obtener_ids_niveles_completados(),
		"objetosVidaObtenidos": Settings.objetosVidaObtenidos,
		"objetosEnergiaObtenidos": Settings.objetosEnergiaObtenidos,
		"partidaFinalizada": partidaFinalizada
	}


# =========================================================
# GUARDAR PARTIDA
# =========================================================

func guardar_partida() -> void:
	if not modo_guardado_en_disco:
		datos_partida_memoria = _obtener_datos_partida().duplicate(true)
		print("PARTIDA GUARDADA EN MEMORIA")
		print("Nivel: ", Settings.nivelActual)
		print("Finalizada: ", partidaFinalizada)
		return

	if not asegurar_carpeta():
		return
	if not _escribir_datos_partida():
		return

	print("PARTIDA GUARDADA")
	print("Nivel: ", Settings.nivelActual)
	print("Finalizada: ", partidaFinalizada)
	print("Ubicación: ", RUTA_GUARDADO)


func _escribir_datos_partida() -> bool:
	var datos := _obtener_datos_partida()

	if not modo_guardado_en_disco:
		datos_partida_memoria = datos.duplicate(true)
		return true

	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo == null:
		advertencia_disco = (
			"No se pudo escribir la partida en el disco "
			+ DISCO_ACTUAL
			+ ". Comprueba los permisos y el espacio disponible."
		)
		push_warning(advertencia_disco)
		return false

	archivo.store_var(datos)
	var error_escritura := archivo.get_error()
	archivo.close()

	if error_escritura != OK:
		advertencia_disco = "No se pudo completar el guardado."
		push_warning(advertencia_disco)
		return false

	advertencia_disco = ""
	return true


# =========================================================
# CARGAR PARTIDA
# =========================================================

func cargar_partida() -> bool:
	var datos

	if not modo_guardado_en_disco:
		if datos_partida_memoria.is_empty():
			print("No hay partida guardada en memoria.")
			return false
		datos = datos_partida_memoria.duplicate(true)
	else:
		_asegurar_disco_inicializado()
		if not FileAccess.file_exists(RUTA_GUARDADO):
			print("No existe una partida guardada.")
			print("Ruta buscada: ", RUTA_GUARDADO)
			return false

		var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
		if archivo == null:
			push_warning("No se pudo abrir la partida.")
			return false

		datos = archivo.get_var()
		archivo.close()

	if datos == null or not datos is Dictionary:
		push_warning("El archivo de partida no contiene datos válidos.")
		return false

	partidaFinalizada = bool(datos.get("partidaFinalizada", false))
	Settings.vidaActual = int(datos.get("vida", Settings.vidaInicial))
	Settings.energiaActual = int(datos.get("energia", Settings.energiaInicial))
	Settings.nivelActual = str(datos.get("nivelActual", ""))

	var ids_guardados: Array = datos.get("nivelesCompletados", [])
	Settings.establecer_niveles_completados(ids_guardados)

	Settings.objetosVidaObtenidos = datos.get("objetosVidaObtenidos", [])
	Settings.objetosEnergiaObtenidos = datos.get("objetosEnergiaObtenidos", [])

	print("PARTIDA CARGADA")
	print("Nivel: ", Settings.nivelActual)
	print("Finalizada: ", partidaFinalizada)
	if modo_guardado_en_disco:
		print("Disco: ", DISCO_ACTUAL)
	else:
		print("Origen: memoria")
	return true


func hay_datos_guardados() -> bool:
	if not modo_guardado_en_disco:
		return not datos_partida_memoria.is_empty()

	_asegurar_disco_inicializado()
	return FileAccess.file_exists(RUTA_GUARDADO)


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
	if not modo_guardado_en_disco:
		print("PARTIDA ALMACENADA SOLO EN MEMORIA")
	else:
		print("PREFERENCIAS CONSERVADAS: ", RUTA_PREFERENCIAS)


# =========================================================
# COMPROBAR PARTIDA CONTINUABLE
# =========================================================

func existe_partida() -> bool:
	var datos

	if not modo_guardado_en_disco:
		if datos_partida_memoria.is_empty():
			return false
		datos = datos_partida_memoria
	else:
		_asegurar_disco_inicializado()
		if not FileAccess.file_exists(RUTA_GUARDADO):
			return false

		var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
		if archivo == null:
			return false
		datos = archivo.get_var()
		archivo.close()

	if datos == null or not datos is Dictionary:
		return false
	if bool(datos.get("partidaFinalizada", false)):
		return false
	if not datos.has("nivelActual") or str(datos["nivelActual"]) == "":
		return false
	return true


# =========================================================
# BORRAR PARTIDA
# =========================================================

func borrar_partida() -> void:
	if not modo_guardado_en_disco:
		datos_partida_memoria.clear()
		partidaFinalizada = false
		print("PARTIDA BORRADA DE MEMORIA")
		return

	_asegurar_disco_inicializado()
	if FileAccess.file_exists(RUTA_GUARDADO):
		var resultado := DirAccess.remove_absolute(RUTA_GUARDADO)
		if resultado == OK:
			print("PARTIDA BORRADA: ", RUTA_GUARDADO)
			partidaFinalizada = false
		else:
			advertencia_disco = "No se pudo borrar la partida."
			push_warning(advertencia_disco)
	else:
		print("No existe una partida para borrar.")


# =========================================================
# ESCRIBIR EN DISCO
# =========================================================

func escribir_en_disco() -> bool:
	if not modo_guardado_en_disco:
		advertencia_disco = "La escritura en disco está desactivada en este modo."
		return false

	if not asegurar_carpeta():
		return false

	if FileAccess.file_exists(RUTA_GUARDADO):
		var resultado := DirAccess.remove_absolute(RUTA_GUARDADO)
		if resultado != OK:
			advertencia_disco = (
				"No se pudo borrar la partida existente. "
				+ "No se escribió una nueva partida."
			)
			push_warning(advertencia_disco)
			return false

	return _escribir_datos_partida()


# =========================================================
# CAMBIAR DE DISCO
# =========================================================

func cambiar_a_c() -> bool:
	return _transferir_a_disco("C")


func cambiar_a_d() -> bool:
	return _transferir_a_disco("D")


func _transferir_a_disco(disco_destino: String) -> bool:
	if not modo_guardado_en_disco:
		advertencia_disco = "El cambio de disco está desactivado en este modo."
		return false

	_asegurar_disco_inicializado()
	advertencia_disco = ""
	disco_destino = disco_destino.to_upper()

	if not _es_disco_valido(disco_destino):
		advertencia_disco = "El disco de destino no es válido."
		return false

	if disco_destino == DISCO_ACTUAL:
		print("La partida ya está en el disco ", disco_destino)
		return true

	if DirAccess.open(disco_destino + ":/") == null:
		advertencia_disco = "El disco " + disco_destino + " no está disponible."
		return false

	var carpeta_origen := CARPETA_GUARDADO
	var carpeta_destino := _ruta_carpeta_para_disco(disco_destino)
	var origen_existe := DirAccess.dir_exists_absolute(carpeta_origen)

	if (
		DirAccess.dir_exists_absolute(carpeta_destino)
		and _carpeta_tiene_contenido(carpeta_destino)
	):
		advertencia_disco = (
			"El destino ya contiene datos en "
			+ carpeta_destino
			+ ". No se modificó ningún archivo."
		)
		return false

	if not origen_existe:
		if DirAccess.make_dir_recursive_absolute(carpeta_destino) != OK:
			advertencia_disco = "No se pudo crear la carpeta de destino."
			return false

		_configurar_disco(disco_destino)
		disco_configurado = true
		if not guardar_configuracion_preferencias():
			return false
		return true

	if not DirAccess.dir_exists_absolute(carpeta_destino):
		if DirAccess.make_dir_recursive_absolute(carpeta_destino) != OK:
			advertencia_disco = "No se pudo crear la carpeta de destino."
			return false

	if not _copiar_contenido(carpeta_origen, carpeta_destino):
		_vaciar_carpeta(carpeta_destino)
		advertencia_disco = "Falló la copia. El guardado original se conservó."
		return false

	if not _verificar_copia(carpeta_origen, carpeta_destino):
		_vaciar_carpeta(carpeta_destino)
		advertencia_disco = (
			"La copia no pasó la verificación. "
			+ "El guardado original se conservó."
		)
		return false

	_configurar_disco(disco_destino)
	disco_configurado = true

	if not guardar_configuracion_preferencias():
		advertencia_disco = (
			"La carpeta se copió, pero no se pudo actualizar "
			+ "la configuración del destino. El origen se conservó."
		)
		return false

	if not _borrar_carpeta_completa(carpeta_origen):
		advertencia_disco = (
			"La copia se realizó, pero no se pudo borrar "
			+ "la carpeta antigua del disco de origen."
		)
		return false

	advertencia_disco = ""
	print("TRANSFERENCIA COMPLETADA")
	print("DISCO ACTUAL: ", DISCO_ACTUAL)
	print("CARPETA: ", CARPETA_GUARDADO)
	return true


# =========================================================
# UTILIDADES DE CARPETAS
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
		var es_directorio := dir_origen.current_is_dir()

		if es_directorio:
			if not _copiar_contenido(ruta_origen, ruta_destino):
				dir_origen.list_dir_end()
				return false
		else:
			if DirAccess.copy_absolute(ruta_origen, ruta_destino) != OK:
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
		var es_directorio := dir_origen.current_is_dir()

		if es_directorio:
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
		var es_directorio := directorio.current_is_dir()
		if es_directorio:
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
