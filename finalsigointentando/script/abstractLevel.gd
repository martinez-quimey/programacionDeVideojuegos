#game
extends Node2D

signal player_died
signal game_paused

@onready var player = $Player
@onready var enemy = $Turret
@onready var projectile_container = $Projectiles
@onready var start_position = $StartPosition
func _physics_process(delta: float) -> void:
		if Input.is_action_just_pressed("pausa") and Settings.sePuedePausar:
			get_tree().paused = true
			game_paused.emit()
			Settings.sePuedePausar = false

func _ready() -> void:
	player.died.connect(_on_player_died)

	player.start(start_position.position, projectile_container)
	enemy.setValues(player, projectile_container)
	Settings.sePuedePausar = true


func _on_player_died() -> void:
	player_died.emit()


func _on_game_paused() -> void:
	pass # Replace with function body.
