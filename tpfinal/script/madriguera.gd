extends Node2D

@onready var areaMadriguera: Area2D = $AreaMadriguera
@onready var collisionMadriguera: Area2D = $CollisionMadriguera

var puede_salir: bool = false
var tiempo_espera: float = 0.0


func _process(delta):

	entrarMadriguera()
	salirMadriguera()

	if not puede_salir: #hay un tiempo para que al entrar su propio colider de salida no genere que salga y entre a la vez
		tiempo_espera += delta

		if tiempo_espera >= 1.0:
			puede_salir = true


func entrarMadriguera():

	if not Input.is_action_just_pressed("interactMadriguera"):
		return



	var cuerpos = areaMadriguera.get_overlapping_bodies()

	for cuerpo in cuerpos:



		if cuerpo.is_in_group("jugador"):

		

			cuerpo.entrar_madriguera()

			puede_salir = false
			tiempo_espera = 0.0

			break

func salirMadriguera():



	if not puede_salir:

		return

	var cuerpos = collisionMadriguera.get_overlapping_bodies()


	for cuerpo in cuerpos:



		if cuerpo.is_in_group("jugador"):



			if cuerpo.esta_en_madriguera:


				cuerpo.salir_madriguera()

				break
