
# Esta baya no aumenta el máximo.
# Solo aumenta la vida actual.
extends Node2D


# =========================================================
# DATOS DE LA BAYA
# =========================================================

@export var id_baya: String = ""
@export var valor: int = 1

const PARTICULA_ROJA = preload("res://entities/recursos/particulas/particulas_rojas.tscn")


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

	print("BAYA DE VIDA RECOGIDA: ", id_baya)

	recoger_baya(body)


# =========================================================
# RECOGER BAYA
# =========================================================

func recoger_baya(player: Node) -> void:

	recogida = true

	var posicion := global_position

	player.aumentar_vida(valor)

	var particulas = PARTICULA_ROJA.instantiate()

	get_tree().current_scene.add_child(particulas)

	particulas.global_position = posicion

	# Iniciar la emisión de partículas.
	particulas.restart()
	particulas.emitting = true

	# Liberar las partículas cuando termine su emisión.
	particulas.finished.connect(particulas.queue_free)

	queue_free()
