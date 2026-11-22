extends Control


const SONGS = [
	{
		"title": "Animal Crossing: 10:00AM",
		"midi": "res://songs/acnl.mid",
		"audio": "res://songs/acnl.ogg"
	},
	{
		"title": "Just the Two of Us",
		"midi": "res://songs/willsmith.mid",
		"audio": "res://songs/willsmith.ogg"
	},
	{
		"title": "Wii Theme",
		"midi": "res://songs/wii.mid",
		"audio": "res://songs/wii.ogg"
	}
]

@onready var song1_btn = $VBoxContainer/Song1Button
@onready var song2_btn = $VBoxContainer/Song2Button
@onready var song3_btn = $VBoxContainer/Song3Button

func _ready():
	song1_btn.text = SONGS[0]["title"]
	song2_btn.text = SONGS[1]["title"]
	song3_btn.text = SONGS[2]["title"]
	
	song1_btn.pressed.connect(func(): _start_song(0))
	song2_btn.pressed.connect(func(): _start_song(1))
	song3_btn.pressed.connect(func(): _start_song(2))
	
func _start_song(index: int):
	GameData.song_title = SONGS[index]["title"]
	GameData.midi_path = SONGS[index]["midi"]
	GameData.audio_path = SONGS[index]["audio"]
	get_tree().change_scene_to_file("res://scenes/main.tscn")
