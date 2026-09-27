# esta baya no genera aumento del maximo, solo aumenta la energia/vida actual
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

@export var valor: int = 1


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



	# ==========================================
	# VIDA
	# ==========================================

	if tipo_baya == TipoBaya.VIDA:

		player.aumentar_vida(valor)

	


	# ==========================================
	# ENERGÍA
	# ==========================================

	elif tipo_baya == TipoBaya.ENERGIA:

		player.aumentar_energia(valor)

	
	queue_free()
