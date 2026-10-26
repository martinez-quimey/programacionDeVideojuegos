
extends Node2D
class_name Baya

# =========================================================
# TIPO DE BAYA
# =========================================================

enum TipoBaya {
	VIDA,
	ENERGIA
}

@export var tipo_baya: TipoBaya = TipoBaya.VIDA
@export var id_baya: String = ""
@export var cantidad: int = 1

# Permite recordar si la baya ya estaba recogida al entrar al árbol.
var ya_estaba_obtenida: bool = false


# =========================================================
# REFERENCIAS
# =========================================================

@onready var vida_sprite: Sprite2D = $Vida
@onready var energia_sprite: Sprite2D = $Energia
@onready var interaction_area: Area2D = $InteractionArea

@onready var particula_roja: GPUParticles2D = $ParticulaRoja
@onready var particula_amarilla: GPUParticles2D = $ParticulaAmarilla


# =========================================================
# OBTENER EL ID DEL NIVEL
# =========================================================

func obtener_id_nivel() -> int:
	var nodo: Node = get_parent()

	print("\n[BAYA] Buscando numero_nivel para: ", get_path())

	while nodo != null:
		print(
			"[BAYA] Revisando nodo: ",
			nodo.name,
			" | Tipo: ",
			nodo.get_class()
		)

		for propiedad in nodo.get_property_list():
			if propiedad["name"] == "numero_nivel":
				var numero: int = int(nodo.get("numero_nivel"))

				print(
					"[BAYA] numero_nivel encontrado: ",
					numero,
					" | Nodo: ",
					nodo.get_path()
				)

				return numero

		nodo = nodo.get_parent()

	push_warning(
		"[BAYA] No se encontró numero_nivel en los padres: "
		+ str(get_path())
	)

	print("[BAYA] ERROR: se devuelve ID de nivel 0.")
	return 0


# =========================================================
# OBTENER ID ÚNICO
# =========================================================

func obtener_id_unico() -> String:
	var numero_nivel: int = obtener_id_nivel()

	if numero_nivel <= 0:
		print(
			"[BAYA] ERROR: numero_nivel inválido: ",
			numero_nivel,
			" | id_baya: ",
			id_baya
		)
		return ""

	if id_baya.strip_edges().is_empty():
		push_warning(
			"[BAYA] La baya del nivel "
			+ str(numero_nivel)
			+ " no tiene id_baya configurado."
		)
		return ""

	var id_unico: String = str(numero_nivel) + "_" + id_baya.strip_edges()

	print(
		"[BAYA] ID generado: ",
		id_unico,
		" | Nivel: ",
		numero_nivel,
		" | ID original: '",
		id_baya,
		"'"
	)

	return id_unico


# =========================================================
# COMPROBACIÓN TEMPRANA
# =========================================================

func _enter_tree() -> void:
	print(
		"\n[BAYA] _enter_tree | Ruta: ",
		get_path(),
		" | Tipo: ",
		TipoBaya.keys()[tipo_baya]
	)

	var obtenida: bool = ya_fue_obtenida()

	print(
		"[BAYA] Comprobación inicial | ID: ",
		id_baya,
		" | Obtenida: ",
		obtenida
	)

	if obtenida:
		ya_estaba_obtenida = true
		visible = false
		set_process(false)
		set_physics_process(false)

		print(
			"[BAYA] Eliminada en _enter_tree porque ya estaba recogida: ",
			id_baya
		)

		queue_free()


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	print(
		"[BAYA] _ready | ID: ",
		id_baya,
		" | Ya estaba obtenida: ",
		ya_estaba_obtenida
	)

	# No configurar ni mostrar una baya que ya fue recogida.
	if ya_estaba_obtenida or ya_fue_obtenida():
		print(
			"[BAYA] Se elimina en _ready porque ya estaba recogida: ",
			id_baya
		)

		visible = false
		set_process(false)
		set_physics_process(false)

		interaction_area.set_deferred("monitoring", false)
		interaction_area.set_deferred("monitorable", false)

		queue_free()
		return

	actualizar_sprite()

	particula_roja.emitting = false
	particula_amarilla.emitting = false

	if not interaction_area.body_entered.is_connected(_on_body_entered):
		interaction_area.body_entered.connect(_on_body_entered)

	print(
		"[BAYA] Lista para recoger | ID: ",
		id_baya,
		" | Tipo: ",
		TipoBaya.keys()[tipo_baya]
	)


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

	print(
		"[BAYA] Sprite actualizado | Tipo: ",
		TipoBaya.keys()[tipo_baya]
	)



