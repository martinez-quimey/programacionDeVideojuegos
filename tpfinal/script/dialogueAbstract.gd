# dialogue
class_name DialogueAbstract
extends Node


@export var esAutomatico: bool = false

var lines: Array[DialogueLine] = []


func add_line(speaker: String, text: String, portrait: Texture2D = null) -> void:
	var line := DialogueLine.new()

	line.speaker = speaker
	line.text = text
	line.portrait = portrait

	lines.append(line)


func create_dialogue() -> void:
	pass
