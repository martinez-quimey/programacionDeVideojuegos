
extends Area2D
class_name AbstractImpulso

@export var velocidad: float = 300.0

var direccion: Vector2


func _ready():

	print("IMPULSO READY")
	print("Direccion: ", direccion)
	print("Velocidad: ", velocidad)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	$Sprite2D.hide()


func _on_body_entered(body):

	print("IMPULSO: entro un cuerpo")
	print("Cuerpo: ", body.name)

	if body.is_in_group("jugador"):

		print("IMPULSO: es el jugador")
		print("Direccion aplicada: ", direccion)
		print("Velocidad aplicada: ", velocidad)

		body.movimiento_forzado(
			self,
			direccion,
			velocidad
		)

		print("IMPULSO: movimiento_forzado() ejecutado")


func _on_body_exited(body):

	print("IMPULSO: salio un cuerpo")
	print("Cuerpo: ", body.name)

	if body.is_in_group("jugador"):

		print("IMPULSO: es el jugador")

		print("IMPULSO: llamando detener_movimiento_forzado()")

		body.detener_movimiento_forzado(self)

		print("IMPULSO: movimiento forzado actualizado")
