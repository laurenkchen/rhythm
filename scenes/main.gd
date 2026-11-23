extends Node2D


#Lane mapping
const LOWEST_NOTE = 38
const HIGHEST_NOTE = 66
const LANE_X =  [426, 526, 626, 726]
const SPAWN_Y = -50.0
const HIT_Y = 560.0
const FALL_TIME = 2.0
const PERFECT_PX = 20.0
const MAX_HOLD_TIME = 1.0
const SONG_DURATION = 60.0
const FADEOUT_TIME = 3.0

var stop_spawning := false
var hold_time := [0.0,0.0,0.0,0.0]

var note_scene := preload("res://scenes/note.tscn")
var score :=0
var combo := 0
var lane_flash := [0.0,0.0,0.0,0.0]

var max_combo := 0 
var perfect_count := 0 
var good_count := 0 
var miss_count := 0
var song_ended := false


@onready var midi = $MidiPlayer
@onready var music = $MidiPlayer/AudioStreamPlayer
@onready var notes = $notes
@onready var hit_zones = $hitzones
@onready var score_label = $ui/Score
@onready var combo_label = $ui/Combo
@onready var judge_label = $ui/Judge


func _ready():
	midi.stop()
	midi.note_offset = FALL_TIME
	midi.midi = load(GameData.midi_path)
	music.stream = load(GameData.audio_path)	
	music.volume_db = 0.0
	
	midi.note.connect(_on_midi_note)
	midi.finished.connect(_on_midi_finished)
	midi.play()
	_run_song_timer()
	
	await get_tree().create_timer(FALL_TIME + GameData.sync_offset).timeout
	if not song_ended:
		music.play()
func _run_song_timer():
	var spawn_cutoff = max(0.0, SONG_DURATION - FADEOUT_TIME - FALL_TIME)
	await get_tree().create_timer(spawn_cutoff).timeout
	stop_spawning = true
	
	await get_tree().create_timer(FALL_TIME).timeout
	if not song_ended: 
		var fade_tween = create_tween()
		fade_tween.tween_property(music, "volume_db", -80.0, FADEOUT_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(FADEOUT_TIME).timeout
	_finish_song()
	
func _on_midi_note(event, _track): 
	if stop_spawning or event["subtype"] != MIDI_MESSAGE_NOTE_ON:
		return
	var span = HIGHEST_NOTE - LOWEST_NOTE + 1
	var lane = clampi(int((event["note"] - LOWEST_NOTE) * 4.0/span), 0,3)
	spawn_note.call_deferred(lane)


func spawn_note(lane):
	var n = note_scene.instantiate()
	n.lane = lane
	n.position = Vector2(LANE_X[lane], SPAWN_Y)
	n.speed = (HIT_Y - SPAWN_Y) / FALL_TIME
	n.missed.connect(_on_note_missed)
	notes.add_child(n)
func _unhandled_input(event):
	for lane in 4:
		if event.is_action_pressed("lane_%d" % lane):
			try_hit(lane)
			
func try_hit(lane):
	var zone: Area2D = hit_zones.get_child(lane)
	var best = null
	var best_dist = INF
	for area in zone.get_overlapping_areas():
		if area.is_queued_for_deletion() or not area.monitoring:
			continue
			
		var d = abs(area.global_position.y - HIT_Y)
		if d < best_dist:
			best = area
			best_dist = d
	if best == null:
		return
	
	best.set_deferred("monitoring", false)
	best.set_deferred("monitorable", false)
	best.set_process(false)
	best.global_position.y = HIT_Y
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(best, "scale", Vector2(1.45, 1.45), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(best, "modulate:a", 0.0, 0.1)
	tween.chain().tween_callback(best.queue_free)
	
	if best_dist <= PERFECT_PX:
		register("Perfect")
	else:
		register("Good")
func _on_note_missed():
	register("Miss")
func register(result):
	match result:
		"Perfect":
			score +=300
			combo +=1
			perfect_count += 1
			judge_label.modulate = Color(0.2, 0.95, 1.0)
		"Good":
			score +=100
			combo +=1
			good_count += 1 
			judge_label.modulate = Color(0.4, 1.0, 0.5)
			
		"Miss":
			combo = 0
			judge_label.modulate = Color(1.0, 0.25, 0.3)
	max_combo = max(max_combo, combo)
	judge_label.text = result
	score_label.text = "Score: %d" % score
	combo_label.text = "Combo: %d" % combo if combo >1 else ""
	
	judge_label.pivot_offset = judge_label.size / 4
	judge_label.scale = Vector2(1.3,1.3)
	create_tween().tween_property(judge_label, "scale", Vector2.ONE, 0.12)
func _process(delta):
	var idle_color = Color.WHITE
	var flash_color =  Color(0.2,0.95,1.0,1.0)
	var expired_color = Color(0.35, 0.35, 0.4, 1.0)
	for lane in 4:
		var zone = hit_zones.get_child(lane)
		var pad = zone.get_node("ColorRect")

		if Input.is_action_pressed("lane_%d" % lane):
			hold_time[lane] +=delta
			if hold_time[lane] <= MAX_HOLD_TIME:
				lane_flash[lane] = 1.0
				for area in zone.get_overlapping_areas():
					if area.monitoring and abs(area.global_position.y - HIT_Y) <= PERFECT_PX:
						try_hit(lane)
						break
					
			else:
				lane_flash[lane] = max(0.0, lane_flash[lane] - delta *7)
				pad.color = expired_color
			
		else:
			hold_time[lane] = 0.0
			lane_flash[lane] = max(0.0, lane_flash[lane] - delta *7)
		var t = lane_flash[lane]
		zone.scale = Vector2.ONE.lerp(Vector2(1.2,1.2), t)
		pad.color = idle_color.lerp(flash_color, t)
		if zone.has_node("Beam"):
			var beam = zone.get_node("Beam")
			beam.color = Color(0.2, 0.95, 1.0, 0.28 * t)
func _on_midi_finished():
	if song_ended: 
		return
	
	while notes.get_child_count() > 0:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	_finish_song()
	
func _finish_song():
	if song_ended:
		return
	song_ended = true
	
	midi.stop()
	music.stop()
	
	
	var total_notes = perfect_count + good_count + miss_count
	GameData.final_score = score
	GameData.max_combo = max_combo
	GameData.perfect_count = perfect_count
	GameData.good_count = good_count
	GameData.miss_count = miss_count
	GameData.accuracy = ((perfect_count * 1.0 + good_count *0.5) / total_notes) * 100
	get_tree().change_scene_to_file("res://scenes/end_screen.tscn")
