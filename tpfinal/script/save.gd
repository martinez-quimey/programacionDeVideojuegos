
extends Node

# =========================================================
# CONFIGURACIÓN DE GUARDADO
# =========================================================

const NOMBRE_CARPETA_GUARDADO := "evaTwoTalesKitsuneSave"
const NOMBRE_ARCHIVO_PARTIDA := "partida.save"
const NOMBRE_ARCHIVO_PREFERENCIAS := "preferencias_eva.cfg"

# En modo persistente se utiliza user://.
# En modo memoria los datos solo viven mientras el juego está abierto.
#
# En Godot Web se fuerza el modo persistente porque user://
# utiliza el almacenamiento del navegador.

var modo_guardado_en_disco: bool = true
var modo_configurado_por_hud: bool = false

var CARPETA_GUARDADO: String = ""
var RUTA_GUARDADO: String = ""
var RUTA_PREFERENCIAS: String = ""

var advertencia_disco: String = ""
var partidaFinalizada: bool = false

var idioma_configurado: bool = false
var disco_configurado: bool = true
var controles_configurados: bool = false

# En modo memoria, estos diccionarios son la fuente de datos.
# Se mantienen mientras el autoload Save siga vivo.

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
	_configurar_rutas()
	_cargar_configuracion_preferencias()


func configurar_modo_guardado(usar_guardado_en_disco: bool) -> void:
	# Godot Web también puede guardar archivos en user://.
	# Por eso se fuerza el almacenamiento persistente en web.

	if OS.has_feature("web"):
		modo_guardado_en_disco = true
	else:
		modo_guardado_en_disco = usar_guardado_en_disco

	modo_configurado_por_hud = true
	advertencia_disco = ""

	if modo_guardado_en_disco:
		_configurar_rutas()
		_cargar_configuracion_preferencias()
	else:
		CARPETA_GUARDADO = ""
		RUTA_GUARDADO = ""
		RUTA_PREFERENCIAS = ""

		disco_configurado = true
		_cargar_configuracion_preferencias()

	if controles_configurados:
		Settings.cambiar_modo_controles(
			int(Settings.modo_controles)
		)
		Settings.cambiar_opcion_interaccion(
			int(Settings.opcion_interaccion)
		)


# =========================================================
# RUTAS
# =========================================================

func _configurar_rutas() -> void:
	CARPETA_GUARDADO = "user://".path_join(
		NOMBRE_CARPETA_GUARDADO
	)

	RUTA_GUARDADO = CARPETA_GUARDADO.path_join(
		NOMBRE_ARCHIVO_PARTIDA
	)

	RUTA_PREFERENCIAS = CARPETA_GUARDADO.path_join(
		NOMBRE_ARCHIVO_PREFERENCIAS
	)

	disco_configurado = true


func _asegurar_rutas_inicializadas() -> void:
	if not modo_guardado_en_disco:
		return

	if (
		CARPETA_GUARDADO.is_empty()
		or RUTA_GUARDADO.is_empty()
		or RUTA_PREFERENCIAS.is_empty()
	):
		_configurar_rutas()


# =========================================================
# CARGAR PREFERENCIAS
# =========================================================

func _cargar_configuracion_preferencias() -> void:

	# -----------------------------------------------------
	# MODO MEMORIA
	# -----------------------------------------------------

	if not modo_guardado_en_disco:
		var estado_memoria: Dictionary = preferencias_memoria.get(
			"estado", {}
		)

		var opciones_memoria: Dictionary = preferencias_memoria.get(
			"preferencias", {}
		)

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

	# -----------------------------------------------------
	# MODO PERSISTENTE
	# -----------------------------------------------------

	_asegurar_rutas_inicializadas()

	var config := ConfigFile.new()
	var error_carga := config.load(RUTA_PREFERENCIAS)

	if error_carga != OK:
		idioma_configurado = false
		disco_configurado = true
		controles_configurados = false
		return

	idioma_configurado = bool(
		config.get_value(
			"estado",
			"idioma_configurado",
			false
		)
	)

	# Ya no existe selección de disco.
	disco_configurado = true

	controles_configurados = bool(
		config.get_value(
			"estado",
			"controles_configurados",
			false
		)
	)

	if idioma_configurado:
		Settings.language = str(
			config.get_value(
				"preferencias",
				"language",
				"es"
			)
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
			int(
				config.get_value(
					"preferencias",
					"opcion_interaccion",
					0
				)
			),
			0,
			1
		)

	print("PREFERENCIAS CARGADAS: ", RUTA_PREFERENCIAS)


