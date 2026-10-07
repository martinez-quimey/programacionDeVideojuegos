extends Area2D


@export var dialogue_script: Script

@export var desplazamiento_camara := 2700.0
@export var duracion_movimiento_camara := 0.8
@export var tiempo_espera_camara := 1.7


func esperar_hasta_suelo(body: CharacterBody2D) -> void:

	print(
		"TRIGGER: esperar_hasta_suelo | is_on_floor = ",
		body.is_on_floor()
	)

	while not body.is_on_floor():

		await get_tree().physics_frame

	print(
		"TRIGGER: esperar_hasta_suelo TERMINADO | is_on_floor = ",
		body.is_on_floor()
	)


func _on_escena_no_puedo_pasar_por_aqui_body_entered(body: Node2D) -> void:

	print("========================================")
	print("TRIGGER: BODY ENTERED")
	print("TRIGGER: cuerpo = ", body.name)
	print("TRIGGER: grupo jugador = ", body.is_in_group("jugador"))
	print("TRIGGER: tipo = ", body.get_class())
	print("TRIGGER: posición = ", body.position)
	print("========================================")


	# =====================================================
	# COMPROBAR SI ES EL PLAYER
	# =====================================================

	if not body.is_in_group("jugador"):

		print("TRIGGER: no es el jugador, ignorando")

		return


	print("TRIGGER: ES EL JUGADOR")


	# =====================================================
	# COMPROBAR ESTADO ACTUAL
	# =====================================================

	if body.estado_actual == null:

		print("ERROR: estado_actual es null")

		return


	# =====================================================
	# CAMBIAR A AUTOMÁTICO
	# =====================================================

	print("TRIGGER: cambiando a automático")

	body.estado_actual.cambiar_a_automatico()


	# =====================================================
	# ESPERAR HASTA QUE ESTÉ EN EL SUELO
	# =====================================================

	print("TRIGGER: esperando hasta suelo")

	await esperar_hasta_suelo(body)

	print("TRIGGER: Player está en el suelo")


	# =====================================================
	# BUSCAR CÁMARA
	# =====================================================

	var camara: Camera2D = body.get_node_or_null("Camera2D")


	if camara == null:

		print(
			"ERROR: no se encontró Camera2D dentro de Player"
		)

		return


	print("TRIGGER: Camera2D encontrada")


	# =====================================================
	# GUARDAR ESTADO ORIGINAL DE LA CÁMARA
	# =====================================================

	var posicion_original := camara.position

	var zoom_original := camara.zoom

	var zoom_reducido := zoom_original - Vector2(0.2, 0.2)


	var posicion_derecha := (
		posicion_original
		+ Vector2(
			desplazamiento_camara,
			0
		)
	)


	print(
		"TRIGGER: moviendo cámara de ",
		posicion_original,
		" a ",
		posicion_derecha
	)

	print(
		"TRIGGER: zoom original = ",
		zoom_original
	)

	print(
		"TRIGGER: zoom reducido = ",
		zoom_reducido
	)


	# =====================================================
	# MOVER CÁMARA Y REDUCIR ZOOM
	# =====================================================

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.set_parallel(true)

	tween.tween_property(
		camara,
		"position",
		posicion_derecha,
		duracion_movimiento_camara
	)

	tween.tween_property(
		camara,
		"zoom",
		zoom_reducido,
		duracion_movimiento_camara
	)

	await tween.finished

	print("TRIGGER: cámara llegó a la derecha")
	print("TRIGGER: zoom reducido")


	# =====================================================
	# ESPERAR
	# =====================================================

	await get_tree().create_timer(
		tiempo_espera_camara
	).timeout

	print("TRIGGER: terminó espera de cámara")


	# =====================================================
	# DEVOLVER CÁMARA Y ZOOM
	# =====================================================

	tween = create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.set_parallel(true)

	tween.tween_property(
		camara,
		"position",
		posicion_original,
		duracion_movimiento_camara
	)

	tween.tween_property(
		camara,
		"zoom",
		zoom_original,
		duracion_movimiento_camara
	)

	await tween.finished

	print("TRIGGER: cámara volvió")
	print("TRIGGER: zoom volvió a ", zoom_original)


	# =====================================================
	# VOLVER A MANUAL
	# =====================================================

	body.estado_actual.cambiar_a_manual()

	print("TRIGGER: Player volvió a manual")


	# =====================================================
	# DIÁLOGO
	# =====================================================

	if dialogue_script == null:

		print(
			"ERROR: dialogue_script no está asignado"
		)

		return


	print("TRIGGER: creando diálogo")


	var dialogue: DialogueAbstract = dialogue_script.new()


	if dialogue == null:

		print(
			"ERROR: dialogue_script.new() devolvió null"
		)

		return


	dialogue.create_dialogue()


	print("TRIGGER: iniciando DialogueManager")


	DialogueManager.start_dialogue(dialogue)

	print("TRIGGER: diálogo iniciado")


	# =====================================================
	# ELIMINAR TRIGGER
	# =====================================================

	queue_free()
