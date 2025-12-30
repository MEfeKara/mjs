extends Node3D

var chart = []
var spawn_index = 0
@onready var game = get_parent()

func _ready():
	# Sabit dosya yolu yerine GameManager'daki seçili şarkının yolunu kullan!
	if GameManager.current_song:
		var chart_path = GameManager.current_song.chart_file
		var file = FileAccess.open(chart_path, FileAccess.READ)
		# ... geri kalan kodlar
		
func _process(_delta):
	while spawn_index < chart.size():
		var n_data = chart[spawn_index]
		# Notaları 2 saniye önceden doğur
		if float(n_data["time"]) - game.music_time <= 2.0:
			spawn_note(n_data)
			spawn_index += 1
		else: break

func spawn_note(data):
	var n = game.note_scene.instantiate()
	n.hit_time = float(data["time"])
	n.lane = int(data["lane"])
	n.scroll_speed = game.scroll_speed
	
	# HitLine ekranın yukarısında olmalı (örn: y=100)
	var hl = game.find_child("HitLine", true, false)
	n.hitline_y = hl.global_position.y if hl else 100.0
	
	if data.get("type") == "hold":
		n.is_hold = true
		n.hold_length = float(data.get("length", 1.0))
	
	var lanes = game.find_child("LanePositions", true, false)
	var x_pos = 100 + (n.lane * 100)
	if lanes:
		var marker = lanes.get_node_or_null(str(n.lane))
		if marker: x_pos = marker.global_position.x
	
	# Notaları ekranın altında (örn: y=800) başlat
	n.position = Vector2(x_pos, 800) 
	game.find_child("Notes", true, false).add_child(n)