# =========================================================
# CONTACTO
# =========================================================

func _on_body_entered(body: Node) -> void:
	print(
		"[BAYA] body_entered | Cuerpo: ",
		body.name,
		" | Grupos: ",
		body.get_groups()
	)

	if not body.is_in_group("jugador"):
		print(
			"[BAYA] Contacto ignorado: el cuerpo no pertenece al grupo jugador."
		)
		return

	print("[BAYA] Jugador detectado. Intentando recoger: ", id_baya)
	recoger_baya(body)


# =========================================================
# RECOGER BAYA
# =========================================================

func recoger_baya(player: Node) -> void:
	print(
		"\n[BAYA] INICIO DE RECOGIDA | ID: ",
		id_baya,
		" | Jugador: ",
		player.name
	)

	var id_unico: String = obtener_id_unico()

	if id_unico.is_empty():
		push_warning(
			"[BAYA] Recogida cancelada: el ID único está vacío."
		)
		return

	if ya_fue_obtenida():
		print(
			"[BAYA] Recogida cancelada: ya figuraba como obtenida: ",
			id_unico
		)
		return

	if tipo_baya == TipoBaya.VIDA:
		aumentar_vidaMax(player)

		if not Settings.objetosVidaObtenidos.has(id_unico):
			Settings.objetosVidaObtenidos.append(id_unico)

		print(
			"[BAYA] ID agregado a objetosVidaObtenidos: ",
			id_unico,
			" | Lista actual: ",
			Settings.objetosVidaObtenidos
		)

	elif tipo_baya == TipoBaya.ENERGIA:
		aumentar_energiaMax(player)

		if not Settings.objetosEnergiaObtenidos.has(id_unico):
			Settings.objetosEnergiaObtenidos.append(id_unico)

		print(
			"[BAYA] ID agregado a objetosEnergiaObtenidos: ",
			id_unico,
			" | Lista actual: ",
			Settings.objetosEnergiaObtenidos
		)

	else:
		push_warning(
			"[BAYA] Recogida cancelada: tipo de baya inválido."
		)
		return

	print("[BAYA] Intentando guardar partida...")
	Save.guardar_partida()

	print(
		"[BAYA] GUARDADO SOLICITADO | ID: ",
		id_unico,
		" | Vida: ",
		Settings.objetosVidaObtenidos,
		" | Energía: ",
		Settings.objetosEnergiaObtenidos
	)

	reproducir_particulas()
	queue_free()


# =========================================================
# PARTÍCULAS
# =========================================================

func reproducir_particulas() -> void:
	var particulas: GPUParticles2D

	if tipo_baya == TipoBaya.VIDA:
		particulas = particula_roja
	else:
		particulas = particula_amarilla

	var transformacion_global: Transform2D = particulas.global_transform

	remove_child(particulas)

	var nivel: Node = get_tree().current_scene

	if nivel == null:
		push_warning(
			"[BAYA] No se pudieron reproducir las partículas: current_scene es null."
		)
		particulas.queue_free()
		return

	nivel.add_child(particulas)
	particulas.global_transform = transformacion_global
	particulas.restart()
	particulas.emitting = true

	print(
		"[BAYA] Partículas reproducidas | Tipo: ",
		TipoBaya.keys()[tipo_baya],
		" | Escena: ",
		nivel.scene_file_path
	)


# =========================================================
# AUMENTAR VIDA
# =========================================================

func aumentar_vidaMax(player: Node) -> void:
	if cantidad <= 0:
		print(
			"[BAYA] Vida no aumentada: cantidad inválida: ",
			cantidad
		)
		return

	if not "vida" in player:
		push_warning(
			"[BAYA] El jugador no tiene la propiedad 'vida'."
		)
		return

	player.vida += cantidad
	Settings.vidaActual = player.vida

	if "barraVida" in player and player.barraVida != null:
		player.barraVida.max_value = player.vida
		player.barraVida.value = player.vida

	print(
		"[BAYA] VIDA AUMENTADA | Cantidad: ",
		cantidad,
		" | Actual: ",
		player.vida,
		" | Settings.vidaActual: ",
		Settings.vidaActual
	)


