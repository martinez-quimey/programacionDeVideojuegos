
extends Node


const CARPETA_GUARDADO = "user://evaTwoTales"
const RUTA_GUARDADO = CARPETA_GUARDADO + "/partida.save"


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


	# ---------------------------------------------------------
	# Si ya existe un guardado, leerlo primero
	# ---------------------------------------------------------

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


	# ---------------------------------------------------------
	# Cambiar solamente el idioma
	# ---------------------------------------------------------

	datos["language"] = Settings.language


	# ---------------------------------------------------------
	# Guardar los datos nuevamente
	# ---------------------------------------------------------

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

	print(
		"Ubicación: ",
		RUTA_GUARDADO
	)


# =========================================================
# GUARDAR PARTIDA COMPLETA
# =========================================================

func guardar_partida() -> void:

	if not asegurar_carpeta():

		print("No se pudo preparar la carpeta de guardado")

		return


	# =========================================================
	# OBTENER EL NIVEL ACTUAL SI TODAVÍA NO ESTÁ GUARDADO
	# =========================================================

	if Settings.nivelActual == "":

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

				print(
					"ADVERTENCIA: no se pudo obtener el nivel actual"
				)

		else:

			print(
				"ADVERTENCIA: Main todavía no está disponible"
			)


	# =========================================================
	# DATOS A GUARDAR
	# =========================================================

	var datos = {

		"language": Settings.language,

		"vida": Settings.vidaActual,

		"energia": Settings.energiaActual,

		"nivelActual": Settings.nivelActual,

		"nivelesCompletados": Settings.nivelesCompletados,

		"objetosVidaObtenidos": Settings.objetosVidaObtenidos,

		"objetosEnergiaObtenidos": Settings.objetosEnergiaObtenidos
	}


	# =========================================================
	# GUARDAR ARCHIVO
	# =========================================================

	var archivo = FileAccess.open(
		RUTA_GUARDADO,
		FileAccess.WRITE
	)


	if archivo == null:

		print(
			"No se pudo crear el archivo de guardado"
		)

		return


	archivo.store_var(datos)

	archivo.close()


	print("PARTIDA GUARDADA")

	print(
		"Nivel guardado: ",
		Settings.nivelActual
	)

	print(
		"Ubicación: ",
		RUTA_GUARDADO
	)


# =========================================================
# CARGAR PARTIDA COMPLETA
# =========================================================

func cargar_partida() -> bool:

	if not FileAccess.file_exists(RUTA_GUARDADO):

		print("No existe una partida guardada")

		print(
			"Ruta buscada: ",
			RUTA_GUARDADO
		)

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

		print(
			"El archivo de guardado no contiene datos válidos"
		)

		return false


	# =========================================================
	# CARGAR IDIOMA
	# =========================================================

	Settings.language = datos.get(
		"language",
		"es"
	)


	# =========================================================
	# CARGAR VIDA
	# =========================================================

	Settings.vidaActual = datos.get(
		"vida",
		Settings.vidaInicial
	)


	# =========================================================
	# CARGAR ENERGÍA
	# =========================================================

	Settings.energiaActual = datos.get(
		"energia",
		Settings.energiaInicial
	)


	# =========================================================
	# CARGAR NIVEL ACTUAL
	# =========================================================

	Settings.nivelActual = datos.get(
		"nivelActual",
		""
	)


	# =========================================================
	# CARGAR NIVELES COMPLETADOS
	# =========================================================

	Settings.nivelesCompletados = datos.get(
		"nivelesCompletados",
		[]
	)


	# =========================================================
	# CARGAR OBJETOS DE VIDA
	# =========================================================

	Settings.objetosVidaObtenidos = datos.get(
		"objetosVidaObtenidos",
		[]
	)


	# =========================================================
	# CARGAR OBJETOS DE ENERGÍA
	# =========================================================

	Settings.objetosEnergiaObtenidos = datos.get(
		"objetosEnergiaObtenidos",
		[]
	)


	print("PARTIDA CARGADA")

	print(
		"Nivel guardado: ",
		Settings.nivelActual
	)


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

	Settings.vidaActual = Settings.vidaInicial

	Settings.energiaActual = Settings.energiaInicial

	Settings.nivelActual = ""

	Settings.nivelesCompletados.clear()

	Settings.objetosVidaObtenidos.clear()

	Settings.objetosEnergiaObtenidos.clear()

	guardar_partida()

	print("NUEVA PARTIDA CREADA")


# =========================================================
# COMPROBAR SI EXISTE PARTIDA
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


	# Si no existe un nivel actual, solamente
	# hay datos de configuración como el idioma.
	if not datos.has("nivelActual"):
		return false


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

		else:

			print(
				"No se pudo borrar la partida"
			)

	else:

		print(
			"No existe una partida para borrar"
		)
