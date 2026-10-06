extends Area2D


@export var dialogue_script: Script

@export var desplazamiento_camara := 100.0
@export var duracion_movimiento_camara := 0.8
@export var tiempo_espera_camara := 2.0


func _on_body_entered(body):

	print("========================================")
	print("TRIGGER: BODY ENTERED")
	print("TRIGGER: cuerpo = ", body.name)
	print("TRIGGER: grupo jugador = ", body.is_in_group("jugador"))
	print("TRIGGER: posición Player = ", body.position)
	print("TRIGGER: is_on_floor = ", body.is_on_floor())
	print("========================================")

	if not body.is_in_group("jugador"):
		return

	print("TRIGGER: ES EL JUGADOR")

	if body.estado_actual == null:
		print("ERROR: estado_actual es null")
		return

	print("TRIGGER: cambiando a automático")

	body.estado_actual.cambiar_a_automatico()

	print("TRIGGER: esperando hasta suelo")

	await esperar_hasta_suelo(body)

	print("TRIGGER: Player está en el suelo")

	var camara: Camera2D = body.get_node_or_null("Camera2D")

	if camara == null:
		print("ERROR: no se encontró Camera2D dentro de Player")
		return

	print("TRIGGER: Camera2D encontrada")

	var posicion_original := camara.position

	var posicion_derecha := posicion_original + Vector2(
		desplazamiento_camara,
		0
	)

	print(
		"TRIGGER: moviendo cámara de ",
		posicion_original,
		" a ",
		posicion_derecha
	)

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		camara,
		"position",
		posicion_derecha,
		duracion_movimiento_camara
	)

	await tween.finished

	print("TRIGGER: cámara llegó a la derecha")

	await get_tree().create_timer(
		tiempo_espera_camara
	).timeout

	print("TRIGGER: terminó espera de cámara")

	tween = create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		camara,
		"position",
		posicion_original,
		duracion_movimiento_camara
	)

	await tween.finished

	print("TRIGGER: cámara volvió")

	body.estado_actual.cambiar_a_manual()

	print("TRIGGER: Player volvió a manual")

	if dialogue_script == null:
		print("ERROR: dialogue_script no está asignado")
		return

	print("TRIGGER: creando diálogo")

	var dialogue: DialogueAbstract = dialogue_script.new()

	if dialogue == null:
		print("ERROR: dialogue_script.new() devolvió null")
		return

	dialogue.create_dialogue()

	print("TRIGGER: iniciando DialogueManager")

	DialogueManager.start_dialogue(dialogue)

	print("TRIGGER: diálogo iniciado")

	queue_free()


func esperar_hasta_suelo(body) -> void:

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
