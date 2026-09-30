extends Node2D 
 
signal player_died 
signal game_paused 
 
@onready var player = $Player 
@onready var estado_manual: EstadoPlayer = $Player/estadoManual 
@onready var estado_automatico: EstadoPlayer = $Player/estadoAutomatico 
 
@onready var projectile_container = $Projectiles 
@onready var start_position = $StartPosition 
 
 
func _physics_process(delta: float) -> void: 
	if Input.is_action_just_pressed("pausa") and Settings.sePuedePausar: 
		get_tree().paused = true 
		game_paused.emit() 
		Settings.sePuedePausar = false 
 
 
func _ready() -> void: 
	estado_manual.died.connect(_on_player_died) 
	estado_automatico.died.connect(_on_player_died) 
 
	if not "checkpoint" in Settings: 
		Settings.checkpoint = 0 
 
	estado_manual.start(start_position.position, projectile_container) 
 
	Settings.sePuedePausar = true 
 
 
func _on_player_died() -> void: 
	player_died.emit() 
 
 
func _on_game_paused() -> void: 
	pass # Replace with function body.
