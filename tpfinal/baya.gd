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


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# Configurar qué sprite se muestra.
	actualizar_sprite()

	# Conectar el área de interacción.
	interaction_area.body_entered.connect(_on_body_entered)

	# Si esta baya ya fue obtenida anteriormente,
	# directamente no debe existir.
	if ya_fue_obtenida():

		print("Baya ya obtenida: ", id_baya)

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

	if id_baya == "":
		print("ADVERTENCIA: esta baya no tiene ID")

		return false

	if tipo_baya == TipoBaya.VIDA:

		return Settings.objetosVidaObtenidos.has(id_baya)

	elif tipo_baya == TipoBaya.ENERGIA:

		return Settings.objetosEnergiaObtenidos.has(id_baya)

	return false


# =========================================================
# CONTACTO
# =========================================================

func _on_body_entered(body: Node) -> void:

	if not body.is_in_group("jugador"):
		return

	print("BAYA RECOGIDA: ", id_baya)

	recoger_baya(body)


# =========================================================
# RECOGER BAYA
# =========================================================

func recoger_baya(player: Node) -> void:

	# Evitar que se recoja dos veces.
	if ya_fue_obtenida():
		return


	# ==========================================
	# VIDA
	# ==========================================

	if tipo_baya == TipoBaya.VIDA:

		aumentar_vidaMax(player)

		if not Settings.objetosVidaObtenidos.has(id_baya):

			Settings.objetosVidaObtenidos.append(id_baya)


	# ==========================================
	# ENERGÍA
	# ==========================================

	elif tipo_baya == TipoBaya.ENERGIA:

		aumentar_energiaMax(player)

		if not Settings.objetosEnergiaObtenidos.has(id_baya):

			Settings.objetosEnergiaObtenidos.append(id_baya)


	# ==========================================
	# GUARDAR
	# ==========================================

	Save.guardar_partida()

	print("BAYA GUARDADA: ", id_baya)

	# La baya desaparece inmediatamente.
	queue_free()


# =========================================================
# AUMENTAR VIDA
# =========================================================

func aumentar_vidaMax(player: Node) -> void:

	if cantidad <= 0:
		return

	# Aumentamos la vida del Player.
	player.vida += cantidad

	# Actualizamos Settings.
	Settings.vidaActual = player.vida

	# Actualizamos la barra de vida.
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

	# Usamos el método que ya tenés en Player.
	player.aumentarEnergiaMax(cantidad)

	print(
		"ENERGÍA AUMENTADA | Máximo: ",
		player.energia_maxima,
		" | Actual: ",
		player.energia_fuego
	)
