extends Control

@onready var title_label = $TitleLabel
@onready var grade_label = $GradeLabel
@onready var stats_label = $StatsLabel
@onready var play_again_btn = $PlayAgainButton
@onready var menu_button = $MenuButton

func _ready():
	title_label.text = GameData.song_title + " Complete!"
	grade_label.text = "Rank: " + _calculate_grade(GameData.accuracy)
	
	stats_label.text = (
		"Score: %d\n" % GameData.final_score + 
		"Accuracy %.1f%%\n" % GameData.accuracy + 
		"Max Combo: %d\n\n" % GameData.max_combo + 
		"Perfect :%d | Good: %d | Miss: %d" % [
			GameData.perfect_count,
			GameData.good_count,
			GameData.miss_count
		]
	)
	play_again_btn.text = "Play Again"
	menu_button.text = "Song Select"
	
	play_again_btn.pressed.connect(_on_play_again)
	menu_button.pressed.connect(_on_menu)
	
func _calculate_grade(acc: float) -> String:
	if acc >= 95 and GameData.miss_count == 0:
		return "S"
	elif acc >= 90.0:
		return "A"
	elif acc >= 80.0:
		return "B"
	elif acc >= 70:
		return "C"
	else:
		return "D"
func _on_play_again():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
func _on_menu():
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
	
