extends Area2D

@onready var portal: AnimatedSprite2D = $Portal

var won: bool = false


func _ready() -> void:
	portal.play("idle")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if won:
		return
	print("You win!")
	won = true
	portal.play("open")


func _on_portal_animation_finished() -> void:
	if portal.animation == "open":
		portal.play("idle_open")
