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
# CONFIGURACIÓN DE CONTROLES
# =========================================================

enum ModoControles {
	MODO_A,
	MODO_B
}

# Siempre se inicia en el modo A por defecto.
# Save puede restaurar la elección guardada cuando existe.
var modo_controles: ModoControles = ModoControles.MODO_A

# 0 = tecla direccional del modo actual (Arriba en A, W en B).
# 1 = E.
var opcion_interaccion: int = 0

# Los nombres deben coincidir con las acciones de Proyecto -> Mapa de entrada.
# Solo se modifican los eventos de teclado listados acá; los eventos de
# joystick, cruceta, palancas y otros dispositivos permanecen intactos.
const PERFILES_CONTROLES: Dictionary = {
	"izquierda": {
		ModoControles.MODO_A: [KEY_LEFT],
		ModoControles.MODO_B: [KEY_A]
	},
	"derecha": {
		ModoControles.MODO_A: [KEY_RIGHT],
		ModoControles.MODO_B: [KEY_D]
	},
	"salto": {
		ModoControles.MODO_A: [KEY_SPACE],
		ModoControles.MODO_B: [KEY_N]
	},
	"saltoFuego": {
		ModoControles.MODO_A: [KEY_Z],
		ModoControles.MODO_B: [KEY_J]
	},
	"avanzarDialogo": {
		ModoControles.MODO_A: [KEY_Z, KEY_SPACE],
		ModoControles.MODO_B: [KEY_J, KEY_N]
	},
	"tornado": {
		ModoControles.MODO_A: [KEY_X],
		ModoControles.MODO_B: [KEY_K]
	},
	"turboFuego": {
		ModoControles.MODO_A: [KEY_C],
		ModoControles.MODO_B: [KEY_L]
	},
	# La misma tecla puede activar abajo e interactMadriguera.
	"interactMadriguera": {
		ModoControles.MODO_A: [KEY_DOWN],
		ModoControles.MODO_B: [KEY_S]
	}
}

# Nombre exacto de la acción del Mapa de entrada que se usa para interactuar.
const ACCION_INTERACCION: String = "interactuar"


func _ready() -> void:
	aplicar_controles()


func cambiar_modo_controles(nuevo_modo: int) -> void:
	# Normalizar el valor recibido evita errores de tipado con enums
	# que vienen desde otros Autoloads o expresiones condicionales.
	if nuevo_modo == int(ModoControles.MODO_B):
		modo_controles = ModoControles.MODO_B
	else:
		modo_controles = ModoControles.MODO_A
	aplicar_controles()


func cambiar_opcion_interaccion(nueva_opcion: int) -> void:
	opcion_interaccion = clampi(nueva_opcion, 0, 1)
	_aplicar_tecla_interaccion()


func aplicar_controles() -> void:
	# Asegurar que ambas acciones especiales existan.
	# Si ya existen, no se borran ni se recrean, así que sus eventos de joystick
	# permanecen intactos.
	if not InputMap.has_action("interactMadriguera"):
		InputMap.add_action("interactMadriguera")

	if not InputMap.has_action(ACCION_INTERACCION):
		InputMap.add_action(ACCION_INTERACCION)

	for accion: String in PERFILES_CONTROLES:
		if not InputMap.has_action(accion):
			push_warning("No existe la acción de InputMap: " + accion)
			continue

		var perfil: Dictionary = PERFILES_CONTROLES[accion]
		var teclas_gestionadas: Array = []
		teclas_gestionadas.append_array(perfil[ModoControles.MODO_A])
		teclas_gestionadas.append_array(perfil[ModoControles.MODO_B])

		# Copia de los eventos para poder eliminar los que correspondan.
		var eventos_actuales: Array[InputEvent] = InputMap.action_get_events(accion)
		for evento: InputEvent in eventos_actuales:
			if not evento is InputEventKey:
				continue

			var evento_teclado := evento as InputEventKey
			var coincide_fisica: bool = teclas_gestionadas.has(
				evento_teclado.physical_keycode
			)
			var coincide_logica: bool = teclas_gestionadas.has(
				evento_teclado.keycode
			)

			if coincide_fisica or coincide_logica:
				InputMap.action_erase_event(accion, evento)

		# Agregar únicamente las teclas del modo activo.
		for tecla: Key in perfil[modo_controles]:
			var nuevo_evento := InputEventKey.new()
			nuevo_evento.physical_keycode = tecla
			InputMap.action_add_event(accion, nuevo_evento)

	_aplicar_tecla_interaccion()


