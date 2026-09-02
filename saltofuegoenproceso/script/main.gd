extends Node2D

@onready var game_container: Node2D = $GameContainer
@onready var hud: CanvasLayer = $HUD

@export var level1: PackedScene

var game: Node2D = null


func _ready() -> void:
	hud.start_game.connect(new_game)
	hud.retry_game.connect(retry_game)
	hud.main_menu.connect(_on_main_menu)


func new_game() -> void:
	load_level(level1)


func retry_game() -> void:
	load_level(level1)


func load_level(level_scene: PackedScene) -> void:
	if game != null:
		game.queue_free()
		game = null

	game = level_scene.instantiate()
	game_container.add_child(game)

	game.player_died.connect(_on_player_died)


func _on_player_died() -> void:
	if game != null:
		game.queue_free()
		game = null

	hud.show_game_over()


func _on_main_menu() -> void:
	if game != null:
		game.queue_free()
		game = null

	hud.show_main_menu()
