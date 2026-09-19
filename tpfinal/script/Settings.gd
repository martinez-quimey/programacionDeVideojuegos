extends Node

var language: String = "es"
var sePuedePausar = false
var main = null

const vidaInicial = 5
var vidaActual = 5

const energiaInicial = 5
var energiaActual = 5

# ==========================================
# PROGRESO DE PARTIDA
# ==========================================

var nivelActual: String = ""

var nivelesCompletados: Array[String] = []

# Objetos de vida obtenidos
var objetosVidaObtenidos: Array[String] = []

# Objetos de energía obtenidos
var objetosEnergiaObtenidos: Array[String] = []


func setearMain(Main):
	main = Main


func getMain():
	return main


func getEnergiaActual():
	return energiaActual


func getVidaActual():
	return vidaActual
