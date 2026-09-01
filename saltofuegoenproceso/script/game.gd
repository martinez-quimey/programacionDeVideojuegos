#game
extends Node2D

signal player_died

@onready var player = $Player
@onready var enemy = $Turret
@onready var projectile_container = $Projectiles
@onready var start_position = $StartPosition


func _ready() -> void:
	player.died.connect(_on_player_died)

	player.start(start_position.position, projectile_container)
	enemy.setValues(player, projectile_container)


func _on_player_died() -> void:
	player_died.emit()
