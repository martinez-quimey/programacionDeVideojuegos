class_name AbstractNPC
extends CharacterBody2D


var player_nearby := false


func _ready() -> void:
	print("NPC READY: ", name)

	var interaction_area: Area2D = $InteractionArea

	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)


func _process(_delta: float) -> void:
	if player_nearby:
		if Input.is_action_just_pressed("interactuar"):
			print("INTERACTAR DETECTADO")
			interact()


func interact() -> void:
	print("ABSTRACT INTERACT")


func _on_interaction_area_body_entered(body: Node2D) -> void:
	print("BODY ENTERED: ", body.name)

	if body.is_in_group("jugador"):
		player_nearby = true
		print("JUGADOR DETECTADO")


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		player_nearby = false
		print("JUGADOR SALIO")
