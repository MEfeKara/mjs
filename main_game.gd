extends Node3D

# --- DÜĞÜM BAĞLANTILARI ---
@onready var music = $Music
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var combo_label = $CanvasLayer/ComboLabel
@onready var judgment_label = $CanvasLayer/JudgmentLabel
@onready var countdown_label = $CanvasLayer/CountdownLabel
@onready var note_container = $CanvasLayer/Notes
@onready var stage_pivot = $StagePivot
@onready var camera = $Camera3D

@export var note_scene: PackedScene
@export var hit_effect_scene: PackedScene

# --- AYARLAR ---
var lane_positions = [790, 890, 990, 1090] 
var hitline_y: float = 150.0 
var spawn_offset = 2.0 

var perf_window = 0.07
var great_window = 0.14
var good_window = 0.22

# --- VERİ TAKİBİ ---
var music_time: float = 0.0
var score: int = 0
var combo: int = 0
var total_notes_in_chart : int = 0
var perfect_count = 0
var great_count = 0
var good_count = 0
var miss_count = 0
var scroll_speed: float = 800.0
var shake_amount : float = 0.0
var chart_data = []

var judgment_tween: Tween
var judgment_original_pos: Vector2

func _ready():
	chart_data = []
	music_time = 0.0
	if countdown_label: countdown_label.visible = false
	
	var old_notes = get_tree().get_nodes_in_group("notes")
	for n in old_notes:
		n.remove_from_group("notes")
		n.free()
	
	if GameManager.current_song:
		var data = GameManager.current_song
		music.stream = load(data.audio_file) if data.audio_file is String else data.audio_file
		scroll_speed = data.scroll_speed
		load_chart(data.chart_file)
		
		# Stage yükleme
		if data.stage_scene:
			for child in stage_pivot.get_children(): child.free()
			var res = load(data.stage_scene) if data.stage_scene is String else data.stage_scene
			if res: stage_pivot.add_child(res.instantiate())
	
	if judgment_label:
		judgment_label.modulate.a = 0
		judgment_original_pos = judgment_label.position
	
	music.finished.connect(on_music_finished)
	update_ui()
	start_countdown()

func start_countdown():
	if not countdown_label: return
	countdown_label.visible = true
	countdown_label.modulate.a = 1.0
	
	for i in range(3, 0, -1):
		countdown_label.text = str(i)
		countdown_label.scale = Vector2(2, 2)
		var t = create_tween()
		t.tween_property(countdown_label, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK)
		await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "GO!"
	var t_go = create_tween()
	t_go.tween_property(countdown_label, "modulate:a", 0, 0.5)
	music.play()

func load_chart(path: String):
	if not FileAccess.file_exists(path): return
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	if json and json.has("notes"):
		chart_data = json["notes"].duplicate(true)
		total_notes_in_chart = chart_data.size()
		chart_data.sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))

func _process(delta):
	if not music or not music.playing: return
	
	music_time = music.get_playback_position() + AudioServer.get_time_since_last_mix()
	
	while chart_data.size() > 0:
		if music_time >= float(chart_data[0]["time"]) - spawn_offset:
			var n = chart_data.pop_front()
			spawn_note(n["lane"], n["time"], n.get("length", 0.0))
		else: break
		
	_handle_camera_shake(delta)

func spawn_note(lane, hit_time, length):
	if not note_scene: return
	var n = note_scene.instantiate()
	n.lane = lane
	n.hit_time = hit_time
	n.hold_length = length
	n.scroll_speed = scroll_speed
	n.hitline_y = hitline_y
	
	var spawn_x = lane_positions[lane]
	var spawn_y = hitline_y + (hit_time - music_time) * scroll_speed
	n.position = Vector2(spawn_x, spawn_y)
	note_container.add_child(n)

func _input(event):
	for i in range(4):
		var action = "lane_" + str(i)
		if event.is_action_pressed(action): check_hit(i)
		if event.is_action_released(action): release_hold(i)

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
		spawn_hit_effect(lane)
		process_judgment(min_diff)
		best_note.register_hit()

func spawn_hit_effect(lane_idx):
	if not hit_effect_scene: return
	var eff = hit_effect_scene.instantiate()
	eff.position = Vector2(lane_positions[lane_idx], hitline_y)
	add_child(eff)

func process_judgment(diff):
	if diff <= perf_window:
		perfect_count += 1
		show_judgment("RIFF!", Color("ff0000ff"))
		add_score(100); apply_shake(15.0)
	elif diff <= great_window:
		great_count += 1
		show_judgment("AIGHT", Color("98000dff"))
		add_score(75); apply_shake(8.0)
	else:
		good_count += 1
		show_judgment("BET", Color("601f00ff"))
		add_score(50); apply_shake(4.0)

func show_judgment(text, color):
	if not judgment_label: return
	if judgment_tween: judgment_tween.kill()
	judgment_label.position = judgment_original_pos
	judgment_label.text = text
	judgment_label.modulate = color
	judgment_label.modulate.a = 1.0
	judgment_label.scale = Vector2(2.0, 2.0)
	judgment_tween = create_tween()
	judgment_tween.parallel().tween_property(judgment_label, "scale", Vector2(1,1), 0.1)
	judgment_tween.parallel().tween_property(judgment_label, "position", judgment_original_pos + Vector2(0,-40), 0.3)
	judgment_tween.tween_property(judgment_label, "modulate:a", 0, 0.2).set_delay(0.1)

func apply_shake(intensity): shake_amount = intensity

func _handle_camera_shake(delta):
	if shake_amount > 0:
		camera.h_offset = randf_range(-1,1) * shake_amount * 0.01
		camera.v_offset = randf_range(-1,1) * shake_amount * 0.01
		shake_amount = lerp(shake_amount, 0.0, delta * 15.0)
	else:
		camera.h_offset = 0; camera.v_offset = 0

func add_score(amount):
	score += amount
	combo += 1
	update_ui()

func reset_combo():
	miss_count += 1
	combo = 0
	update_ui()
	show_judgment("REALLY?..", Color("4d474bff"))

func update_ui():
	score_label.text = "Score: " + str(score)
	combo_label.text = str(combo)
	combo_label.visible = (combo > 0)

func release_hold(lane):
	var notes = get_tree().get_nodes_in_group("notes")
	for n in notes:
		if n.lane == lane and n.has_method("is_holding") and n.is_holding:
			n.queue_free()

# --- SONUÇ SİSTEMİ ---
func on_music_finished():
	var total_points = total_notes_in_chart * 1.0
	var current_points = (perfect_count * 1.0) + (great_count * 0.7) + (good_count * 0.4)
	var acc = (current_points / total_points * 100.0) if total_points > 0 else 0.0
	
	var rank = "C"
	if acc >= 98: rank = "SS"
	elif acc >= 93: rank = "S"
	elif acc >= 85: rank = "A"
	elif acc >= 75: rank = "B"
	
	GameManager.last_run_data = {
		"score": score, "accuracy": acc, "rank": rank,
		"perfects": perfect_count, "greats": great_count, "goods": good_count, "misses": miss_count
	}
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Results.tscn")
