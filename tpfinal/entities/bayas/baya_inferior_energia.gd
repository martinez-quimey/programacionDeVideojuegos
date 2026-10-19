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
@onready var particulas: GPUParticles2D = $Particulas


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# Las partículas no deben emitirse inicialmente.
	particulas.emitting = false

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

	reproducir_particulas()

	queue_free()


# =========================================================
# REPRODUCIR PARTÍCULAS
# =========================================================

func reproducir_particulas() -> void:

	# Guardar la posición global del efecto.
	var transformacion_global := particulas.global_transform

	# Separar las partículas de la baya.
	remove_child(particulas)

	# Agregarlas a la escena actual.
	var nivel := get_tree().current_scene
	nivel.add_child(particulas)

	# Mantener la posición original.
	particulas.global_transform = transformacion_global

	# Reproducir la explosión.
	particulas.restart()
	particulas.emitting = true