func _aplicar_tecla_interaccion() -> void:
	# La acción exacta usada por el juego es "interactuar".
	# Si ya existía en el Mapa de entrada, se mantienen todos los eventos
	# que no sean las teclas administradas por este selector.
	if not InputMap.has_action(ACCION_INTERACCION):
		InputMap.add_action(ACCION_INTERACCION)

	# Solo administramos Arriba, W y E. No se eliminan eventos de joystick,
	# cruceta, palancas ni otras teclas ajenas a este selector.
	var teclas_gestionadas: Array[Key] = [KEY_UP, KEY_W, KEY_E]
	var eventos_interaccion: Array[InputEvent] = InputMap.action_get_events(
		ACCION_INTERACCION
	)

	for evento: InputEvent in eventos_interaccion:
		if not evento is InputEventKey:
			continue

		var evento_teclado: InputEventKey = evento as InputEventKey
		var coincide_tecla_fisica: bool = teclas_gestionadas.has(
			evento_teclado.physical_keycode
		)
		var coincide_tecla_logica: bool = teclas_gestionadas.has(
			evento_teclado.keycode
		)

		if coincide_tecla_fisica or coincide_tecla_logica:
			InputMap.action_erase_event(ACCION_INTERACCION, evento)

	# Opción 0: Arriba en el modo A o W en el modo B.
	# Opción 1: E en ambos modos.
	var tecla_elegida: Key = KEY_E
	if opcion_interaccion == 0:
		if modo_controles == ModoControles.MODO_A:
			tecla_elegida = KEY_UP
		else:
			tecla_elegida = KEY_W

	var nuevo_evento: InputEventKey = InputEventKey.new()
	nuevo_evento.physical_keycode = tecla_elegida
	InputMap.action_add_event(ACCION_INTERACCION, nuevo_evento)

# =========================================================
# REGISTRO CENTRAL DE NIVELES
# =========================================================

# id: identificador único del nivel.
# ruta: archivo .tscn del nivel.
# nombre_es: nombre mostrado en español.
# nombre_en: nombre mostrado en inglés.
# completado: progreso REAL de la partida.
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
	if estan_todos_los_niveles_disponibles():
		return registro_niveles.duplicate(true)

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


func esta_nivel_disponible(id_nivel: int) -> bool:
	if estan_todos_los_niveles_disponibles():
		return not obtener_nivel_por_id(id_nivel).is_empty()

	for nivel: Dictionary in obtener_niveles_disponibles():
		if int(nivel.get("id", -1)) == id_nivel:
			return true
	return false


# =========================================================
# REGISTRO DE NIVELES
# =========================================================

func obtener_nivel_por_id(id_nivel: int) -> Dictionary:
	for nivel: Dictionary in registro_niveles:
		if int(nivel["id"]) == id_nivel:
			return nivel
	return {}


func obtener_nivel_por_ruta(ruta: String) -> Dictionary:
	for nivel: Dictionary in registro_niveles:
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
	for nivel: Dictionary in registro_niveles:
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
	for nivel: Dictionary in registro_niveles:
		if bool(nivel.get("completado", false)):
			ids.append(int(nivel["id"]))
	return ids


func establecer_niveles_completados(ids: Array) -> void:
	for nivel: Dictionary in registro_niveles:
		nivel["completado"] = ids.has(int(nivel["id"]))


func reiniciar_niveles_completados() -> void:
	for nivel: Dictionary in registro_niveles:
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