# =========================================================
# AUMENTAR ENERGÍA
# =========================================================

func aumentar_energiaMax(player: Node) -> void:
	if cantidad <= 0:
		print(
			"[BAYA] Energía no aumentada: cantidad inválida: ",
			cantidad
		)
		return

	if not player.has_method("aumentarEnergiaMax"):
		push_warning(
			"[BAYA] El jugador no tiene el método aumentarEnergiaMax()."
		)
		return

	player.aumentarEnergiaMax(cantidad)

	print(
		"[BAYA] ENERGÍA AUMENTADA | Máximo: ",
		player.energia_maxima,
		" | Actual: ",
		player.energia_fuego
	)


# =========================================================
# COMPROBACIÓN ESTÁTICA
# =========================================================

static func fue_obtenida(
	id: String,
	tipo: TipoBaya,
	id_nivel: int
) -> bool:
	if id.is_empty() or id_nivel <= 0:
		print(
			"[BAYA ESTÁTICA] Parámetros inválidos | ID: ",
			id,
			" | Nivel: ",
			id_nivel
		)
		return false

	var id_unico: String = str(id_nivel) + "_" + id

	if tipo == TipoBaya.VIDA:
		var obtenida: bool = Settings.objetosVidaObtenidos.has(id_unico)

		print(
			"[BAYA ESTÁTICA] VIDA | ID: ",
			id_unico,
			" | Resultado: ",
			obtenida
		)

		return obtenida

	if tipo == TipoBaya.ENERGIA:
		var obtenida: bool = Settings.objetosEnergiaObtenidos.has(id_unico)

		print(
			"[BAYA ESTÁTICA] ENERGÍA | ID: ",
			id_unico,
			" | Resultado: ",
			obtenida
		)

		return obtenida

	return false

# Recalcula si la baya debe existir en el nivel.
# Puede llamarse desde el nivel después de cargar los datos guardados.
func recalcular_estado() -> void:
	print("[BAYA][RECALCULAR] Iniciando comprobación.")
	print("[BAYA][RECALCULAR] Nodo: ", get_path())
	print("[BAYA][RECALCULAR] ID baya: ", id_baya)
	print("[BAYA][RECALCULAR] Tipo baya: ", TipoBaya.keys()[tipo_baya])

	var id_nivel: int = obtener_id_nivel()
	var id_unico: String = obtener_id_unico()

	print("[BAYA][RECALCULAR] ID nivel: ", id_nivel)
	print("[BAYA][RECALCULAR] ID único: ", id_unico)

	var obtenida: bool = ya_fue_obtenida()

	print("[BAYA][RECALCULAR] ¿Ya fue recogida?: ", obtenida)

	if obtenida:
		print("[BAYA][RECALCULAR] La baya ya fue recogida. Eliminando nodo.")
		queue_free()
		return

	print("[BAYA][RECALCULAR] La baya no figura como recogida. Se mantiene visible.")
	actualizar_sprite()


# Comprueba los datos persistidos según el tipo de baya.
func ya_fue_obtenida() -> bool:
	var id_unico: String = obtener_id_unico()

	match tipo_baya:
		TipoBaya.VIDA:
			var obtenida: bool = Settings.objetosVidaObtenidos.has(id_unico)
			print("[BAYA][COMPROBAR] VIDA | ID: ", id_unico,
				" | Lista: ", Settings.objetosVidaObtenidos,
				" | Encontrada: ", obtenida)
			return obtenida

		TipoBaya.ENERGIA:
			var obtenida: bool = Settings.objetosEnergiaObtenidos.has(id_unico)
			print("[BAYA][COMPROBAR] ENERGIA | ID: ", id_unico,
				" | Lista: ", Settings.objetosEnergiaObtenidos,
				" | Encontrada: ", obtenida)
			return obtenida

	return false