# =========================================================
# GUARDAR PREFERENCIAS
# =========================================================

func guardar_configuracion_preferencias() -> bool:

	# -----------------------------------------------------
	# MODO MEMORIA
	# -----------------------------------------------------

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

	# -----------------------------------------------------
	# MODO PERSISTENTE
	# -----------------------------------------------------

	_asegurar_rutas_inicializadas()

	if not asegurar_carpeta():
		return false

	var config := ConfigFile.new()

	# Cargar la configuración anterior si existe.
	config.load(RUTA_PREFERENCIAS)

	config.set_value(
		"estado",
		"idioma_configurado",
		idioma_configurado
	)

	config.set_value(
		"estado",
		"disco_configurado",
		true
	)

	config.set_value(
		"estado",
		"controles_configurados",
		controles_configurados
	)

	config.set_value(
		"preferencias",
		"language",
		Settings.language
	)

	config.set_value(
		"preferencias",
		"modo_controles",
		int(Settings.modo_controles)
	)

	config.set_value(
		"preferencias",
		"opcion_interaccion",
		int(Settings.opcion_interaccion)
	)

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


# =========================================================
# CONFIGURACIÓN INICIAL
# =========================================================

func configuracion_inicial_completa() -> bool:
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
				"idioma_configurado",
				false
			)
		):
			return str(
				preferencias_memoria.get("preferencias", {}).get(
					"language",
					"es"
				)
			)

		return null

	_asegurar_rutas_inicializadas()

	var config := ConfigFile.new()

	if config.load(RUTA_PREFERENCIAS) == OK:
		if bool(
			config.get_value(
				"estado",
				"idioma_configurado",
				false
			)
		):
			return str(
				config.get_value(
					"preferencias",
					"language",
					"es"
				)
			)

	return null


# =========================================================
# ASEGURAR CARPETA
# =========================================================

