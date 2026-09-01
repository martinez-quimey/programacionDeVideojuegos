#main
extends Node2D

@export var GAME_SCENE: PackedScene

@onready var game_container: Node2D = $GameContainer
@onready var hud: CanvasLayer = $HUD

var game: Node2D = null


func _ready() -> void:
	hud.start_game.connect(new_game)


func new_game() -> void:
	if game != null:
		return

	# Ocultar Start y cualquier mensaje
	hud.hide_game_over()

	# Crear nueva partida
	game = GAME_SCENE.instantiate()
	game_container.add_child(game)

	# Conectar muerte
	game.player_died.connect(_on_player_died)


func _on_player_died() -> void:
	if game != null:
		game.queue_free()
		game = null

	# Mostrar Game Over y Start
	hud.show_game_over()
