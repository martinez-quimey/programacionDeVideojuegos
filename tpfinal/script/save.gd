
extends Node


const CARPETA_GUARDADO = "user://evaTwoTales"
const RUTA_GUARDADO = CARPETA_GUARDADO + "/partida.save"

# Indica si se terminó la beta.
var partidaFinalizada: bool = false


# =========================================================
# ASEGURAR CARPETA
# =========================================================

func asegurar_carpeta() -> bool:

	var directorio = DirAccess.open("user://")

	if directorio == null:
		print("No se pudo acceder a user://")
		return false

	if not directorio.dir_exists("evaTwoTales"):

		var resultado = directorio.make_dir("evaTwoTales")

		if resultado != OK:
			print("No se pudo crear la carpeta evaTwoTales")
			return false

		print("CARPETA evaTwoTales CREADA")

	return true


# =========================================================
# GUARDAR SOLAMENTE EL IDIOMA
# =========================================================

func guardar_idioma() -> void:

	if not asegurar_carpeta():
		print("No se pudo preparar la carpeta de guardado")
		return

	var datos = {}

	if FileAccess.file_exists(RUTA_GUARDADO):

		var archivo_lectura = FileAccess.open(
			RUTA_GUARDADO,
			FileAccess.READ
		)

		if archivo_lectura != null:

			var datos_existentes = archivo_lectura.get_var()
			archivo_lectura.close()

			if datos_existentes is Dictionary:
				datos = datos_existentes

	datos["language"] = Settings.language

	var archivo = FileAccess.open(
		RUTA_GUARDADO,
		FileAccess.WRITE
	)

	if archivo == null:
		print("No se pudo crear el archivo de guardado")
		return

	archivo.store_var(datos)
	archivo.close()

	print("IDIOMA GUARDADO: ", Settings.language)
	print("Ubicación: ", RUTA_GUARDADO)


# =========================================================
# GUARDAR PARTIDA COMPLETA
# =========================================================

func guardar_partida() -> void:

	if not asegurar_carpeta():
		print("No se pudo preparar la carpeta de guardado")
		return

	# No recuperar automáticamente un nivel actual
	# cuando la partida ya terminó.
	if Settings.nivelActual == "" and not partidaFinalizada:

		var main = Settings.getMain()

		if main != null:

			var ruta_nivel = main.obtener_ruta_nivel_actual()

			if ruta_nivel != "":
				Settings.nivelActual = ruta_nivel

				print(
					"NIVEL ACTUAL GUARDADO AUTOMÁTICAMENTE: ",
					Settings.nivelActual
				)
			else:
				print("ADVERTENCIA: no se pudo obtener el nivel actual")
		else:
			print("ADVERTENCIA: Main todavía no está disponible")

	# Datos que se guardan.
	var datos = {
		"language": Settings.language,
		"vida": Settings.vidaActual,
		"energia": Settings.energiaActual,
		"nivelActual": Settings.nivelActual,
		"nivelesCompletados": Settings.nivelesCompletados,
		"objetosVidaObtenidos": Settings.objetosVidaObtenidos,
		"objetosEnergiaObtenidos": Settings.objetosEnergiaObtenidos,
		"partidaFinalizada": partidaFinalizada
	}

	var archivo = FileAccess.open(
		RUTA_GUARDADO,
		FileAccess.WRITE
	)

	if archivo == null:
		print("No se pudo crear el archivo de guardado")
		return

	archivo.store_var(datos)
	archivo.close()

	print("PARTIDA GUARDADA")
	print("Nivel guardado: ", Settings.nivelActual)
	print("Partida finalizada: ", partidaFinalizada)
	print("Ubicación: ", RUTA_GUARDADO)


# =========================================================
# CARGAR PARTIDA COMPLETA
# =========================================================

func cargar_partida() -> bool:

	if not FileAccess.file_exists(RUTA_GUARDADO):
		print("No existe una partida guardada")
		print("Ruta buscada: ", RUTA_GUARDADO)
		return false

	var archivo = FileAccess.open(
		RUTA_GUARDADO,
		FileAccess.READ
	)

	if archivo == null:
		print("No se pudo abrir la partida")
		return false

	var datos = archivo.get_var()
	archivo.close()

	if datos == null or not datos is Dictionary:
		print("El archivo de guardado no contiene datos válidos")
		return false

	# Cargar el estado de finalización.
	partidaFinalizada = datos.get(
		"partidaFinalizada",
		false
	)

	# Cargar idioma.
	Settings.language = datos.get(
		"language",
		"es"
	)

	# Cargar vida.
	Settings.vidaActual = datos.get(
		"vida",
		Settings.vidaInicial
	)

	# Cargar energía.
	Settings.energiaActual = datos.get(
		"energia",
		Settings.energiaInicial
	)

	# Cargar nivel actual.
	Settings.nivelActual = datos.get(
		"nivelActual",
		""
	)

	# Cargar niveles completados.
	Settings.nivelesCompletados = datos.get(
		"nivelesCompletados",
		[]
	)

	# Cargar objetos de vida.
	Settings.objetosVidaObtenidos = datos.get(
		"objetosVidaObtenidos",
		[]
	)

	# Cargar objetos de energía.
	Settings.objetosEnergiaObtenidos = datos.get(
		"objetosEnergiaObtenidos",
		[]
	)

	print("PARTIDA CARGADA")
	print("Nivel guardado: ", Settings.nivelActual)
	print("Partida finalizada: ", partidaFinalizada)

	return true


# =========================================================
# OBTENER IDIOMA GUARDADO
# =========================================================

func obtener_idioma_guardado():

	if not FileAccess.file_exists(RUTA_GUARDADO):
		return null

	var archivo = FileAccess.open(
		RUTA_GUARDADO,
		FileAccess.READ
	)

	if archivo == null:
		return null

	var datos = archivo.get_var()
	archivo.close()

	if datos == null or not datos is Dictionary:
		return null

	if not datos.has("language"):
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

	Settings.nivelesCompletados.clear()
	Settings.objetosVidaObtenidos.clear()
	Settings.objetosEnergiaObtenidos.clear()

	guardar_partida()

	print("NUEVA PARTIDA CREADA")


# =========================================================
# COMPROBAR SI EXISTE UNA PARTIDA CONTINUABLE
# =========================================================

func existe_partida() -> bool:

	if not FileAccess.file_exists(RUTA_GUARDADO):
		return false

	var archivo = FileAccess.open(
		RUTA_GUARDADO,
		FileAccess.READ
	)

	if archivo == null:
		return false

	var datos = archivo.get_var()
	archivo.close()

	if datos == null or not datos is Dictionary:
		return false

	# Una partida finalizada no se puede continuar.
	if datos.get("partidaFinalizada", false):
		return false

	# Debe existir el dato del nivel actual.
	if not datos.has("nivelActual"):
		return false

	# Un nivel vacío significa que no hay partida continuable.
	if datos["nivelActual"] == "":
		return false

	return true


# =========================================================
# BORRAR PARTIDA
# =========================================================

func borrar_partida() -> void:

	if FileAccess.file_exists(RUTA_GUARDADO):

		var resultado = DirAccess.remove_absolute(
			RUTA_GUARDADO
		)

		if resultado == OK:
			print("PARTIDA BORRADA")
			partidaFinalizada = false
		else:
			print("No se pudo borrar la partida")

	else:
		print("No existe una partida para borrar")
