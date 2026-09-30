# Esta baya no aumenta el máximo.
# Solo aumenta la energía actual.
extends Node2D


# =========================================================
# DATOS DE LA BAYA
# =========================================================

@export var id_baya: String = ""

@export var valor: int = 1


# =========================================================
# REFERENCIAS
# =========================================================

@onready var interaction_area: Area2D = $InteractionArea


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# Conectar el área de interacción.
	interaction_area.body_entered.connect(_on_body_entered)


# =========================================================
# CONTACTO
# =========================================================

func _on_body_entered(body: Node) -> void:

	if not body.is_in_group("jugador"):
		return

	print("BAYA DE ENERGÍA RECOGIDA: ", id_baya)

	recoger_baya(body)


# =========================================================
# RECOGER BAYA
# =========================================================

func recoger_baya(player: Node) -> void:

	player.aumentar_energia(valor)

	queue_free()