func asegurar_carpeta() -> bool:
	if not modo_guardado_en_disco:
		return false

	_asegurar_rutas_inicializadas()

	var ruta_absoluta := ProjectSettings.globalize_path(
		CARPETA_GUARDADO
	)

	if DirAccess.dir_exists_absolute(ruta_absoluta):
		return true

	var resultado := DirAccess.make_dir_recursive_absolute(
		ruta_absoluta
	)

	if resultado != OK:
		advertencia_disco = (
			"No se pudo crear la carpeta de guardado. "
			+ "Comprueba los permisos y el espacio disponible."
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

	# -----------------------------------------------------
	# MODO MEMORIA
	# -----------------------------------------------------

	if not modo_guardado_en_disco:
		datos_partida_memoria = _obtener_datos_partida().duplicate(true)

		print("PARTIDA GUARDADA EN MEMORIA")
		print("Nivel: ", Settings.nivelActual)
		print("Finalizada: ", partidaFinalizada)
		return

	# -----------------------------------------------------
	# MODO PERSISTENTE
	# -----------------------------------------------------

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

	_asegurar_rutas_inicializadas()

	var archivo := FileAccess.open(
		RUTA_GUARDADO,
		FileAccess.WRITE
	)

	if archivo == null:
		advertencia_disco = (
			"No se pudo escribir la partida. "
			+ "Comprueba los permisos y el espacio disponible."
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

	# -----------------------------------------------------
	# MODO MEMORIA
	# -----------------------------------------------------

	if not modo_guardado_en_disco:
		if datos_partida_memoria.is_empty():
			print("No hay partida guardada en memoria.")
			return false

		datos = datos_partida_memoria.duplicate(true)

	# -----------------------------------------------------
	# MODO PERSISTENTE
	# -----------------------------------------------------

	else:
		_asegurar_rutas_inicializadas()

		if not FileAccess.file_exists(RUTA_GUARDADO):
			print("No existe una partida guardada.")
			print("Ruta buscada: ", RUTA_GUARDADO)
			return false

		var archivo := FileAccess.open(
			RUTA_GUARDADO,
			FileAccess.READ
		)

		if archivo == null:
			push_warning("No se pudo abrir la partida.")
			return false

		datos = archivo.get_var()
		archivo.close()

	# -----------------------------------------------------
	# RESTAURAR DATOS
	# -----------------------------------------------------

	if datos == null or not datos is Dictionary:
		push_warning("El archivo de partida no contiene datos válidos.")
		return false

	partidaFinalizada = bool(
		datos.get("partidaFinalizada", false)
	)

	Settings.vidaActual = int(
		datos.get("vida", Settings.vidaInicial)
	)

	Settings.energiaActual = int(
		datos.get("energia", Settings.energiaInicial)
	)

	Settings.nivelActual = str(
		datos.get("nivelActual", "")
	)

	var ids_guardados: Array = datos.get(
		"nivelesCompletados",
		[]
	)

	Settings.establecer_niveles_completados(ids_guardados)

	Settings.objetosVidaObtenidos = datos.get(
		"objetosVidaObtenidos",
		[]
	)

	Settings.objetosEnergiaObtenidos = datos.get(
		"objetosEnergiaObtenidos",
		[]
	)

	print("PARTIDA CARGADA")
	print("Nivel: ", Settings.nivelActual)
	print("Finalizada: ", partidaFinalizada)

	if modo_guardado_en_disco:
		print("Origen: ", RUTA_GUARDADO)
	else:
		print("Origen: memoria")

	return true


func hay_datos_guardados() -> bool:
	if not modo_guardado_en_disco:
		return not datos_partida_memoria.is_empty()

	_asegurar_rutas_inicializadas()

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
		_asegurar_rutas_inicializadas()

		if not FileAccess.file_exists(RUTA_GUARDADO):
			return false

		var archivo := FileAccess.open(
			RUTA_GUARDADO,
			FileAccess.READ
		)

		if archivo == null:
			return false

		datos = archivo.get_var()
		archivo.close()

	if datos == null or not datos is Dictionary:
		return false

	if bool(datos.get("partidaFinalizada", false)):
		return false

	if not datos.has("nivelActual"):
		return false

	if str(datos["nivelActual"]) == "":
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

	_asegurar_rutas_inicializadas()

	if FileAccess.file_exists(RUTA_GUARDADO):
		var ruta_absoluta := ProjectSettings.globalize_path(
			RUTA_GUARDADO
		)

		var resultado := DirAccess.remove_absolute(
			ruta_absoluta
		)

		if resultado == OK:
			print("PARTIDA BORRADA: ", RUTA_GUARDADO)
			partidaFinalizada = false
		else:
			advertencia_disco = "No se pudo borrar la partida."
			push_warning(advertencia_disco)

	else:
		print("No existe una partida para borrar.")


# =========================================================
# ESCRIBIR EN ALMACENAMIENTO PERSISTENTE
# =========================================================

func escribir_en_disco() -> bool:
	if not modo_guardado_en_disco:
		advertencia_disco = (
			"La escritura persistente está desactivada en este modo."
		)
		return false

	if not asegurar_carpeta():
		return false

	_asegurar_rutas_inicializadas()

	if FileAccess.file_exists(RUTA_GUARDADO):
		var ruta_absoluta := ProjectSettings.globalize_path(
			RUTA_GUARDADO
		)

		var resultado := DirAccess.remove_absolute(
			ruta_absoluta
		)

		if resultado != OK:
			advertencia_disco = (
				"No se pudo borrar la partida existente. "
				+ "No se escribió una nueva partida."
			)

			push_warning(advertencia_disco)
			return false

	return _escribir_datos_partida()
