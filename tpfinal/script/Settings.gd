
extends Node

# =========================================================
# MODOS DE ACCESO A LOS NIVELES
# =========================================================

enum ModoAccesoNiveles {
	NORMAL,
	ALL_LEVELS
}

# Se configura desde el Inspector.
# NORMAL: progresión habitual.
# ALL_LEVELS: todos los niveles están disponibles para probarlos.
# Este ajuste NO se guarda dentro de la partida.
var modo_acceso_niveles: ModoAccesoNiveles = ModoAccesoNiveles.NORMAL


# =========================================================
# VARIABLES GENERALES
# =========================================================

var checkpoints_por_nivel: Dictionary = {}

var language: String = "es"
var sePuedePausar: bool = false
var main = null

const vidaInicial: int = 5
var vidaActual: int = 5

const energiaInicial: int = 5
var energiaActual: int = 5

var checkpoint: int = 0


# =========================================================
# REGISTRO CENTRAL DE NIVELES
# =========================================================

# id: identificador único del nivel.
# ruta: archivo .tscn del nivel.
# nombre_es: nombre mostrado en español.
# nombre_en: nombre mostrado en inglés.
# completado: progreso REAL de la partida.
#
# ALL_LEVELS no modifica el campo "completado".

var registro_niveles: Array[Dictionary] = [
	{
		"id": 1,
		"ruta": "res://entities/levels/level_1/El bosque espiritual.tscn",
		"nombre_es": "El bosque espiritual",
		"nombre_en": "The Spirit Forest",
		"completado": false
	}
]


# =========================================================
# PROGRESO DE PARTIDA
# =========================================================

# Ruta de la escena actual. No es el ID del nivel.
var nivelActual: String = ""

var objetosVidaObtenidos: Array = []
var objetosEnergiaObtenidos: Array = []


# =========================================================
# CONSULTAR EL MODO DE ACCESO
# =========================================================

func estan_todos_los_niveles_disponibles() -> bool:
	return modo_acceso_niveles == ModoAccesoNiveles.ALL_LEVELS


# =========================================================
# OBTENER LOS NIVELES DISPONIBLES
# =========================================================

func obtener_niveles_disponibles() -> Array[Dictionary]:
	# Modo de desarrollo: devolver todos los niveles registrados.
	# Se devuelve una copia para que quien consulte la lista
	# no modifique accidentalmente el registro original.
	if estan_todos_los_niveles_disponibles():
		return registro_niveles.duplicate(true)

	# Modo normal:
	# el primer nivel está disponible desde el comienzo.
	# Cada nivel posterior se desbloquea al completar el anterior,
	# respetando el orden en que aparecen en registro_niveles.
	var disponibles: Array[Dictionary] = []

	for i in range(registro_niveles.size()):
		var nivel: Dictionary = registro_niveles[i]

		if i == 0:
			disponibles.append(nivel)
			continue

		var nivel_anterior: Dictionary = registro_niveles[i - 1]

		if bool(nivel_anterior.get("completado", false)):
			disponibles.append(nivel)

	return disponibles


# =========================================================
# COMPROBAR SI UN NIVEL ESTÁ DISPONIBLE
# =========================================================

func esta_nivel_disponible(id_nivel: int) -> bool:
	# En ALL_LEVELS, todos los niveles registrados están disponibles,
	# independientemente del progreso guardado.
	if estan_todos_los_niveles_disponibles():
		return not obtener_nivel_por_id(id_nivel).is_empty()

	# En NORMAL, respetar la progresión.
	for nivel in obtener_niveles_disponibles():
		if int(nivel.get("id", -1)) == id_nivel:
			return true

	return false


# =========================================================
# REGISTRO DE NIVELES
# =========================================================

func obtener_nivel_por_id(id_nivel: int) -> Dictionary:
	for nivel in registro_niveles:
		if int(nivel["id"]) == id_nivel:
			return nivel

	return {}


func obtener_nivel_por_ruta(ruta: String) -> Dictionary:
	for nivel in registro_niveles:
		if str(nivel["ruta"]) == ruta:
			return nivel

	return {}


func obtener_nombre_nivel(id_nivel: int) -> String:
	var nivel := obtener_nivel_por_id(id_nivel)

	if nivel.is_empty():
		return "Nivel " + str(id_nivel)

	if language == "en":
		return str(nivel["nombre_en"])

	return str(nivel["nombre_es"])


# =========================================================
# MARCAR UN NIVEL COMO COMPLETADO
# =========================================================

func marcar_nivel_completado(id_nivel: int) -> void:
	for nivel in registro_niveles:
		if int(nivel["id"]) == id_nivel:
			nivel["completado"] = true
			print("NIVEL COMPLETADO: ID ", id_nivel)
			return

	push_warning("No existe el nivel con ID " + str(id_nivel))


# =========================================================
# OBTENER EL PROGRESO REAL
# =========================================================

func obtener_ids_niveles_completados() -> Array:
	var ids: Array = []

	for nivel in registro_niveles:
		if bool(nivel.get("completado", false)):
			ids.append(int(nivel["id"]))

	return ids


func establecer_niveles_completados(ids: Array) -> void:
	for nivel in registro_niveles:
		nivel["completado"] = ids.has(int(nivel["id"]))


func reiniciar_niveles_completados() -> void:
	for nivel in registro_niveles:
		nivel["completado"] = false


# =========================================================
# MAIN
# =========================================================

func setearMain(Main) -> void:
	main = Main


func getMain():
	return main


# =========================================================
# VIDA Y ENERGÍA
# =========================================================

func getEnergiaActual() -> int:
	return energiaActual


func getVidaActual() -> int:
	return vidaActual
