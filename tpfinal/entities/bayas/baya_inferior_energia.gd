
# Esta baya no aumenta el máximo.
# Solo aumenta la energía actual.
extends Node2D


# =========================================================
# DATOS DE LA BAYA
# =========================================================

@export var id_baya: String = ""
@export var valor: int = 1

const PARTICULA_AMARILLA = preload("res://entities/recursos/particulas/particulas_amarillas.tscn")


# =========================================================
# REFERENCIAS
# =========================================================

@onready var interaction_area: Area2D = $InteractionArea

var recogida: bool = false


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)


# =========================================================
# CONTACTO
# =========================================================

func _on_body_entered(body: Node) -> void:
	if recogida:
		return

	if not body.is_in_group("jugador"):
		return

	recoger_baya(body)


# =========================================================
# RECOGER BAYa
# =========================================================

func recoger_baya(player: Node) -> void:
	if recogida:
		return

	recogida = true

	var posicion := global_position

	player.aumentar_energia(valor)

	var particulas = PARTICULA_AMARILLA.instantiate()

	get_tree().current_scene.add_child(particulas)

	particulas.global_position = posicion

	# Iniciar la emisión de partículas.
	particulas.restart()
	particulas.emitting = true

	# Liberar las partículas cuando termine su emisión.
	particulas.finished.connect(particulas.queue_free)

	queue_free.call_deferred()
