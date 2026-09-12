extends CharacterBody2D

@onready var Invulnerabilidad: Timer = $Invulnerabilidad

@onready var detection_area: Area2D = $DetectionArea
const isBoss = false
var vida: int = 1

var player_in_range: bool = false



func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.is_in_group("jugador"):
		player_in_range = true
		actuarContraPlayer()


func _on_body_exited(body):
	if body.is_in_group("jugador"):
		player_in_range = false
		dejarDeActuarContraPlayer()

func actuarContraPlayer():
	pass
func dejarDeActuarContraPlayer():
	pass


func animacionHerida():
	pass

func morir():
	queue_free()


func herir(num: int):
	if Invulnerabilidad.is_stopped():
		vida -= num

		if isBoss:
			pass

		if vida <= 0:
			morir()
			return

		Invulnerabilidad.start()
		animacionHerida()
