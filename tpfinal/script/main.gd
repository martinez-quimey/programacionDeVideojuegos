# Main.gd

extends Node2D


@onready var game_container: Node2D = $GameContainer
@onready var hud: CanvasLayer = $HUD


# =========================================================
# NIVEL INICIAL DE UNA PARTIDA NUEVA
# =========================================================

@export var level1: PackedScene


# =========================================================
# NIVEL ACTUALMENTE CARGADO
# =========================================================

var game: Node2D = null

# Guardamos la ruta del nivel aunque el nodo game sea eliminado.
var ruta_nivel_actual: String = ""


# =========================================================
# INICIALIZACIÓN DEL IDIOMA
# =========================================================

func _enter_tree() -> void:

	var idioma_guardado = Save.obtener_idioma_guardado()

	if idioma_guardado == null:

		Settings.language = "es"

	else:

		Settings.language = idioma_guardado


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:

	Settings.setearMain(self)

	hud.start_game.connect(new_game)
	hud.retry_game.connect(retry_game)
	hud.main_menu.connect(_on_main_menu)
	hud.continue_game.connect(continue_game)


# =========================================================
# OBTENER RUTA DEL NIVEL ACTUAL
# =========================================================

func obtener_ruta_nivel_actual() -> String:

	if ruta_nivel_actual == "":

		print("ERROR: no hay ninguna ruta de nivel guardada")

		return ""


	print("Ruta del nivel actual: ", ruta_nivel_actual)

	return ruta_nivel_actual


# =========================================================
# CONTINUAR PARTIDA
# =========================================================

func continue_game() -> void:

	print("====================================")
	print("CONTINUANDO PARTIDA")
	print("====================================")

	print("Nivel guardado: ", Settings.nivelActual)

	if Settings.nivelActual == "":

		print("ERROR 1: nivelActual está vacío")

		return


	print("Comprobando existencia del recurso...")

	if not ResourceLoader.exists(Settings.nivelActual):

		print("ERROR 2: el recurso NO existe")
		print("Ruta buscada: ", Settings.nivelActual)

		return


	print("OK: el recurso existe")

	print("Intentando hacer load()...")

	var escena_nivel = load(Settings.nivelActual)

	if escena_nivel == null:

		print("ERROR 3: load() devolvió null")
		print("Godot no pudo cargar el recurso")

		return


	print("OK: load() funcionó")
	print("Recurso cargado: ", escena_nivel)

	print("Comprobando tipo de recurso...")

	if not escena_nivel is PackedScene:

		print("ERROR 4: el recurso NO es una PackedScene")
		print("Tipo obtenido: ", escena_nivel.get_class())

		return


	print("OK: el recurso es una PackedScene")

	print("Comprobando GameContainer...")

	if game_container == null:

		print("ERROR 5: GameContainer es null")

		return


	print("OK: GameContainer existe")
	print("GameContainer: ", game_container)

	print("Intentando instantiate()...")

	var nuevo_game = escena_nivel.instantiate()

	if nuevo_game == null:

		print("ERROR 6: instantiate() devolvió null")

		return


	print("OK: instantiate() funcionó")
	print("Instancia creada: ", nuevo_game)

	if not nuevo_game is Node2D:

		print("ERROR 7: el nivel no es Node2D")
		print("Tipo obtenido: ", nuevo_game.get_class())

		nuevo_game.queue_free()

		return


	print("OK: el nivel es Node2D")


	if game != null:

		print("Eliminando nivel anterior...")

		game.queue_free()

		game = null


	print("Asignando nuevo nivel a game...")

	game = nuevo_game

	# Guardamos la ruta del nivel.
	ruta_nivel_actual = Settings.nivelActual

	print("Ruta guardada para reintentar: ", ruta_nivel_actual)


	print("Agregando nivel al GameContainer...")

	game_container.add_child(game)

	print("OK: nivel agregado al GameContainer")

	print("Conectando señales...")

	if game.has_signal("player_died"):

		game.player_died.connect(_on_player_died)

		print("OK: player_died conectado")

	else:

		print("ERROR 8: el nivel no tiene señal player_died")


	if game.has_signal("game_paused"):

		game.game_paused.connect(_on_game_paused)

		print("OK: game_paused conectado")

	else:

		print("ERROR 9: el nivel no tiene señal game_paused")


	print("====================================")
	print("NIVEL CARGADO CORRECTAMENTE")
	print("====================================")


# =========================================================
# NUEVA PARTIDA
# =========================================================

func new_game() -> void:

	print("====================================")
	print("NUEVA PARTIDA")
	print("====================================")

	if level1 == null:

		print("ERROR: level1 no está asignado en Main")

		return


	load_level(level1)


# =========================================================
# REINTENTAR NIVEL
# =========================================================

func retry_game() -> void:

	print("====================================")
	print("REINTENTAR NIVEL")
	print("====================================")


	var ruta_nivel = obtener_ruta_nivel_actual()

	if ruta_nivel == "":

		print("No se puede reintentar: ruta inválida")

		return


	print("Cargando nuevamente: ", ruta_nivel)


	var escena_nivel = load(ruta_nivel)

	if escena_nivel == null:

		print("No se pudo cargar el nivel para reintentar")

		return


	if not escena_nivel is PackedScene:

		print("El recurso del nivel no es PackedScene")

		return


	load_level(escena_nivel)


# =========================================================
# CARGAR UN NIVEL
# =========================================================

func load_level(level_scene: PackedScene) -> void:

	print("====================================")
	print("CARGANDO NIVEL")
	print("====================================")


	if level_scene == null:

		print("ERROR: level_scene es null")

		return


	print("Nivel recibido: ", level_scene.resource_path)


	# Guardamos la ruta ANTES de crear/eliminar nodos.
	ruta_nivel_actual = level_scene.resource_path

	print("Ruta guardada para reintentar: ", ruta_nivel_actual)


	if game != null:

		print("Eliminando nivel anterior...")

		game.queue_free()

		game = null


	print("Instanciando nivel...")

	game = level_scene.instantiate()

	if game == null:

		print("ERROR: no se pudo instanciar el nivel")

		return


	game_container.add_child(game)

	print("Nivel agregado al GameContainer")


	if game.has_signal("player_died"):

		game.player_died.connect(_on_player_died)

		print("player_died conectado")


	if game.has_signal("game_paused"):

		game.game_paused.connect(_on_game_paused)

		print("game_paused conectado")


	print("Nivel cargado correctamente")
	print("Ruta real: ", game.scene_file_path)


# =========================================================
# PLAYER MUERE
# =========================================================

func _on_player_died() -> void:

	print("====================================")
	print("MAIN: PLAYER MURIÓ")
	print("MAIN: ruta guardada: ", ruta_nivel_actual)
	print("MAIN: mostrando GAME OVER")
	print("====================================")


	if game != null:

		game.queue_free()

		game = null


	hud.show_game_over()


# =========================================================
# PAUSA
# =========================================================

func _on_game_paused() -> void:

	hud.show_pause_menu()


# =========================================================
# VOLVER AL MENÚ
# =========================================================

func _on_main_menu() -> void:

	if game != null:

		game.queue_free()

		game = null


	hud.show_main_menu()
