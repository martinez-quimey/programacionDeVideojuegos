extends Node

const RUTA_GUARDADO = "user://partida.save"


func guardar_partida() -> void:

	var datos = {
		"language": Settings.language,

		"vida": Settings.vidaActual,
		"energia": Settings.energiaActual,

		"nivelActual": Settings.nivelActual,

		"nivelesCompletados": Settings.nivelesCompletados,

		"objetosVidaObtenidos": Settings.objetosVidaObtenidos,

		"objetosEnergiaObtenidos": Settings.objetosEnergiaObtenidos
	}

	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)

	if archivo:
		archivo.store_var(datos)
		archivo.close()

		print("PARTIDA GUARDADA")


func cargar_partida() -> bool:

	if not FileAccess.file_exists(RUTA_GUARDADO):
		print("No existe una partida guardada")
		return false

	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)

	if archivo == null:
		print("No se pudo abrir la partida")
		return false

	var datos = archivo.get_var()
	archivo.close()

	Settings.language = datos.get("language", "es")

	Settings.vidaActual = datos.get(
		"vida",
		Settings.vidaInicial
	)

	Settings.energiaActual = datos.get(
		"energia",
		Settings.energiaInicial
	)

	Settings.nivelActual = datos.get(
		"nivelActual",
		""
	)

	Settings.nivelesCompletados = datos.get(
		"nivelesCompletados",
		[]
	)

	Settings.objetosVidaObtenidos = datos.get(
		"objetosVidaObtenidos",
		[]
	)

	Settings.objetosEnergiaObtenidos = datos.get(
		"objetosEnergiaObtenidos",
		[]
	)

	print("PARTIDA CARGADA")

	return true


func iniciar_nueva_partida() -> void:

	Settings.language = "es"

	Settings.vidaActual = Settings.vidaInicial
	Settings.energiaActual = Settings.energiaInicial

	Settings.nivelActual = ""

	Settings.nivelesCompletados.clear()

	Settings.objetosVidaObtenidos.clear()

	Settings.objetosEnergiaObtenidos.clear()

	guardar_partida()

	print("NUEVA PARTIDA CREADA")


func existe_partida() -> bool:

	return FileAccess.file_exists(RUTA_GUARDADO)


func borrar_partida() -> void:

	if FileAccess.file_exists(RUTA_GUARDADO):

		DirAccess.remove_absolute(RUTA_GUARDADO)

		print("PARTIDA BORRADA")
