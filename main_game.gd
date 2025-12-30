extends Node3D

# --- DÜĞÜM BAĞLANTILARI ---
@onready var music = $Music
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var combo_label = $CanvasLayer/ComboLabel
@onready var judgment_label = $CanvasLayer/JudgmentLabel
@onready var note_container = $CanvasLayer/Notes
@onready var stage_pivot = $StagePivot
@onready var camera = $Camera3D

@export var note_scene: PackedScene
@export var hit_effect_scene: PackedScene # Editörden HitEffect.tscn'yi buraya sürükle!

# --- AYARLAR ---
var lane_positions = [790, 890, 990, 1090] 
var hitline_y: float = 150.0 
var spawn_offset = 2.0 

# Vuruş Hassasiyeti
var perf_window = 0.07
var great_window = 0.14
var good_window = 0.22

# --- DEĞİŞKENLER ---
var music_time: float = 0.0
var score: int = 0
var combo: int = 0
var scroll_speed: float = 800.0
var shake_amount : float = 0.0
var chart_data = []

var judgment_tween: Tween
var judgment_original_pos: Vector2

func _ready():
	chart_data = [] 
	music_time = 0.0
	
	var old_notes = get_tree().get_nodes_in_group("notes")
	for n in old_notes:
		n.remove_from_group("notes")
		n.free()
	
	if GameManager.current_song:
		var data = GameManager.current_song
		if data.audio_file is String:
			music.stream = load(data.audio_file)
		else:
			music.stream = data.audio_file
			
		scroll_speed = data.scroll_speed
		load_chart(data.chart_file)
		
		if data.stage_scene:
			for child in stage_pivot.get_children():
				child.free()
			
			var stage_res = load(data.stage_scene) if data.stage_scene is String else data.stage_scene
			if stage_res:
				var stage = stage_res.instantiate()
				stage_pivot.add_child(stage)
	
	if judgment_label:
		judgment_label.modulate.a = 0
		judgment_original_pos = judgment_label.position
	
	update_ui()
	music.play()

func load_chart(path: String):
	chart_data = []
	if not FileAccess.file_exists(path): return
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	if json and json.has("notes"):
		var raw_notes = json["notes"].duplicate(true)
		raw_notes.sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))
		chart_data = raw_notes

func _process(delta):
	if not music or not music.playing: return
	music_time = music.get_playback_position() + AudioServer.get_time_since_last_mix()
	
	while chart_data.size() > 0:
		var next_note_time = float(chart_data[0]["time"])
		if music_time >= next_note_time - spawn_offset:
			var n = chart_data.pop_front()
			spawn_note(n["lane"], n["time"], n.get("length", 0.0))
		else:
			break
	_handle_camera_shake(delta)

func spawn_note(lane, hit_time, length):
	if not note_scene: return
	var new_note = note_scene.instantiate()
	new_note.lane = lane
	new_note.hit_time = hit_time
	new_note.hold_length = length
	new_note.scroll_speed = scroll_speed
	new_note.hitline_y = hitline_y
	
	var spawn_x = lane_positions[lane]
	var spawn_y = hitline_y + (hit_time - music_time) * scroll_speed
	new_note.position = Vector2(spawn_x, spawn_y)
	note_container.add_child(new_note)

func _input(event):
	for i in range(4):
		var action = "lane_" + str(i)
		if event.is_action_pressed(action):
			check_hit(i)
		if event.is_action_released(action):
			release_hold(i)

func check_hit(lane):
	var notes = get_tree().get_nodes_in_group("notes")
	var best_note = null
	var min_diff = 999.0

	for n in notes:
		if n.lane == lane and not n.hit_registered:
			var diff = abs(n.hit_time - music_time)
			if diff < min_diff:
				min_diff = diff
				best_note = n
	
	if best_note and min_diff <= good_window:
		# --- BURAYA DİKKAT: Vuruş Efekti Çağrılıyor ---
		spawn_hit_effect(lane)
		process_judgment(min_diff)
		best_note.register_hit()

# EFEKTİ SAHNEYE EKLEYEN YENİ FONKSİYON
func spawn_hit_effect(lane_index: int):
	if not hit_effect_scene: return
	var effect = hit_effect_scene.instantiate()
	# Efekti tam vuruş çizgisine (HitLine) ve şeridine koy
	effect.position = Vector2(lane_positions[lane_index], hitline_y)
	add_child(effect)

func process_judgment(diff):
	if diff <= perf_window:
		show_judgment("RIFF!", Color("a80000ff"))
		add_score(100)
		apply_shake(15.0)
	elif diff <= great_window:
		show_judgment("AIGHT", Color("d90049ff"))
		add_score(75)
		apply_shake(8.0)
	else:
		show_judgment("BET", Color("5e1a00ff"))
		add_score(50)
		apply_shake(4.0)

func show_judgment(text, color):
	if not judgment_label: return
	if judgment_tween: judgment_tween.kill()
	
	judgment_label.position = judgment_original_pos
	judgment_label.text = text
	judgment_label.modulate = color
	judgment_label.modulate.a = 1.0
	judgment_label.scale = Vector2(2.0, 2.0)
	
	judgment_tween = create_tween()
	judgment_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	judgment_tween.parallel().tween_property(judgment_label, "scale", Vector2(1.0, 1.0), 0.1)
	judgment_tween.parallel().tween_property(judgment_label, "position", judgment_original_pos + Vector2(0, -40), 0.3)
	judgment_tween.tween_property(judgment_label, "modulate:a", 0.0, 0.2).set_delay(0.1)

func apply_shake(intensity: float):
	shake_amount = intensity

func _handle_camera_shake(delta):
	if shake_amount > 0:
		camera.h_offset = randf_range(-1, 1) * shake_amount * 0.01
		camera.v_offset = randf_range(-1, 1) * shake_amount * 0.01
		shake_amount = lerp(shake_amount, 0.0, delta * 15.0)
	else:
		camera.h_offset = 0
		camera.v_offset = 0

func add_score(amount):
	score += amount
	combo += 1
	update_ui()

func reset_combo():
	combo = 0
	update_ui()
	show_judgment("REALLY?", Color("605d5cff"))

func update_ui():
	score_label.text = "Score: " + str(score)
	combo_label.text = str(combo)
	combo_label.visible = (combo > 0)

func release_hold(lane):
	var notes = get_tree().get_nodes_in_group("notes")
	for n in notes:
		if n.lane == lane and n.has_method("is_holding") and n.is_holding:
			n.queue_free()
