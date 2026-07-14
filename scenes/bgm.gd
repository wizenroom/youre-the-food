extends CanvasLayer

@onready var Axiom: AudioStreamPlayer = $Axiom
@onready var OutOfTheBlue: AudioStreamPlayer = $"Out of the Blue"

@onready var AxiomLabel:= $Control/Axiom
@onready var OutOfTheBlueLabel := $"Control/OutOfTheBlue"

var current_track := randi_range(1,2)


func _ready():
	Axiom.finished.connect(_on_audio_finished)
	OutOfTheBlue.finished.connect(_on_audio_finished)
	_on_audio_finished()


func play_Axiom():
	current_track = 1
	Axiom.play()
	showAxiomlabel()


func play_OutOfTheBlue():
	current_track = 2
	OutOfTheBlue.play()
	showOutOfTheBlueLabel()

func showAxiomlabel():
	AxiomLabel.visible = true
	OutOfTheBlueLabel.visible = false
	
func showOutOfTheBlueLabel():
	AxiomLabel.visible = false
	OutOfTheBlueLabel.visible = true
	

func _on_audio_finished():
	if current_track == 1:
		play_OutOfTheBlue()
	else:
		play_Axiom()
		
