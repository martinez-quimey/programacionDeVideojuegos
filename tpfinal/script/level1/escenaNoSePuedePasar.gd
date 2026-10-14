
extends Area2D

@export var dialogue_script: Script

@export var desplazamiento_camara := 2700.0
@export var duracion_movimiento_camara := 0.8
@export var tiempo_espera_camara := 1.7

var secuencia_activa := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func esperar_hasta_suelo(body: CharacterBody2D) -> void:

	while not body.is_on_floor():
		await get_tree().physics_frame


func _on_escena_no_puedo_pasar_por_aqui_body_entered(body: Node2D) -> void:

	if secuencia_activa:
		return

	if not body.is_in_group("jugador"):
		return

	if body.estado_actual == null:
		return

	secuencia_activa = true

	# Guardar la cámara antes de pausar.
	var camara: Camera2D = body.get_node_or_null("Camera2D")

	if camara == null:
		secuencia_activa = false
		return

	var posicion_original := camara.position
	var zoom_original := camara.zoom

	var posicion_derecha := (
		posicion_original
		+ Vector2(desplazamiento_camara, 0)
	)

	var zoom_reducido := zoom_original - Vector2(0.2, 0.2)

	# Cambiar a automático antes de pausar.
	body.estado_actual.cambiar_a_automatico()

	await esperar_hasta_suelo(body)

	# Pausar el árbol entero.
	get_tree().paused = true

	# La cámara debe poder procesar durante la pausa.
	camara.process_mode = Node.PROCESS_MODE_ALWAYS

	# Mover la cámara y reducir el zoom.
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
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

	# Espera que funciona aunque el árbol esté pausado.
	await get_tree().create_timer(
		tiempo_espera_camara,
		true
	).timeout

	# Devolver la cámara y el zoom.
	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
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

	# Reanudar el juego antes de cambiar de estado.
	get_tree().paused = false

	body.estado_actual.cambiar_a_manual()

	# Iniciar el diálogo.
	if dialogue_script != null:
		var dialogue: DialogueAbstract = dialogue_script.new()

		if dialogue != null:
			dialogue.create_dialogue()
			DialogueManager.start_dialogue(dialogue)

	# Eliminar el trigger.
	queue_free()
