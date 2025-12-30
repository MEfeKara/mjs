extends Node2D

var hit_time: float = 0.0
var lane: int = 0
var hitline_y: float = 0.0
var scroll_speed: float = 0.0
var hit_registered: bool = false

var hold_length: float = 0.0 
var is_hold: bool = false
var is_holding: bool = false

@onready var head = $Head
@onready var tail = $Tail

func _ready():
	add_to_group("notes")
	
	if head:
		head.position = Vector2.ZERO
		if head is ColorRect: head.position = -head.size / 2
	
	if hold_length > 0:
		is_hold = true
		if tail:
			tail.visible = true
			# Kuyruk yukarı doğru uzanmalı (negatif scale veya pozisyon)
			tail.size.y = hold_length * scroll_speed
			tail.position.x = -tail.size.x / 2
	else:
		is_hold = false
		if tail: tail.visible = false

func _process(_delta):
	var game = get_tree().current_scene
	if not "music_time" in game: return
	
	if not hit_registered:
		# --- HAREKET ---
		# hitline_y ekranın yukarısında (örn: 150), scroll_speed aşağıdan yukarı itiyor
		position.y = hitline_y + (hit_time - game.music_time) * scroll_speed
		
		# --- SİLİNME (GÜVENLİ) ---
		# Nota vuruş çizgisini (hitline_y) yukarı doğru 200 piksel geçerse sil (Miss)
		# Up-scroll'da nota yukarı çıktıkça Y değeri azalır.
		if position.y < (hitline_y - 200):
			game.reset_combo()
			queue_free()
	else:
		if is_hold and is_holding:
			position.y = hitline_y
			var remaining = (hit_time + hold_length) - game.music_time
			if remaining > 0:
				tail.size.y = remaining * scroll_speed
			else:
				queue_free()

func register_hit():
	hit_registered = true
	var game = get_tree().current_scene
	
	if not is_hold:
		remove_from_group("notes")
		var tw = create_tween()
		tw.parallel().tween_property(self, "scale", Vector2(1.8, 1.8), 0.1)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
		tw.finished.connect(queue_free)
	else:
		is_holding = true
		if head: head.modulate = Color(3, 3, 3)
