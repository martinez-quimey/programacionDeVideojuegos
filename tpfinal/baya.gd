# Baya.gd
extends Node2D


# =========================================================
# TIPO DE BAYA
# =========================================================

enum TipoBaya {
	VIDA,
	ENERGIA
}

@export var tipo_baya: TipoBaya = TipoBaya.VIDA


# =========================================================
# DATOS DE LA BAYA
# =========================================================

@export var id_baya: String = ""

@export var cantidad: int = 1


# =========================================================
# REFERENCIAS
# =========================================================

@onready var vida_sprite: Sprite2D = $Vida
@onready var energia_sprite: Sprite2D = $Energia
@onready var interaction_area: Area2D = $InteractionArea

@onready var particula_roja: GPUParticles2D = $ParticulaRoja
@onready var particula_amarilla: GPUParticles2D = $ParticulaAmarilla


# =========================================================
# OBTENER ID ÚNICO COMBINADO CON EL NIVEL
# =========================================================

func obtener_id_unico() -> String:

	var padre := get_parent()

	if padre == null:
		push_warning("La baya no tiene un nodo padre.")
		return ""

	var nombre_nivel = padre.get("nombre_nivel")

	if nombre_nivel == null or str(nombre_nivel).is_empty():
		push_warning("No se encontró nombre_nivel en el padre de la baya.")
		return ""

	if id_baya.is_empty():
		push_warning("Esta baya no tiene ID.")
		return ""

	return str(nombre_nivel) + "_" + id_baya


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	actualizar_sprite()

	# Las partículas solo se reproducen al recoger la baya.
	particula_roja.emitting = false
	particula_amarilla.emitting = false

	interaction_area.body_entered.connect(_on_body_entered)

	if ya_fue_obtenida():

		print("Baya ya obtenida: ", obtener_id_unico())

		queue_free()


# =========================================================
# SPRITE
# =========================================================

func actualizar_sprite() -> void:

	if tipo_baya == TipoBaya.VIDA:

		vida_sprite.show()
		energia_sprite.hide()

	elif tipo_baya == TipoBaya.ENERGIA:

		vida_sprite.hide()
		energia_sprite.show()


# =========================================================
# COMPROBAR SI YA FUE OBTENIDA
# =========================================================

func ya_fue_obtenida() -> bool:

	var id_unico := obtener_id_unico()

	if id_unico.is_empty():
		return false

	if tipo_baya == TipoBaya.VIDA:

		return Settings.objetosVidaObtenidos.has(id_unico)

	elif tipo_baya == TipoBaya.ENERGIA:

		return Settings.objetosEnergiaObtenidos.has(id_unico)

	return false


# =========================================================
# CONTACTO
# =========================================================

func _on_body_entered(body: Node) -> void:

	if not body.is_in_group("jugador"):
		return

	print("BAYA RECOGIDA: ", obtener_id_unico())

	recoger_baya(body)


# =========================================================
# RECOGER BAYA
# =========================================================

func recoger_baya(player: Node) -> void:

	var id_unico := obtener_id_unico()

	# Evitar recoger una baya sin identificación válida.
	if id_unico.is_empty():
		return

	# Evitar recogerla dos veces.
	if ya_fue_obtenida():
		return


	# ==========================================
	# VIDA
	# ==========================================

	if tipo_baya == TipoBaya.VIDA:

		aumentar_vidaMax(player)

		if not Settings.objetosVidaObtenidos.has(id_unico):

			Settings.objetosVidaObtenidos.append(id_unico)


	# ==========================================
	# ENERGÍA
	# ==========================================

	elif tipo_baya == TipoBaya.ENERGIA:

		aumentar_energiaMax(player)

		if not Settings.objetosEnergiaObtenidos.has(id_unico):

			Settings.objetosEnergiaObtenidos.append(id_unico)


	# ==========================================
	# GUARDAR
	# ==========================================

	Save.guardar_partida()

	print("BAYA GUARDADA: ", id_unico)

	# Reproducir las partículas antes de eliminar la baya.
	reproducir_particulas()

	queue_free()


# =========================================================
# REPRODUCIR PARTÍCULAS AL RECOGER LA BAYA
# =========================================================

func reproducir_particulas() -> void:

	var particulas: GPUParticles2D

	# Elegir las partículas según el tipo de baya.
	if tipo_baya == TipoBaya.VIDA:
		particulas = particula_roja
	else:
		particulas = particula_amarilla

	# Guardar la transformación global para conservar
	# la posición y la orientación del efecto.
	var transformacion_global := particulas.global_transform

	# Separar las partículas de la baya.
	remove_child(particulas)

	# Agregarlas a la escena actual para que sobrevivan
	# cuando la baya sea eliminada.
	var nivel := get_tree().current_scene
	nivel.add_child(particulas)

	# Restaurar su posición global.
	particulas.global_transform = transformacion_global

	# Reiniciar y reproducir el efecto.
	particulas.restart()
	particulas.emitting = true


# =========================================================
# AUMENTAR VIDA
# =========================================================

func aumentar_vidaMax(player: Node) -> void:

	if cantidad <= 0:
		return

	player.vida += cantidad

	Settings.vidaActual = player.vida

	if player.barraVida != null:

		player.barraVida.max_value = player.vida
		player.barraVida.value = player.vida

	print(
		"VIDA AUMENTADA | Máximo: ",
		player.vida
	)


# =========================================================
# AUMENTAR ENERGÍA
# =========================================================

func aumentar_energiaMax(player: Node) -> void:

	if cantidad <= 0:
		return

	player.aumentarEnergiaMax(cantidad)

	print(
		"ENERGÍA AUMENTADA | Máximo: ",
		player.energia_maxima,
		" | Actual: ",
		player.energia_fuego
	)
