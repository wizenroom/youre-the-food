extends CanvasLayer

## Track order: 0 Axiom, 1 Out of the Blue, 2 Atoms, 3 Why Is No One Watching
## Why is never the first song that plays.

@onready var _players: Array[AudioStreamPlayer] = [
	$Axiom,
	$"Out of the Blue",
	$Atoms,
	$WhyIsNoOneWatching,
]
@onready var _labels: Array[Label] = [
	$Control/Axiom,
	$Control/OutOfTheBlue,
	$Control/Atoms,
	$Control/WhyIsNoOneWatching,
]

const WHY_INDEX := 3
var current_track := -1


func _ready() -> void:
	for p in _players:
		p.finished.connect(_on_audio_finished)
	# first song: anything except Why
	_play_track(randi() % WHY_INDEX)


func _play_track(index: int) -> void:
	if current_track >= 0 and current_track < _players.size():
		_players[current_track].stop()
	current_track = index
	_players[current_track].play()
	for i in _labels.size():
		_labels[i].visible = i == current_track


func _on_audio_finished() -> void:
	_play_track((current_track + 1) % _players.size())
